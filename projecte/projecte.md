#Enrutament i concentració de logs amb Syslog i Journal

## Centralització de logs amb rsyslog

### Syslog

Syslog és un standart de facto( no està acceptat per un organisme estandaritzat, però si de forma popular ), 
utilitzat per la generació de logs en una xarxa informàtica. Els logs són missatges de seguretat que genera el sistema, 
encara que poden contenir qualsevol informació. El dimoni que utilitza aquest protocol és el syslogd, que 
envia missatges via UDP(encara que es pot configurar per que ho faci també per TCP), pel port 514. 

El protocol va ser creat per Eric Allman, com a part del projecte Sendmail. 
Encara que en un principi només era part d'aquest projecte, es va veure que era molt útil, i 
va començar a ser part d'altres projectes importants. Actualment forma part de quasi tots els 
sistemes Unix i GNU/Linux i altres sistemas com Microsoft Windows. Encara que sigui present, es 
considera aquest protocol obsolet, degut a l'aparició d'altres sistemes més potents(systemd) i la 
poca eficiència a l'hora de la manipulació dels logs generats. 

#### Estructura del missatge

El missatge que genera el syslog segueix el rfc3164, el qual indica que els missatges tenen 3 parts marcades:

    1. Prioritat
    2. Capcelera
    3. Text

##### Prioritat

La prioritat és un número de 8 bits que indica el recurs(qui ha generat el missatge) i el nivell d'importància. Els còdis del recurs són:  

0.  Missatges del kernel 
1. Missatges de l'usuari
2. Sistema de correo
3. Dimonis del sistema
4. Seguretat
5. Missatges generats pel mateix dimoni syslogd
6. Subsistema d'impressió
7. Subsistema de missatges de xarxa
8. Susbistema UUCP
9. Susbistema d'hora
10. Dimoni del ftp
11. Susbsitema NTP
12. Inspecció del registre
13. Alertas en el registre
14. Dimoni del sistema d'hora
15. Dimoni del rellotge
16. Ús local

Codis del nivell d'importància: 

0. Emergència, el sistema està inutilitzable
1. Alerta, actuar inmediatament
2. Crític, condicions crítiques
3. Error
4. Perill
5. Avís, normal però caldia actuar
6. Informació
7. Missatges de baix nivell

##### Capcelera

És el segon camp, el qual conté, el temps en format Mmm dd hh:mm:ss, 
seguit del nom del host, o en el seu defecte la direcció ip.

##### Text

És l'últim camp de log, que dona informació sobre el procés que ha generat el log. 
Normalment comença amb el nom del procés que l'ha generat, seguit d'un caràcter no 
alfanumèric com ":" o un espai. Per últim el propi text que conté el contingut real del missatge.

Podem veure una línia d'exemple d'un log:

    May  2 12:50:35 i10 pengine[12009]: notice: LogActions: Move    ClusterIP	(Started i11 -> i10)

### Rsyslog
 
Syslog com aplicació, ha quedat obsoleta per molts motius esmentats anteriorment. En aquest projecte utilitzarem rsyslog com aplicació, per a centralitzar els logs. 
Rsyslog utilitza el mateix estandard que utilitza syslog (RFC 3164), però extenent aquest últim. Les principals millores són:

* Utilització de la ISO 8601. Permet el timestamp en milisegons, a més de la utilització de time-zones.
* Utilització de TCP per enviar els missatges.
* Completa funcionalitat amb systemd journal. 
* Completa funcionalitat amb SSL i GSS-API.

Entre d'altres millores.

### Configuració del servidor i client

Per començar la centralització de logs amb rsyslog. Desactivem journalctl, per que no tinguin cap mena de conflicte(encara que no tindria que tenir), per a fer les proves en aquest projecte.

El contexte general de les proves serà, 1 client que enviarà tot el que generi rsyslog (i11), i un servidor que agruparà tot al seu disc dur(i10).

A l'hora de configurar els hosts, utilizarem el [manual](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/3/html/Installation_and_Configuration_Guide/Configuring_the_rsyslog_Server.html) de configuració de redhat, per la configuració de rsyslog.

#### Servidor

En el nostre cas, tenim desactivat tant el selinux com el firewall(no és 
el més indicat, però es un entorn de proves). El fitxer de configuració de rsyslog és el /etc/rsyslog.conf. 
En el nostre cas el [fitxer](https://github.com/etj-projecte-2016/enrutament/blob/master/projecte/rsyslog.conf) quedaria d'aquesta manera. 
A l'hora de filtrar el que volem i com ho volem, tindriem que utilitzar expressions regulars. Per exemple:  

    mail.* /var/log/messages 
    authpriv.* /var/log/secure
 
En aquests casos estem dient que tot el que comenci en mail,authpriv es dessi, en el seu respectiu log.

Però també tenim l'opció de crear templates:

	$template TmplAuth, "/var/log/HOSTS/%HOSTNAME%/%PROGRAMNAME%"
	$template TmplMsg, "/var/log/HOSTS/%HOSTNAME%/%PROGRAMNAME%"
	$template Msgs, "/var/log/HOSTS/%HOSTNAME%/messages"

	authpriv.* ?TmplAuth
	*.info,mail.none,authpriv.none,cron.none ?TmplMsg
	*.* ?Msgs
	& ~ 
 
Amb l'opció $template, creem una variable que es diu TemlAuth, i dessarà tot el que acabi per TmplAuth a, /var/log/HOSTS/nom-del-host/nom-del-programa. 
Amb aquesta configuració estem dessant per cada hosts un log per cada programa que els generi, i a més tot el que es generi en un log concentrat que es diu messages. 

Acabat d'editar el fitxer fem un restart del servei:

   systemctl restart rsyslog

Hi ha moltes configuracions possibles, depenent del que et convingui més, voldràs tenir tot en un fitxer o per contra desglossat en diferents.

#### Client

Per d'altra banda cal configurar el client per que enviï els logs al servidor.

El [fitxer](https://github.com/etj-projecte-2016/enrutament/blob/master/projecte/rsyslog.conf.client) quedaria d'aquesta manera.

Cal configurar:

    *.* @192.168.2.40:514

Li estem dient que tot el que generi rsyslog, ho enviï a la ip indicada.

Amb tot això tindriem configurat ja la centralització feta. El següent tema 
a explorar és, els logs que generem seran enviats tots al servidor, o per contra 
volem que també es quedin els logs al client, per tal de tenir un backup de seguretat? 

### Administració de logs amb logrotate i creació d'escripts

Per explorar aquest tema, exposo el següent cas. A la feina ens proposen
que els logs generats pel kernel a més d'enviar-los al servidor, es quedin 
al propi client en forma comprimida un dia. Per d'altra banda a un servidor 
de backup tindrem que mantenir una setmana els logs generats. Per això utilitzarem 
logrotate per desglossar cada dia el log generat. Al servidor utilizarem 
un cron que buscarà els fitxers més antics d'una setmana, farà un backup 
d'aquests i per últim esborrarà el backup anterior.

#### Configuració del client

Primer de tot tenim que configurar el client per que guardi els missatges 
del kernel al propi host. Tenim que editar el fitxer /etc/rsyslog.conf
i afegir la següent linia:

    kern.*		/var/log/kernel 

Fem un restart del servei rsyslog.

Per d'altra banda, ens havien demanat que aquests logs estiguin un dia 
en el propi hosts. Això ho podem fer amb logrotate.

##### Logrotate

Logrotate és una eïna per l'administració de sistemes que generen gran 
nombre de logs. Això permet entre d'altres coses, rotació automàtica, 
compressió de logs, esborrar-los etc.

En el nostre cas els logs del kernel tenen que estar un dia només. El fitxer
de configuració del logrotate està a /etc/logrotate.conf o per contra, dins del
directori /etc/logrotate.d/, hi ha un fitxer per cada cas. En aquest cas
utilitzarem un fitxer apart per fer el nostre exemple. El 
[fitxer](https://github.com/etj-projecte-2016/enrutament/blob/master/kernel)
en qüestió quedaria d'aquesta manera. 

Aquest fitxer ens diu que farà logrotate del fitxer /var/log/kernel, que
ho farà diariament, i que començarà a borrar el fitxer antic quan hi existeixi 
dos fitxers previs. A més fara els fitxers comprimits.

Per fer-ho més ràpid, editem un fitxer dins de [/etc/cron.d/rotate-logs](https://github.com/etj-projecte-2016/enrutament/blob/master/projecte/rotate-logs),
que executarà un script cada minut amb l'user root. El fitxer el qüestió
és [aquest](https://github.com/etj-projecte-2016/enrutament/blob/master/projecte/rotate1min.sh). 

A més, si no volem esperar cada minut, podem fer l'ordre:

    logrotate -vf /etc/logrotate.d/kernel


A l'hora de comprimir els fitxers, el logrotate crea un fitxer amb el 
nom d'aquest seguit d'un número començant pel número 1. Com que no volem
això, si no que acabi amb la data de quan es crea el backup, tenim que 
afegir les següents linies:

    dateext
    dateformat %Y%m%d
    
Logrotate fa un backup del propi fitxer original, per tant, es te que crear
un altra vegada aquest. Per fer-ho tenim l'opció postorate que ens permet
executar scripts una vegada feta la rotació. En aquest exemple creem el fitxer
original per tal de deixar-ho tot tal i com estava. Per exemple:

    posrotate
		/bin/touch /var/log/kernel
	endscript
	

##### Rsync

La segona part de la proposta era sincronitzar en un servidor de backups,
fins a 10 fitxers, per tal de tenir una copia d'aquests. Això ho podem aconseguir
amb la utilitat Rsync. 

Per fer aquest tasca necessitarem també de cron, per tal de sincronitzar cada x minuts,
les carpetes que volem. 

Una altra cop, crearem un fitxer dins de [/etc/cron.d/rsync-bk](https://github.com/etj-projecte-2016/enrutament/blob/master/projecte/rsync-bk),
que executarà un script com [aquest](https://github.com/etj-projecte-2016/enrutament/blob/master/projecte/sync-01.sh).

L'escript, sincronitza els fitxers que contenen la paraula kernel al principi,
amb un directori remot (en aquest cas el host i10, que és on concentrem els logs).

Amb això tindriem ja finalitzat l'exemple que vam proposar.

## Centralització de logs amb Systemd

### Systemd

Systemd és un conjunt de dimonis d'administració del sistema GNU/Linux,
llibreries i eïnes per interactuar amb el nucli del SO. Aquest, va substituir
l'antic init, sent el primer procés que s'executa en el sistema i per tant 
és el procés pare de tots els demés. 


### Estructura general

Systemd per defecte emmagatzema els logs a /var/log/journal/. Dins d'aquests
directori crea un subdirectori amb el "UID" del sistema. 

Els logs que genera systemd, estan en format binari, que dona per tant, 
millor rendiment en indexació, per tant d'exploració, i per últim d'integritat
d'aquests. Per contra no podem explorar-los amb un simple cat. Per per-ho,
tenim un client que utilitza systemd per mostrar els logs.

#### Journalctl

##### Estructura del missatge

L'estructura general del missatge, és molt semblant a la del syslog, encara
que hi ha diferències:

* Els missatges d'error són més grans i tenen un color vermell i en negreta.
* El time stamp, és convertit a la hora local del sistema.
* Tots els logs són mostrats, també els que estan rotats. 
* L'inici d'un nou boot, és mostrat de manera diferent i marcada, per diferenciar-los.

Un exemple sería:

*May 16 16:24:58 localhost.localdomain su[6439]: (to root) eric on pts/3*


### Enrutament amb systemd

Per fer aquesta part, s'han creat dos màquines virtuals amb la última versió
de Fedora, ja que per instal.lar els paquets necessaris, la versió que teniem
a classe no estava suportada. En concret la versió 23. 

Per fer la concentració de logs amb journal, hi ha dos serveis que tenim que utilitzar:
journal-remote( que ens permet captar els logs ) i journal-upload( que ens permet
enviar els logs a una màquina remota). El paquet que els conté, és el
systemd-journal-gateway. 

#### Problemes generals

A l'hora de fer una recerca, per trobar informació de journald, el dimoni 
que s'encarrega de les tasques que tenen que veure amb logs, m'he trobat 
que no hi ha molta inforamció a nivell usuari sense experiencia. A més m'he 
trobat amb molts problemes amb la documentació, amb una informació molt escassa,
amb errors, etc. A mes d'aquest problema, hi ha un molt greu, i es que hi ha 
molts bugs coneguts. A pàgines com github, on la gent comenta els seus problemes,
hi ha bastants posts on, coincideixen que journald no està encara per ser incorporat
en aquests temes. Li falta encara per polir. Dit això, encara amb problemes,
gràcies a forums on la gent que no te intenció lucrar-se, he aconseguit 
centrarlitzar els logs en una sol host.

#### Configuració del servidor i client

El contexte general de les proves, serà igual al que vam utilitzar en el cas
de syslog, però amb dos màquines virtuals.

A l'hora de configurar els hosts, utilitzarem els manuals de systemd-upload
i systemd-remote.

##### Client

Primer de tot instal.lem el software necessari. En concret l'ordre és:

    yum install -y systemd-journal-gateway

Per configurar el client tenim que editar el següent fitxer de configuració:

    vim /etc/systemd/journal-upload.conf

Els logs que s'enviaran al servidor, poden utilitzar el protocol http i https,
però de moment https no funciona tal i com es menciona als fitxers de configuració.
Per tant utilitzarem només http.

La linia:  

    URL=http://172.16.0.10:19532
    
Està indicant la url del servidor el port que utilitzarà, que és el per defecte,
i el protocol.


Per fer que journal-upload estigui on en l'arrancada del sistema:

    systemctl enable systemd-journal-upload.service
    
 Per últim fem un restart del servei per que agagi la nova configuració:
 
    systemctl restart systemd-journal-upload.service
    
Al fer el status del servei, veurem que el servei esta failed, per que no 
pot llegir ni escriure al directori /var/lib/systemd/journal-upload. Una solució
que vaig trobar per internet era afegir a systemd-journal-upload al grup 
systemd-journal que si te permisos. Però no vaig tenir éxit. Així que 
temporalment he donat permisos 777 al directori.

    chmod 777 /var/lib/systemd/journal-upload
    
A més, tenim que afegir a l'usuari systemd-journal-upload al grup system-journal,
per tal que pugui escriure i llegir a aquest directori:

    usermod -a -G systemd-journal systemd-journal-remote 

Per últim desactivem el firewalld i posem a permissive el selinux:

    systemctl stop firewalld
    systemctl disable firewalld
    setenforce 0
    
##### Servidor 

Per la part del servidor, podem fer que el servidor prengui el rol de pasiu
(el servidor espera a conexions, a l'espera d'events) o per d'altra banda 
actiu( va a demanar al client els logs ). En aquest cas faré que el servidor
prengui el rol de passiu.

Primer de tot instal·lem el paquet que he esmentat anteriorment:

    yum install -y systemd-journal-gateway 

Per configurar el port que utilitzarà el journal-remote tenim que editar 
el fitxer /etc/systemd/system/sockets.target.wants/systemd-journal-remote.socket.
Però en el nostre cas deixarem el que hi ha per defecte.

Per configurar paràmetres del journal-remote editem el fitxer 
/lib/systemd/system/systemd-journal-remote.service. En el nostre cas
editarem el protocol a utilitzar(http) ja que encara que estigui inclós
https, no funciona correctament. També es pot editar el directori on 
aniràn els logs rebuts, a més de mols paràmetres més.

Tenim que assegurar-nos que el directori on aniràn els logs existeixi, de lo
contrari no arrencarà el servei:

    mkdir /var/log/journal/remote
    chown systemd-journal-remote /var/log/journal/remote
    
    
El propi fitxer de configuració del servei a /etc/systemd/journal-remote.conf
podem configurar si utilitzarà https( per tant ssl ), entre d'altres.

Per últim fem un restart del servei:

    systemctl restart systemd-journal-remote
    
Amb tot això ja tenim tot configurat per tranferir els logs amb journal.

#### Configuració https amb journal

Journald ens dona la opció d'enviar els logs via https. Això és el que diu 
la documentació. Ara bé, a l'hora de configurar-ho, el dimoni journal-upload
no consegueix servir els logs al journal-remote. Amb l'ordre netstat podem 
veure que el servidor te obert el port per defecte, i a més pot rebre dades.
El missatge d'error que ens dona el journal-remote al fer un status del servei,
és que hi ha un error en el microhttpd, que utilitzen els dos dimonis per
transferir els logs. No hi ha molta informació a internet sobre aquest problema,
relacionat amb journald.  

### Exploració dels logs amb journalctl

Per defecte tots els usuaris tenen permis per poder inspeccionar els seus
logs privats. Per defecte els logs estan a /var/log/journal/ID/. Per poder
inspeccionar tots els logs, tenim que ser super usuari o podem afegir a l'usuari 
que volguem als grups, systemd-journal, adm o wheel. Per exemple:

    usermod -a -G wheel pere
    
Quan cridem a journalctl amb el terminal sense opcions, per defecte 
ens mostra tots els logs que hi ha en el sistema, del path per defecte on 
estan allotjats. 

Una de les característiques que dona journald respecte a syslog es la inclusió de,
la hora local del sistema. Per veure les que suporta journalctl:

    timedatectl list-timezones

I per fixar-la com a predeterminada:

    timedatectl set-timezone "zone"
    
Una altra opció interesant és veure el time-stamp en format UTC:

    journalctl --utc

#### Filtrat

Hi ha moltes opcions de filtrat, però he recollit les que són més importants

##### Per boots

Per veure els missatges des del últim boot:

    journalctl -b

Per veure els tots els boots de la màquina:

   journalctl --list-boots

Amb això veurem el número de boots de la màquina, i amb l'opció -b,
podrem escollir el boot que indiquem. 

##### Per data

Journalctl permet el filtrat posant límits com "fins" ( --until ) o 
"des de" ( --since ). El format de la data ha de ser:

    YYY-MM-DD HH:MM:SS
    
Si la segona part és absent, s'utilitzarà "00:00:00".

Un exemple de filtrat per data seria:

    journalctl --since "2015-01-10" --until "2015-02-10"

##### Per servei 

Possiblement és l'opció més utilitzada:

    journalctl -u httpd 
    
També podem combinar aquests filtres amb els anteriors:


    journalctl -u http --since "2016-10-10"
    
##### Per pid,uid o gid

Per pid:

    journalctl '_PID=8088

Per uid:

    journalctl '_UID=33
    
Per gid:

    journalctl '_GID=0


##### Kernel

    journalctl -k

#### Modificació 

Per defecte journalctl ens mostra els logs expandits, del tal manera que 
ocupen tota la pantalla i per veure tot el missatge a vegades tenim que 
desplaçar a la dretra el terminal. Per fer que això no passi:

    journalctl --no-full
    
Per deixar-ho com estava:

    journalctl -a

Si volem processar la inforamció, tenim que treure el paginat del journalctl.
Per fer-ho:

   journalctl --no-pager
    
#### Formats de sortida

Si volguessim un format de sortida diferent al per defecte:

    journalctl -o "format"

Els més comuns són:

* export ( format binari )
* json i json-pretty
* short ( format syslog )
* verbose


Per últim també cal mencionar que aquestes opcions seràn aplicades al logs
generats en el path per defecte. Si volem que tinguin efecte en un log diferent:

    journalctl --file 

O també un path:

    journalctl --directory
    
### Manteniment dels logs amb journald

Per configurar el manteniment que farà journald amb els logs, tenim que editar
el fitxer /etc/systemd/journald.conf

Els logs que genera journald poden ser: "volatile", guardats només en memòria.
"Persistent" guardats en el disc. Aquests es guardaran en /var/log/journal.
Si el directori no existeix, no es guardaran els logs. "Auto", el mateix comportament 
que "Persistent" però si el directori no existeix el crea. Per últim "None", que no guarda
logs.

Les ordres més importants són:

* SystemMaxUse: Especifica l'espai màxim que pot utilitzar journald en disc.
* SystemMaxFileSize: Quin tamany màxim pot tenir un log abans de ser rotat.
* SplitMode: Ens permet fer un split dels logs per: uid, login and none.
* Compress: Valor boolea que permet comprimir o no els logs.

Pér veure el disc ocupat pels logs:

    journalctl --disk-usage
    
Journalctl no fa un rotate con syslog. Aquest només te un fitxer i segons la 
mida màxima que li hem indicat, va guardant la informació, esborrant la antiga.    

