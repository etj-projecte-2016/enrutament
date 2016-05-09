#**Enrutament i concentració de logs amb Syslog i Journal**


## Centralització de logs amb rsyslog

### Syslog

Syslog és un standart de facto( no està acceptat per un organisme estandaritzat, però si de forma popular ), utilitzat per la generació de logs en una xarxa informàtica. Els logs són missatges de seguretat que genera el sistema, encara que poden contenir qualsevol informació. El dimoni que utilitza aquest protocol és el syslogd, que envia missatges via UDP(encara que es pot configurar per que ho faci també per TCP), pel port 514. 

El protocol va ser creat per Eric Allman, com a part del projecte Sendmail. Encara que en un principi només era part d'aquest projecte, es va veure que era molt útil, i va començar a ser part d'altres projectes importants. Actualment forma part de quasi tots els sistemes Unix i GNU/Linux i altres sistemas com Microsoft Windows. Encara que sigui present, es considera aquest protocol obsolet, degut a l'aparició d'altres sistemes més potents(systemd) i la poca eficiència a l'hora de la manipulació dels logs generats. 

#### Estructura del missatge

El missatge que genera el syslog segueix el rfc3164, el qual indica que els missatges tenen 3 parts marcades:

    1. Prioritat
    2. Capcelera
    3. Text

##### Prioritat

La prioritat és un número de 8 bits que indica el recurs(qui ha generat el missatge) i el nivell d'importància. Els còdis del recurs són:  

    * 0: Missatges del kernel 
    * 1: Missatges de l'usuari
    * 2: Sistema de correo
    * 3: Dimonis del sistema
    * 4: Seguretat
    * 5: Missatges generats pel mateix dimoni syslogd
    * 6: Subsistema d'impressió
    * 7: Subsistema de missatges de xarxa
    * 8: Susbistema UUCP
    * 9: Susbistema d'hora
    * 10: Seguretat
    * 11: Dimoni del ftp
    * 12: Susbsitema NTP
    * 13: Inspecció del registre
    * 14: Alertas en el registre
    * 15: Dimoni del sistema d'hora
    * 16-23: Ús local

Codis del nivell d'importància: 

    * 0: Emergència, el sistema està inutilitzable
    * 1: Alerta, actuar inmediatament
    * 2: Crític, condicions crítiques
    * 3: Error
    * 4: Perill
    * 5: Avís, normal però caldia actuar
    * 6: Informació
    * 7: Missatges de baix nivell

##### Capcelera

És el segon camp, el qual conté, el temps en format Mmm dd hh:mm:ss, seguit del nom del host, o en el seu defecte la direcció ip.

##### Text

És l'últim camp de log, que dona informació sobre el procés que ha generat el log. Normalment comença amb el nom del procés que l'ha generat, seguit d'un caràcter no alfanumèric com ":" o un espai. Per últim el propi text que conté el contingut real del missatge.

Podem veure una línia d'exemple d'un log:

*May  2 12:50:35 i10 pengine[12009]: notice: LogActions: Move    ClusterIP	(Started i11 -> i10)*

### Rsyslog
 
Syslog com aplicació, ha quedat obsoleta per molts motius esmentats anteriorment. En aquest projecte utilitzarem rsyslog com aplicació, per a centralitzar els logs. 
Rsyslog utilitza el mateix estandard que utilitza syslog (RFC 3164), però extenent aquest últim. Les principals millores són:

*  Utilització de la ISO 8601. Permet el timestamp en milisegons, a més de la utilització de time-zones.
* Utilització de TCP per enviar els missatges.
* Completa funcionalitat amb systemd journal. 
* Completa funcionalitat amb SSL i GSS-API.

Entre d'altres millores.

### Configuració del servidor i client

Per començar la centralització de logs amb rsyslog. Desactivem journalctl, per que no tinguin cap mena de conflicte(encara que no tindria que tenir), per a fer les proves en aquest projecte.

El contexte general de les proves serà, 1 client que enviarà tot el que generi rsyslog (i11), i un servidor que agruparà tot al seu disc dur(i10).

A l'hora de configurar els hosts, utilizarem el [manual](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/3/html/Installation_and_Configuration_Guide/Configuring_the_rsyslog_Server.html) de configuració de redhat, per la configuració de rsyslog.

#### Servidor

En el nostre cas, tenim desactivat tant el selinux com el firewall(no és el més indicat, però es un entorn de proves). El fitxer de configuració de rsyslog és el /etc/rsyslog.conf. En el nostre cas el [fitxer](https://github.com/etj-projecte-2016/enrutament/blob/master/rsyslog.conf) quedaria d'aquesta manera. A l'hora de filtrar el que volem i com ho volem, tindriem que utilitzar expressions regulars. Per exemple:  

> * mail.* /var/log/messages 
* authpriv.* /var/log/secure
 
En aquests casos estem dient que tot el que comenci en mail,authpriv es dessi, en el seu respectiu log.

Però també tenim l'opció de crear templates:

> * $template TmplAuth, "/var/log/HOSTS/%HOSTNAME%/%PROGRAMNAME%"
* $template TmplMsg, "/var/log/HOSTS/%HOSTNAME%/%PROGRAMNAME%"
* $template Msgs, "/var/log/HOSTS/%HOSTNAME%/messages"

> * authpriv.* ?TmplAuth
* *.info,mail.none,authpriv.none,cron.none ?TmplMsg
* *.* ?Msgs
* & ~ 
 
Amb l'opció $template, creem una variable que es diu TemlAuth, i dessarà tot el que acabi per TmplAuth a, /var/log/HOSTS/nom-del-host/nom-del-programa. Amb aquesta configuració estem dessant per cada hosts un log per cada programa que els generi, i a més tot el que es generi en un log concentrat que es diu messages. 

Hi ha moltes configuracions possibles, depenent del que et convingui més, voldràs tenir tot en un fitxer o per contra desglossat en diferents.

#### Client

Per d'altra banda cal configurar el client per que enviï els logs al servidor.

El [fitxer](https://github.com/etj-projecte-2016/enrutament/blob/master/rsyslog.conf.client) quedaria d'aquesta manera.

Cal configurar:

> * *.* @192.168.2.40:514

Li estem dient que tot el que generi rsyslog, ho enviï a la ip indicada.

Amb tot això tindriem configurat ja la centralització feta. El següent tema a explorar és, els logs que generem seran enviats tots al servidor, o per contra volem que també es quedin els logs al client, per tal de tenir un backup de seguretat? 

### Administració de logs amb logrotate i creació d'escripts

Per explorar aquest tema, exposo el seguent cas. Ens proposen que els logs s'enviin al servidor, però que a més d'això es quedi un backup de dels logs generals pel kernel. 




