# Based on https://github.com/JangChun/docker-lemp

FROM ubuntu:18.04

MAINTAINER Borja Rodríguez Diliz <borja.rodriguez.diliz@gmail.com>

################ Install packages ################

RUN apt-get update && apt-get install -y software-properties-common language-pack-en-base

RUN add-apt-repository ppa:ondrej/php

RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get -qq install -y \
        php7.4 php7.4-mongodb php7.4-fpm \php7.4-mysql php7.4-mbstring php7.4-cgi \
        php7.4-curl php7.4-dev php7.4-gd php7.4-imap php7.4-intl php7.4-zmq php7.4-http \
        php7.4-pspell php7.4-ps php7.4-sqlite3 php7.4-tidy php7.4-zip php7.4-xdebug \
        php7.4-xmlrpc php7.4-xsl php7.4-mysql libssl-dev php7.4-dev php-imagick pkg-config \
        mysql-client nginx curl supervisor git unzip nmap sudo apt-utils vim acl inetutils-ping && \
        rm -rf /var/lib/apt/lists/*

## Configuration
RUN sed -i 's/^listen\s*=.*$/listen = 127.0.0.1:9000/' /etc/php/7.4/fpm/pool.d/www.conf && \
    cd /etc/php/7.4/cli/conf.d && \
    ln -sf /etc/php/7.4/mods-available/mongodb.ini 20-mongodb.ini

COPY files/root /

################ Install packages ################


################ Section SSH ################
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server && \
    mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    useradd -s /bin/bash docker && echo "docker:docker" | chpasswd && \
    mkdir -p /home/docker && chown -R docker:docker /home/docker && \
    echo 'docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/docker && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"

RUN echo "export VISIBLE=now" >> /etc/profile

################ Section SSH ################

################ Section Use NodeJS ################
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

# nodejs includes matching npm as well
RUN apt-get install -y -q \
    nodejs \
    && apt-get -y autoclean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g bower grunt npm-check-updates karma pm2

################ Section Use NodeJS ################

################ Section Mongo Tools ################
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
RUN apt-get update && apt-get install -y mongodb-org-tools mongodb-org-shell
################ Section Mongo Tools ################

################ Install composer ################
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer
################ Install composer ################

################ Yarn ################
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

RUN sudo apt-get update && sudo apt-get install yarn
################ Yarn ################

################ Disable Xdebug by default so we improve performance ################
RUN sudo phpdismod xdebug && service php7.4-fpm restart

ENV TERM xterm
ENV ON_ENTRY_SCRIPT=$ON_ENTRY_SCRIPT

RUN sudo mkdir -p /root/.ssh/

VOLUME  ["/var/www"]
VOLUME  ["/root/.ssh/"]

EXPOSE 80 22

ENTRYPOINT ["/entrypoint.sh"]
