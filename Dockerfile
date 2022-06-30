# Based on https://github.com/JangChun/docker-lemp

FROM ubuntu:22.04

MAINTAINER Borja Rodríguez Diliz <borja.rodriguez.diliz@gmail.com>

################ Install packages ################

RUN apt update && apt -y upgrade && apt install lsb-release ca-certificates apt-transport-https software-properties-common -y

RUN mkdir -p /run/php/

RUN add-apt-repository ppa:ondrej/php

RUN apt update && \
        DEBIAN_FRONTEND=noninteractive apt -qq install -y \
        php8.1 php8.1-mongodb php8.1-fpm \php8.1-mysql php8.1-mbstring php8.1-cgi \
        php8.1-curl php8.1-dev php8.1-gd php8.1-imap php8.1-intl php8.1-zmq \
        php8.1-pspell php8.1-sqlite3 php8.1-tidy php8.1-zip php8.1-xdebug \
        php8.1-xmlrpc php8.1-xsl php8.1-mysql libssl-dev php8.1-dev php-imagick pkg-config \
        mysql-client nginx curl supervisor git unzip nmap sudo apt-utils vim acl inetutils-ping nano && \
        rm -rf /var/lib/apt/lists/*

## Configuration
RUN sed -i 's/^listen\s*=.*$/listen = 127.0.0.1:9000/' /etc/php/8.1/fpm/pool.d/www.conf && \
    cd /etc/php/8.1/cli/conf.d && \
    ln -sf /etc/php/8.1/mods-available/mongodb.ini 20-mongodb.ini

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
ENV NODE_VERSION 16.15.1

RUN mkdir -p $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
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
# Workaround until mongodb supports ubuntu 22 https://www.mongodb.com/community/forums/t/installing-mongodb-over-ubuntu-22-04/159931/4
RUN echo "deb http://security.ubuntu.com/ubuntu impish-security main" | sudo tee /etc/apt/sources.list.d/impish-security.list
RUN apt update
RUN apt install -y libssl1.1
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
RUN sudo phpdismod xdebug && service php8.1-fpm restart

ENV TERM xterm
ENV ON_ENTRY_SCRIPT=$ON_ENTRY_SCRIPT

RUN sudo mkdir -p /root/.ssh/

VOLUME  ["/var/www"]
VOLUME  ["/root/.ssh/"]

EXPOSE 80 22

ENTRYPOINT ["/entrypoint.sh"]

