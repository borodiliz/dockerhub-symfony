#!/bin/bash

set -x

if [[ ! -z $SSH_AUTHORIZED_KEY ]]
then
    mkdir -p /root/.ssh/
    echo $SSH_AUTHORIZED_KEY > /root/.ssh/authorized_keys
fi


if [[ ! -z $ON_ENTRY_SCRIPT ]] && [[ -f $ON_ENTRY_SCRIPT ]]
then
    $ON_ENTRY_SCRIPT
fi

exec /usr/bin/supervisord --nodaemon -c /etc/supervisor/supervisord.conf