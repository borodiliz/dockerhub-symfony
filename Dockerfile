# Based on https://github.com/JangChun/docker-lemp

FROM ubuntu:20.04

MAINTAINER Borja Rodríguez Diliz <borja.rodriguez.diliz@gmail.com>

################ Install packages ################

RUN apt-get update && apt-get install -y software-properties-common language-pack-en-base

RUN mkdir -p /run/php/

RUN add-apt-repository ppa:ondrej/php

RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get -qq install -y \
        php8.0 php8.0-mongodb php8.0-fpm \php8.0-mysql php8.0-mbstring php8.0-cgi \
        php8.0-curl php8.0-dev php8.0-gd php8.0-imap php8.0-intl php8.0-zmq \
        php8.0-pspell php8.0-ps php8.0-sqlite3 php8.0-tidy php8.0-zip php8.0-xdebug \
        php8.0-xmlrpc php8.0-xsl php8.0-mysql libssl-dev php8.0-dev php-imagick pkg-config \
        mysql-client nginx curl supervisor git unzip nmap sudo apt-utils vim acl inetutils-ping && \
        rm -rf /var/lib/apt/lists/*

## Configuration
RUN sed -i 's/^listen\s*=.*$/listen = 127.0.0.1:9000/' /etc/php/8.0/fpm/pool.d/www.conf && \
    cd /etc/php/8.0/cli/conf.d && \
    ln -sf /etc/php/8.0/mods-available/mongodb.ini 20-mongodb.ini

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
# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 14.15.1

RUN mkdir -p $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
#RUN export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" && . "$NVM_DIR/nvm.sh" && nvm install v14.15.1
# install node and npm
RUN . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# confirm installation
RUN node -v
RUN npm -v
RUN npm install -g bower grunt npm-check-updates karma pm2

################ Section Use NodeJS ################

################ Section Mongo Tools ################
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
RUN apt-get update && apt-get install -y mongodb-org-tools mongodb-org-shell
################ Section Mongo Tools ################

################ Install composer ################
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer
################ Install composer ################

################ Disable Xdebug by default so we improve performance ################
RUN sudo phpdismod xdebug && service php8.0-fpm restart

ENV TERM xterm
ENV ON_ENTRY_SCRIPT=$ON_ENTRY_SCRIPT

RUN sudo mkdir -p /root/.ssh/

VOLUME  ["/var/www"]
VOLUME  ["/root/.ssh/"]

EXPOSE 80 22

ENTRYPOINT ["/entrypoint.sh"]
