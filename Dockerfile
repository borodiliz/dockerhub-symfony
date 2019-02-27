# Based on https://github.com/JangChun/docker-lemp

FROM ubuntu:18.04

MAINTAINER Borja Rodríguez Diliz <borja.rodriguez.diliz@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

################ Install packages ################

RUN apt-get update && apt-get install -y software-properties-common language-pack-en-base

RUN add-apt-repository ppa:ondrej/php

RUN apt-get update && \
    apt-get install -y php7.3 php7.3-mongodb php7.3-fpm php7.3-mysql php7.3-mbstring php7.3-cgi \
        php7.3-curl php7.3-dev php7.3-gd php7.3-imap php7.3-intl php7.3-zmq php7.3-http \
        php7.3-pspell php7.3-ps  php7.3-recode  php7.3-sqlite3 php7.3-tidy php7.3-zip php7.3-xdebug \
        php7.3-xmlrpc php7.3-xsl php7.3-mysql libssl-dev php7.3-dev pkg-config \
        mysql-client nginx curl supervisor git unzip nmap sudo apt-utils vim acl inetutils-ping && \
        rm -rf /var/lib/apt/lists/*

## Configuration
RUN sed -i 's/^listen\s*=.*$/listen = 127.0.0.1:9000/' /etc/php/7.3/fpm/pool.d/www.conf && \
    cd /etc/php/7.3/cli/conf.d && \
    ln -sf /etc/php/7.3/mods-available/mongodb.ini 20-mongodb.ini

COPY files/root /

################ Install packages ################


################ Section SSH ################
RUN apt-get update && \
    apt-get install -y openssh-server && \
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
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -

# nodejs includes matching npm as well
RUN apt-get install -y -q \
    nodejs \
    && apt-get -y autoclean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g bower grunt npm-check-updates karma pm2

################ Section Use NodeJS ################

################ Section Mongo Tools 4.0 ################
RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
RUN apt-get update && apt-get install -y mongodb-org-tools mongodb-org-shell
################ Section Mongo Tools 4.0 ################

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
RUN sudo phpdismod xdebug && service php7.3-fpm restart

ENV TERM xterm

ENV SSH_AUTHORIZED_KEY=$SSH_AUTHORIZED_KEY
ENV SSH_ID_RSA=$SSH_ID_RSA
ENV SSH_ID_RSA_PUB=$SSH_ID_RSA_PUB

ENV ON_ENTRY_SCRIPT=$ON_ENTRY_SCRIPT

VOLUME  ["/var/www"]

EXPOSE 80 22

ENTRYPOINT ["/entrypoint.sh"]
