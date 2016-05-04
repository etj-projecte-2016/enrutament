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





