#!/bin/bash

if [ ! "$(ls -A /usr/local/etc/icinga2)" ]; then
	echo "=> Copying fresh config-files for /usr/local/etc/icinga2"
	cp -r /usr/local/etc/icinga2.dist/* /usr/local/etc/icinga2/

    echo "=> Setting up connection to master node"
    icinga2 node setup \
        --cn $ICINGA2_CLIENT_HOSTNAME \
        --zone $ICINGA2_CLIENT_HOSTNAME \
        --endpoint $ICINGA2_MASTER_FQDN,$ICINGA2_MASTER_FQDN,5665 \
        --parent_host $ICINGA2_MASTER_FQDN \
        --parent_zone master \
        --ticket $ICINGA2_CLIENT_TICKET \
        --trustedcert /opt/master.crt \
        --accept-config \
        --accept-commands \
        --disable-confd
fi

mkdir -p /usr/local/var/cache/icinga2
chown -R icinga:icinga /usr/local/var/cache/icinga2

mkdir -p /usr/local/var/log/icinga2
chown -R icinga:icinga /usr/local/var/log/icinga2

mkdir -p /usr/local/var/run/icinga2
chown -R icinga:icinga /usr/local/var/run/icinga2

mkdir -p /usr/local/var/lib/icinga2
chown -R icinga:icinga /usr/local/var/lib/icinga2

echo "=> Starting Icinga"

icinga2 daemon &

# Allow any signal which would kill a process to stop server
trap "killall icinga2" HUP INT QUIT ABRT ALRM TERM TSTP

i=0
while [ $i -lt 5 ] ; do
    sleep 5
    if pgrep -x "icinga2" > /dev/null
    then
        i=0
    else
        i=$[$i+1]
        echo "=> No icinga process found ($i)"
    fi
done