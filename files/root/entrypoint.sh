#!/bin/bash

set -x

#chown -R www-data:www-data /var/www /var/log/php

exec /usr/bin/supervisord --nodaemon -c /etc/supervisor/supervisord.conf
