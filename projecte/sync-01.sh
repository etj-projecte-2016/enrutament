#!/bin/sh

/usr/bin/rsync -rtvz /var/log/kernel* root@i10:/var/tmp/backup
