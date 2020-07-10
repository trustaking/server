#!/bin/bash
# =================== YOUR DATA ========================
#bash <( curl -s https://raw.githubusercontent.com/trustaking/server/master/install-server-only.sh )
SERVER_IP=$(curl --silent whatismyip.akamai.com)

# if vps not contains swap file - create it
SWAP_SIZE="1G"

TIMEZONE="Etc/GMT+0" # list of avaiable timezones: ls -R --group-directories-first /usr/share/zoneinfo

# Prefer IPv4 over IPv6 - make apt-get faster

sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf

# Upgrade The Base Packages

apt update -qy
apt upgrade -qy

# Add A Few PPAs To Stay Current

apt -qy install software-properties-common

apt-add-repository ppa:nginx/development -y
apt-add-repository ppa:ondrej/nginx -y
apt-add-repository ppa:ondrej/php -y
apt-add-repository ppa:certbot/certbot -y

# Update Package Lists

apt update -qy

# Base Packages

apt-get install -qy build-essential curl fail2ban \
gcc git libmcrypt4 libpcre3-dev python-certbot-nginx \
make python2.7 python-pip supervisor ufw unattended-upgrades \
unzip whois zsh mc p7zip-full htop

# Set The Hostname If Necessary

echo "trustaking.com" > /etc/hostname
sed -i "s/127\.0\.0\.1.*localhost/127.0.0.1	trustaking.com/" /etc/hosts
hostname trustaking.com

# Set The Timezone

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
update-locale LANG="en_US.UTF-8"

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
ufw allow 7777
ufw allow 'Nginx Full'
ufw --force enable

# Configure Supervisor Autostart

systemctl enable supervisor.service
service supervisor start

# Configure Swap Disk

if [ -f /swap.img ]; then
    echo "Swap exists."
else
    fallocate -l $SWAP_SIZE /swap.img
    chmod 600 /swap.img
    mkswap /swap.img
    swapon /swap.img
    echo "/swap.img none swap sw 0 0" >> /etc/fstab
    echo "vm.swappiness=30" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
fi

# Install Base PHP Packages

apt -qy install php7.3-fpm php7.3-common php7.3-mysql php7.3-xml \
php7.3-xmlrpc php7.3-curl php7.3-gd \
php-imagick php7.3-cli php7.3-dev php7.3-imap php7.3-mbstring \
php7.3-sqlite3 php-memcached php7.1-mcrypt php7.3-bcmath php7.3-intl php7.3-readline \
php7.3-opcache php7.3-soap php7.3-zip unzip php7.3-pgsql php-msgpack \
gcc make re2c libpcre3-dev software-properties-common build-essential 

# Misc. PHP CLI Configuration

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.3/cli/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.3/cli/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.3/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.3/cli/php.ini

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

# Configure A Few More Server Things

sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.3/fpm/pool.d/www.conf

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

# Restart Nginx & PHP-FPM Services

if [ ! -z "\$(ps aux | grep php-fpm | grep -v grep)" ]
then
    service php7.3-fpm restart
fi

service nginx restart
service nginx reload

# Install Composer Package Manager

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Create a bash file to harden connectivity
cat > /root/harden.sh << EOF
# Disable Password Authentication Over SSH & switch default port
sed -ri 's/#Port 22/Port 7777/g' /etc/ssh/sshd_config
sed -ri 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config
sed -ri 's/#AllowTcpForwarding yes/AllowTcpForwarding no/g' /etc/ssh/sshd_config
sed -ri 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -ri 's/#UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
sed -ri 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/g' /etc/ssh/sshd_config
echo 'PermitRootLogin no' &>> /etc/ssh/sshd_config
ufw allow 7777 ## check vps provider has port 7777 open
# Restart SSH
ssh-keygen -A
service ssh restart
EOF

# Display information
echo
[ ! -d /var/secure ] && mkdir -p /var/secure 
echo "Run the following scripts:"
echo "bash <( curl -s https://raw.githubusercontent.com/trustaking/server/master/reinstall-coin.sh )"
echo "bash <( curl -s https://raw.githubusercontent.com/trustaking/server/master/reinstall-web.sh )"
echo "~/harden.sh"
echo "Copy over keys.ini, btcpayserver.pri to /var/secure/ using run transfer.sh"