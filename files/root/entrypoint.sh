#!/bin/bash

set -x
mkdir -p /root/.ssh/

if [[ ! -z $SSH_AUTHORIZED_KEY ]]
then
    echo $SSH_AUTHORIZED_KEY > /root/.ssh/authorized_keys
fi
if [[ ! -z $SSH_ID_RSA ]]
then
    echo $SSH_ID_RSA > /root/.ssh/id_rsa
fi
if [[ ! -z $SSH_ID_RSA_PUB ]]
then
    echo $SSH_ID_RSA_PUB > /root/.ssh/id_rsa.pub
fi


if [[ ! -z $ON_ENTRY_SCRIPT ]] && [[ -f $ON_ENTRY_SCRIPT ]]
then
    $ON_ENTRY_SCRIPT
fi

exec /usr/bin/supervisord --nodaemon -c /etc/supervisor/supervisord.conf