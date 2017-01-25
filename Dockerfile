FROM ubuntu:xenial

MAINTAINER Martins Balodis

ENV DEBCONF_NONINTERACTIVE_SEEN="true" TIMEZONE="UTC" DISPLAY=":1"
RUN locale-gen en_US.UTF-8
ENV LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8"

# laravel configuration
ENV DB_HOST="localhost" DB_DATABASE="test_database" DB_USERNAME="root" DB_PASSWORD="root"

# configuration and startup scripts
ADD fs /

# install all dependencies
RUN apt-get update && \
apt-get install -y software-properties-common curl sudo && \
curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash - && \
apt-get update && \
/bin/bash -c "debconf-set-selections <<< 'mysql-server mysql-server/root_password password $DB_PASSWORD'" && \
/bin/bash -c "debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $DB_PASSWORD'" && \
DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common wget \
nano mysql-client php-mcrypt php-cli php-mysql php-intl php-fpm php-mbstring git \
build-essential php-curl php-bcmath php-ssh2 python-pip tar unzip php-xml \
nodejs psmisc php-gd php-memcache lsof iputils-ping php-mongodb \
openjdk-8-jre-headless xfonts-100dpi xfonts-75dpi \
xfonts-scalable xfonts-cyrillic tightvncserver supervisor expect \
firefox=45.0.2+build1-0ubuntu1 fonts-ipafont-gothic xfonts-scalable openssh-server \
mysql-server mysql-client \
mongodb \
net-tools && \
mkdir /opt/selenium && \
wget http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.0.jar -O /opt/selenium/selenium-server-standalone.jar && \
/usr/local/bin/download-images.sh && \
expect -c 'set timeout 3;spawn /usr/bin/vncpasswd;expect "*?assword:*";send -- "selenium\r";expect "*?erify:*";send -- "selenium\r";expect "*?view-only password*";send -- "n\r";send -- "\r";expect eof' && \
sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
sed -i 's/^\(log_error\s.*\)/# \1/' /etc/mysql/my.cnf && \
touch /root/.xsession && \
apt-get remove --purge -y software-properties-common expect && \
apt-get autoremove -y && \
apt-get clean && \
apt-get autoclean && \
rm -rf /var/lib/apt/lists/* && \
phpenmod mcrypt &&  \
npm install -g bower && \
npm install -g gulp && \
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer && \
rm -rf /var/lib/apt/lists/* && \
mkdir /root/.ssh && \
touch /root/.ssh/known_hosts && \
ssh-keyscan github.com >> /root/.ssh/known_hosts && \
ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts

# do some container configuration
RUN /usr/local/bin/configure_container.sh

# Expose Ports
EXPOSE 4444 5901 3306 27017

CMD ["/bin/bash", "/start.sh"]