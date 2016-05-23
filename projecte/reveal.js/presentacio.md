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

* Recurs de 0 fins 23 i l'importància de 0 fins 7

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

Les linies que cal configurar són:

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
ll /var/log/HOSTS/\%HOSTNAME\%```

## Configuració del client

Només cal indicar la IP del servidor i que volem enviar

```
*.* @192.168.2.40:514
```



