#!/bin/bash

set -x

if [[ "x$SSH_AUTHORIZED_KEY" != "x" ]]
then
    mkdir -p /root/.ssh/
    echo $SSH_AUTHORIZED_KEY > /root/.ssh/authorized_keys
fi


if [[ -f /var/www/docker/deploy.sh ]]
then
    /var/www/docker/deploy.sh
fi

exec /usr/bin/supervisord --nodaemon -c /etc/supervisor/supervisord.conf
