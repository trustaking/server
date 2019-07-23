#!/bin/bash
# =================== YOUR DATA ========================
#bash <( curl -s https://raw.githubusercontent.com/trustaking/server/master/install-server.sh )
SERVER_IP=$(curl --silent ipinfo.io/ip)
SERVICE_END_DATE="2020-05-31"
SERVICE_DESC=" trustaking.com service. Service ends on "$SERVICE_END_DATE
ONLINE_DAYS=365
PRICE="15\.00"
# =================== YOUR DATA ========================
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}* Sorry, this script needs to be run as root. Do \"sudo su root\" and then re-run this script${NONE}"
    exit 1
    echo -e "${NONE}${GREEN}* All Good!${NONE}";
fi

read -p "Which Fork (redstone, x42, impleum, city, stratis, obsidian)? " fork
read -p "What sub-domain (default=${fork})? " subdomain
read -p "Mainnet (m) or Testnet (t)? " net
read -p "Which branch (default=master)? " branch

if [[ ${subdomain} == '' ]]; then 
    subdomain="${fork}"
fi

if [[ ${branch} == '' ]]; then 
    branch="master"
fi

# =================== YOUR DATA ========================
SERVER_NAME="${subdomain}.trustaking.com"
REDIRECTURL="${SERVER_NAME}\/activate.php"
DNS_NAME="${subdomain}.trustaking.com"
USER="$fork-web"
SUDO_PASSWORD="$fork-web" ## TODO: create random password
MYSQL_ROOT_PASSWORD="$fork-web" ## TODO: create random password
COINSERVICEINSTALLER="https://raw.githubusercontent.com/trustaking/server/master/install-coin.sh"
COINSERVICECONFIG="https://raw.githubusercontent.com/trustaking/server/master/config/config-$fork.sh"
WEBFILE="https://github.com/trustaking/node.git"
RPCUSER=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
RPCPASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

#TODO: Replace with config files

if [[ "$net" =~ ^([tT])+$ ]]; then
    case $fork in
         stratis)
            apiport="38221"; # "37221" <Main Stratis
            ;;
         redstone)
            apiport="38222"; # "37222" <Main Redstone
            ;;
        x42)
           apiport="42221"; # "42220" <Main X42
           ;;
        city)
           apiport="24335"; # "4335" <Main City
           apiver="&api-version=1.0";
        ;; 
        impleum)
           apiport="38222"; # "39222" <Main Impleum
            ;;
        obsidian)
            apiport="47221" # "47221" <Main Obsidian
            ;;
         *)
           echo "$fork has not been configured."
           exit
           ;;
    esac
else 
    case $fork in
        stratis)
            apiport="37221";
            ;;
         redstone)
            apiport="37222";
            ;;
         x42)
            apiport="42220";
            ;;
         city)
            apiport="4335";
            apiver="&api-version=1.0";
            ;; 
         impleum)
            apiport="39222";
            ;;
        obsidian)
            apiport="47221" # "47221" <Main Obsidian
            ;;
         *)
            echo "$fork has not been configured."
            exit
            ;;
    esac
fi

# =================== YOUR DATA ========================
read -p "Are you using DNS(y) or IP(n)?" dns

if [[ "$dns" =~ ^([nN])+$ ]]; then
    DNS_NAME=$(curl --silent ipinfo.io/ip)
fi

# SSH access via password will be disabled. Use keys instead.
###### add manually for aruba
PUBLIC_SSH_KEYS=""

# if vps not contains swap file - create it
SWAP_SIZE="3G"

TIMEZONE="Etc/GMT+0" # list of avaiable timezones: ls -R --group-directories-first /usr/share/zoneinfo

# =================== AUTOMATION ================

# Prefer IPv4 over IPv6 - make apt-get faster

sudo sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf

# Upgrade The Base Packages

apt update -qy
apt upgrade -qy

# Add A Few PPAs To Stay Current

apt -qy install software-properties-common

apt-add-repository ppa:nginx/development -y
apt-add-repository ppa:ondrej/nginx -y
apt-add-repository ppa:chris-lea/redis-server -y
apt-add-repository ppa:ondrej/apache2 -y
apt-add-repository ppa:ondrej/php -y
apt-add-repository ppa:certbot/certbot -y

# Update Package Lists

apt update -qy

# Base Packages

apt-get install -qy build-essential curl fail2ban \
gcc git libmcrypt4 libpcre3-dev python-certbot-nginx \
make python2.7 python-pip supervisor ufw unattended-upgrades \
unzip whois zsh mc p7zip-full htop

# Install Python Httpie

pip install httpie

# Disable Password Authentication Over SSH

sed -i "/PasswordAuthentication yes/d" /etc/ssh/sshd_config
echo "" | sudo tee -a /etc/ssh/sshd_config
echo "" | sudo tee -a /etc/ssh/sshd_config
echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config

# Restart SSH

ssh-keygen -A
service ssh restart

# Set The Hostname If Necessary

echo "${SERVER_NAME}" > /etc/hostname
sed -i "s/127\.0\.0\.1.*localhost/127.0.0.1	${SERVER_NAME} localhost/" /etc/hosts
hostname ${SERVER_NAME}

# Set The Timezone

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# Create The Root SSH Directory If Necessary

if [ ! -d /root/.ssh ]
then
    mkdir -p /root/.ssh
    touch /root/.ssh/authorized_keys
fi

# Setup User

useradd $USER
mkdir -p /home/$USER/.ssh
adduser $USER sudo

# Setup Bash For User

chsh -s /bin/bash $USER
cp /root/.profile /home/$USER/.profile
cp /root/.bashrc /home/$USER/.bashrc

# Set The Sudo Password For User

PASSWORD=$(mkpasswd $SUDO_PASSWORD)
usermod --password $PASSWORD $USER

# Build Formatted Keys & Copy Keys To User

cat > /root/.ssh/authorized_keys << EOF
$PUBLIC_SSH_KEYS
EOF

cp /root/.ssh/authorized_keys /home/$USER/.ssh/authorized_keys

# Create The Server SSH Key

ssh-keygen -f /home/$USER/.ssh/id_rsa -t rsa -N ''

# Copy Github And Bitbucket Public Keys Into Known Hosts File

ssh-keyscan -H github.com >> /home/$USER/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> /home/$USER/.ssh/known_hosts

# Setup Site Directory Permissions

chown -R $USER:$USER /home/$USER
chmod -R 755 /home/$USER
chmod 700 /home/$USER/.ssh/id_rsa

# Setup Unattended Security Upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "Ubuntu xenial-security";
};
Unattended-Upgrade::Package-Blacklist {
    //
};
EOF

cat > /etc/apt/apt.conf.d/10periodic << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Setup UFW Firewall

ufw allow 22
ufw allow 'Nginx Full'
ufw --force enable

# Allow FPM Restart

echo "$USER ALL=NOPASSWD: /usr/sbin/service php7.3-fpm reload" > /etc/sudoers.d/php-fpm

# Configure Supervisor Autostart

systemctl enable supervisor.service
service supervisor start

# Configure Swap Disk

if [ -f /var/node_swap.img ]; then
    echo "Swap exists."
else
    fallocate -l $SWAP_SIZE /var/node_swap.img
    chmod 600 /var/node_swap.img
    mkswap /var/node_swap.img
    swapon /var/node_swap.img
    echo "/var/node_swap.img none swap sw 0 0" >> /etc/fstab
    echo "vm.swappiness=30" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
fi

# Install Base PHP Packages

sudo apt -qy install php7.3-fpm php7.3-common php7.3-mysql php7.3-xml \
php7.3-xmlrpc php7.3-curl php7.3-gd \
php-imagick php7.3-cli php7.3-dev php7.3-imap php7.3-mbstring \
php-sqlite3 php-memcached php7.1-mcrypt php7.3-bcmath php7.3-intl php7.3-readline \
php7.3-opcache php7.3-soap php7.3-zip unzip php7.3-pgsql php-msgpack \
gcc make re2c libpcre3-dev software-properties-common build-essential 

# Install Phalcon

#curl -s "https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh" | sudo bash
#sudo apt -qy install php7.3-phalcon
#sudo apt update

# Misc. PHP CLI Configuration

sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.3/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.3/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.3/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.3/cli/php.ini

# Configure Sessions Directory Permissions

chmod 733 /var/lib/php/sessions
chmod +t /var/lib/php/sessions

# Install Nginx & PHP-FPM

apt install -qy nginx php7.3-fpm

# Enable Nginx service
systemctl enable nginx.service

# Generate dhparam File

openssl dhparam -out /etc/nginx/dhparams.pem 2048

# Disable The Default Nginx Site

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
service nginx restart

# Tweak Some PHP-FPM Settings

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.3/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.3/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.3/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.3/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.3/fpm/php.ini
sed -i "s/short_open_tag.*/short_open_tag = On/" /etc/php/7.3/fpm/php.ini

# Setup Session Save Path

sed -i "s/\;session.save_path = .*/session.save_path = \"\/var\/lib\/php5\/sessions\"/" /etc/php/7.3/fpm/php.ini
sed -i "s/php5\/sessions/php\/sessions/" /etc/php/7.3/fpm/php.ini

# Configure Nginx & PHP-FPM To Run As User

sed -i "s/user www-data;/user $USER;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf
sed -i "s/^user = www-data/user = $USER/" /etc/php/7.3/fpm/pool.d/www.conf
sed -i "s/^group = www-data/group = $USER/" /etc/php/7.3/fpm/pool.d/www.conf
sed -i "s/;listen\.owner.*/listen.owner = $USER/" /etc/php/7.3/fpm/pool.d/www.conf
sed -i "s/;listen\.group.*/listen.group = $USER/" /etc/php/7.3/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.3/fpm/pool.d/www.conf

# Configure A Few More Server Things

sed -i "s/;request_terminate_timeout.*/request_terminate_timeout = 60/" /etc/php/7.3/fpm/pool.d/www.conf
sed -i "s/worker_processes.*/worker_processes auto;/" /etc/nginx/nginx.conf
sed -i "s/# multi_accept.*/multi_accept on;/" /etc/nginx/nginx.conf

# Install A Catch All Server

cat > /etc/nginx/sites-available/catch-all << EOF
server {
    return 404;
}
EOF

ln -s /etc/nginx/sites-available/catch-all /etc/nginx/sites-enabled/catch-all

cat > /etc/nginx/sites-available/${USER} << EOF
server {
    listen 80;
    server_name ${DNS_NAME};
    root /home/${USER}/${SERVER_NAME}/;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        index index.php;
        try_files \$uri \$uri/ \$uri.php;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    access_log off;
    error_log  /var/log/nginx/${SERVER_NAME}-error.log error;
    error_page 404 /index.php;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
        include fastcgi_params;
        fastcgi_intercept_errors on;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/${SERVER_NAME} /etc/nginx/sites-enabled/${SERVER_NAME}

# Restart Nginx & PHP-FPM Services

if [ ! -z "\$(ps aux | grep php-fpm | grep -v grep)" ]
then
    service php7.3-fpm restart
fi

service nginx restart
service nginx reload

# Add User To www-data Group

usermod -a -G www-data $USER
id $USER
groups $USER

### Install Node.js
#curl --silent --location https://deb.nodesource.com/setup_8.x | bash -
#apt-get update
#sudo apt -qy install nodejs
#npm install -g pm2
#npm install -g gulp

### Set The Automated Root Password

#export DEBIAN_FRONTEND=noninteractive
#debconf-set-selections <<< "mysql-community-server mysql-community-server/data-dir select ''"
#debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $MYSQL_ROOT_PASSWORD"
#debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $MYSQL_ROOT_PASSWORD"

### Install MySQL
#apt-get install -y mysql-server

## Configure Password Expiration
#echo "default_password_lifetime = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf

## Configure Access Permissions For Root & User
#sed -i '/^bind-address/s/bind-address.*=.*/bind-address = */' /etc/mysql/mysql.conf.d/mysqld.cnf
#mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" -e "GRANT ALL ON *.* TO root@'$SERVER_IP' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
#mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" -e "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
#service mysql restart

#mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" -e "CREATE USER '$USER'@'$SERVER_IP' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"
#mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" -e "GRANT ALL ON *.* TO '$USER'@'$SERVER_IP' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;"
#mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" -e "GRANT ALL ON *.* TO '$USER'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;"
#mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Install & Configure Redis Server
#apt-get install -y redis-server
#sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
#service redis-server restart

# Install & Configure Memcached
#apt-get install -y memcached
#sed -i 's/-l 127.0.0.1/-l 0.0.0.0/' /etc/memcached.conf
#service memcached restart

# Install & Configure Beanstalk
#apt-get install -y --force-yes beanstalkd
#sed -i "s/BEANSTALKD_LISTEN_ADDR.*/BEANSTALKD_LISTEN_ADDR=0.0.0.0/" /etc/default/beanstalkd
#sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd
#/etc/init.d/beanstalkd start

# Install Composer Package Manager

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Install SSL certificate if using DNS

if [[ "$dns" =~ ^([yY])+$ ]]; then
certbot --nginx \
  --non-interactive \
  --agree-tos \
  --email admin@trustaking.com \
  --domains ${SERVER_NAME}
fi

# Install Website
mkdir /home/${USER}/${SERVER_NAME}
cd /home/${USER}/
git clone ${WEBFILE} ${SERVER_NAME}
chown ${USER}:www-data /home/${USER}/${SERVER_NAME} -R
chmod g+rw /home/${USER}/${SERVER_NAME} -R
chmod g+s /home/${USER}/${SERVER_NAME} -R
cd /home/${USER}/${SERVER_NAME}
php /usr/local/bin/composer require trustaking/btcpayserver-php-client:dev-master

## Inject apiport & ticker into /include/config.php
sed -i "s/^\(\$ticker='\).*/\1$fork';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$api_port='\).*/\1$apiport';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$price='\).*/\1${PRICE}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$redirectURL='\).*/\1${REDIRECTURL}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$service_desc='\).*/\1${SERVICE_DESC}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$service_end_date='\).*/\1${SERVICE_END_DATE}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$online_days='\).*/\1${ONLINE_DAYS}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$api_ver='\).*/\1${apiver}';/" /home/${USER}/${SERVER_NAME}/include/config.php

#Inject RPC username & password into config.php
sed -i "s/^\(\$rpc_user='\).*/\1${RPCUSER}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$rpc_pass='\).*/\1${RPCPASS}';/" /home/${USER}/${SERVER_NAME}/include/config.php

## Inject apiport into /scripts/trustaking-*.sh files
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-add-funds.sh
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-balance.sh
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-setup.sh
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-withdraw-funds.sh
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/hot-wallet-setup.sh

sed -i "s/^\(\$apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-add-funds.ps1
sed -i "s/^\(\$apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-balance.ps1
sed -i "s/^\(\$apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-setup.ps1
sed -i "s/^\(\$apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-withdraw-funds.ps1

# Install Coins Service
read "Hit a key to install Coin service!" response
wget ${COINSERVICEINSTALLER} -O ~/install-coin.sh
wget ${COINSERVICECONFIG} -O ~/config-${fork}.sh
chmod +x ~/install-coin.sh
cd ~
~/install-coin.sh -f ${fork} -n ${net} -b ${branch}

# Install hot wallet setup
read "Hit a key to install hot wallet!" response
/home/${USER}/${SERVER_NAME}/scripts/hot-wallet-setup.sh

# Display information
echo "Website URL: "${DNS_NAME}
[ ! -d /var/secure ] && mkdir -p /var/secure 
echo "Requires keys.php, btcpayserver.pri & pub in /var/secure/ - run transfer.sh"