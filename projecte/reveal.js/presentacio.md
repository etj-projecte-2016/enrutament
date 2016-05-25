% Enrutament i concentració de logs amb Syslog i Journal
% Eric Torres Jara
% ASIX 2016

# Tema general del projecte

* Syslog
* Systemd
* Enrutament
* Exploració de logs

# Centralització de logs amb syslog

## Syslog

* Protocol
* Syslogd
* TCP 514
* Obsolet

## Estructura del missatge

1. Prioritat
2. Capcelera
3. Text

## Prioritat

Número de 8 bits que indica el recurs( 5 bits ) i el nivel d'importància (3 bits).

* Recurs de 0 fins 23 i la importància de 0 fins 7

## Càlcul prioritat

    Prioritat = Recurs * 8 + Importància
    
* Valors més baixos representen major prioritat

## Capcelera

Mmm dd hh:mm:ss + nom del host o direcció IP

## Text

Informació sobre el procés que ha generat el log.

* Nom del procés + ":" + contingut real del missatge

## Exemple

    May  2 12:50:35 i10 pengine[12009]: notice: LogActions: Move    ClusterIP	(Started i11 -> i10)

## Rsyslog

Eś una millora de syslogd ja obsolet. Utilitza el mateix RFC però amb millores:

* Permet el timestamp en milisegons, a més de la utilització de time-zones
* TCP per enviar els missatges
* Completa funcionalitat amb systemd journal  y SSL.

## Configuració del servidor(i10)

 * El fitxer general de rsyslog està a /etc/rsyslog.conf
 * Directori de treball és /var/log
 * Creació de regles a partir d'expressions regulars
 
## Configuració del servidor(i10)(2)

* Centralitzar-ho tot en un sol fitxer a /var/log/messages
* Dividir els logs segons el hosts, programa 
  
## Configuració del servidor(i10)(3)

El fitxer és /etc/rsyslog.conf:

```
    $template TmplAuth, "/var/log/HOSTS/%HOSTNAME%/%PROGRAMNAME%"
	$template TmplMsg, "/var/log/HOSTS/%HOSTNAME%/%PROGRAMNAME%"
	$template Msgs, "/var/log/HOSTS/%HOSTNAME%/messages"

	authpriv.* ?TmplAuth
	*.info,mail.none,authpriv.none,cron.none ?TmplMsg
	*.* ?Msgs
	& ~ 
```
## Configuració del servidor(i10)(4)

* Restart del servei

``` 
systemctl restart rsyslogd 

```
* Mirar el estat

```
systemctl status rsyslogd 

```
* Mirar /var/log/HOSTS/%HOSTNAME% 

``` 
ll /var/log/HOSTS/HOSTNAME

```

## Configuració del client(i11)

Només cal indicar la IP del servidor i que volem enviar

```
*.* @192.168.2.40:514

```

* Fer el restart del rsyslogd

## Exemple 

Ens demanen que cal tenir un dia els logs del kernel al propi client. 
A més a un servidor tenir un backup de "x" dies dels logs comprimits.

## Exemple 

* Tenim que generar aquests logs en un fitxer.

```
kern.*		/var/log/kernel
``` 

## Exemple: logrotate

Eïna d'administració de logs, que permet rotació d'aquests, compressió, 
esborrar-los etc.

* Rotar /var/log/kernel
* Diariament
* Cromprimit
* 2 fitxers previs

## Exemple: logrotate(2)

El fitxer és /var/log/kernel:

```
/var/log/kernel{
    missingok
    notifempty
    sharedscripts
    rotate 2
    hourly
    compress
    dateext
    dateformat %Y%m%d
    postrotate
    	/bin/touch /var/log/kernel
    endscript
}
```
## Exemple: logrotate(3)

* Més ràpid, cada minut

* Crear un script que executarà logrotate

```
#!/bin/sh

/usr/sbin/logrotate -vf /etc/logrotate.d/kernel
```

## Exemple: logrotate(4)

* Posar al cron aquest script i que s'executi cada minut.

```
# Executa  la rotació de logs cada minut
*/1 * * * * root	/var/tmp/rotate1min.sh
```

## Exemple: rsysnc(4)

Sincronitzar els logs a un servidor extern i guardar-los 7 dies.

* Rsysnc per sincronitzar carpetes remotes
* Cron per sincronitzar-les cada x minuts

## Exemple: rsysnc(5)

```
# Executa  la rotació de logs cada minut
*/1 * * * * root	/var/tmp/sync-01.sh
```

```
/usr/bin/rsync -rtvz /var/log/kernel* root@i10:/var/tmp/backup
```

# Exploració de logs generats amb syslog

## Tipús que hem generat

* Log massiu
* Logs desglossats

## Eïnes

* Grep
* Cut

# Centralització de logs amb Systemd

## Systemd

* Conjunt de dimonis d'administració del sistema
* Substitueix l'antic init
* Procés amb PID 1

## Journald 

* Fitxers en binari
* /var/log/journal
* journaltcl

## Estructura del missatge

* Missatges d'error més grans i tenen un color vermell i en negreta
* Time stamp convertir a hora local
* Tots els logs són mostrats, també els rotats
* Inici de nou boot

## Exemple

```
*May 16 16:24:58 localhost.localdomain su[6439]: (to root) eric on pts/3*
```

## Enrutament amb systemd

* 2 màquines virtuals amb Fedora 23
* Systemd-journal-remote
* Systemd-journal-upload

## Configuració del client

Paquet necessari és:

```
yum install -y systemd-journal-gateway
```
Cal fer:

```
systemctl enable systemd-journal-upload.service
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
```

## Configuració del client (2)

Editem /etc/systemd/journal-upload.conf amb:

```
URL=http://172.16.0.10:19532
```
Afegim systemd-journal-remote al grup systemd-journal:
```
usermod -a -G systemd-journal systemd-journal-remote 
```

## Configuració del servidor

* Mode actiu ( demana els logs al client )
* Mode passiu ( espera conexions )

En el meu cas només he pogut implementar mode passiu.

## Configuració del servidor (2)

Quin port està escoltant, editem /etc/systemd/system/sockets.target.wants/systemd-journal-remote.socket:

```
[Socket]
ListenStream=19532
```

## Configuració del servidor (3)

Protocol i carpeta destinada als logs:

```
vim /lib/systemd/system/systemd-journal-remote.service
```
I editem la següent linia:
```
[Service]
ExecStart=/usr/lib/systemd/systemd-journal-remote \
          --listen-http=-3 \
          --output=/var/log/journal/remote/
```

## Configuració del servidor (4)

Assegurar-nos de que el directori existeix:

```
mkdir /var/log/journal/remote
chown -R systemd-journal-remote /var/log/journal/remote
```

# Exploració de logs amb journald

## Journalctl

* Cada usuari pot veure el seu log
* systemd-journal, adm o wheel
```
usermod -a -G wheel pere
```

## Filtrat

* Per boot
* Per data
* Per servei
* Per pid,uid o gid
* Kernel

## Modificació 

* Per defecte en format less
* Ho podem treure per tenir un format clàssic

## Formats de sortida

journalctl -o "format"

* export ( format binari )
* json i json-pretty
* short ( format syslog )
* verbose

## Canviar el desti de les modificacions

* Seleccionar el fitxer que volguem:
```
journalctl --file 
```
* Seleccionar el directori:
```
journalctl --directory
```

# Manteniment dels logs amb journald

## Configuració del dimoni

/etc/systemd/journald.conf

* volatile
* Persistent
* Auto
* None

## Generació dels logs

* Només un fitxer general del sistema
* Split per uid o login

## Rotate

* SystemMaxUse: Especifica l'espai màxim que pot utilitzar journald en disc.
* SystemMaxFileSize: Quin tamany màxim pot tenir un log abans de ser rotat.
* SplitMode: Ens permet fer un split dels logs per: uid, login and none.

```
journalctl --disk-usage
```

# Conclusions

## Syslog

* Segueix la filosofia UNIX de un programa una tasca
* Si no t'agrada una programa afegeixes un que la faci
* Obsolet a l'hora de la exploració de logs
* Enrutament bastant entenedor
* Gran quantitat d'informació

## Journald

* Un únic programa que s'encarrega de tot
* Exploració de logs eficient
* No és tan configurable
* No hi ha gaire informació a internet
* Enrutament encara no està del tot acabat

# Gràcies per la vostra atenció

## Preguntes?


