FROM ubuntu:xenial

MAINTAINER Martins Balodis

ENV DEBCONF_NONINTERACTIVE_SEEN="true" TIMEZONE="UTC" DISPLAY=":1"
RUN locale-gen en_US.UTF-8
ENV LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8"

# laravel configuration
ENV DB_HOST="localhost" DB_DATABASE="test_database" DB_USERNAME="root" DB_PASSWORD="root" DISABLE_NOTIFIER="true"

# configuration and startup scripts
ADD fs /

# install all dependencies
RUN apt-get update && \
apt-get install -qqy software-properties-common curl sudo && \
add-apt-repository ppa:ondrej/php && \
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && \
apt-get update && \
/bin/bash -c "debconf-set-selections <<< 'mysql-server mysql-server/root_password password $DB_PASSWORD'" && \
/bin/bash -c "debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $DB_PASSWORD'" && \
DEBIAN_FRONTEND=noninteractive apt-get -y install  wget \
nano mysql-client php7.1-mcrypt php7.1-cli php7.1-mysql php7.1-intl php7.1-fpm php7.1-mbstring git \
build-essential php7.1-curl php7.1-bcmath php7.1-ssh2 python-pip tar unzip php7.1-xml \
nodejs psmisc php7.1-gd php7.1-memcache lsof iputils-ping php7.1-mongodb php7.1-zip \
openjdk-8-jre-headless xfonts-100dpi xfonts-75dpi \
xfonts-scalable xfonts-cyrillic tightvncserver supervisor expect \
firefox=45.0.2+build1-0ubuntu1 chromium-browser fonts-ipafont-gothic xfonts-scalable openssh-server \
gconf2 \
mysql-server mysql-client \
mongodb \
net-tools \
apt-transport-https \
ca-certificates \
lxc \
iptables \
bridge-utils \
python-software-properties \
cgroupfs-mount \
psmisc \
zip && \
pip install --upgrade awscli && \
mkdir /opt/selenium && \
wget http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.0.jar -O /opt/selenium/selenium-server-standalone.jar && \
/usr/local/bin/download-images.sh && \
wget http://chromedriver.storage.googleapis.com/2.26/chromedriver_linux64.zip && \
unzip chromedriver_linux* && \
rm -rf chromedriver_linux* && \
mv chromedriver /usr/local/bin/chromedriver && \
expect -c 'set timeout 3;spawn /usr/bin/vncpasswd;expect "*?assword:*";send -- "selenium\r";expect "*?erify:*";send -- "selenium\r";expect "*?view-only password*";send -- "n\r";send -- "\r";expect eof' && \
sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
sed -i 's/^\(log_error\s.*\)/# \1/' /etc/mysql/my.cnf && \
mkdir /var/run/mysqld && \
chown mysql:mysql /var/run/mysqld && \
touch /root/.xsession && \
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
DEBIAN_FRONTEND=noninteractive apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' && \
apt-get update -qq && \
apt-get install -qqy docker-engine && \
apt-get remove --purge -y software-properties-common python-software-properties expect && \
apt-get autoremove -y && \
apt-get clean && \
apt-get autoclean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
phpenmod mcrypt &&  \
npm install -g bower && \
npm install -g gulp && \
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer && \
rm -rf /var/lib/apt/lists/* && \
mkdir /root/.ssh && \
touch /root/.ssh/known_hosts && \
ssh-keyscan github.com >> /root/.ssh/known_hosts && \
ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts

# Disable the SUID sandbox so that Chrome can launch without being in a privileged container.
# One unfortunate side effect is that `google-chrome --help` will no longer work.
RUN dpkg-divert --add --rename --divert /usr/bin/chromium-browser.real /usr/bin/chromium-browser && \
    echo "#!/bin/bash\nexec /usr/bin/chromium-browser.real --no-sandbox --disable-gpu \"\$@\"" > /usr/bin/chromium-browser && \
    chmod 755 /usr/bin/chromium-browser

# do some container configuration
RUN /usr/local/bin/configure_container.sh

# Expose Ports
EXPOSE 4444 5901 3306 27017 9515 2376
