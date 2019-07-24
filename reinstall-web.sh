#!/bin/bash
# =================== YOUR DATA ========================
#bash <( curl -s https://raw.githubusercontent.com/trustaking/server/master/reinstall-web.sh )
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
            apiver="&Segwit=true";
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
            apiport="47221";
            apiver="&Segwit=true";
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

## Add site-available and enable the website
if [ ! -f /etc/nginx/sites-available/${USER} ]; then

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

fi

# Re-Install Website
rm -rf /home/${USER}/${SERVER_NAME}
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
sed -i "s/^\(apiver=\).*/\1$apiver/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-add-funds.sh
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-balance.sh
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-setup.sh
sed -i "s/^\(apiver=\).*/\1$apiver/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-setup.sh
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-withdraw-funds.sh
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/hot-wallet-setup.sh

sed -i "s/^\(\$apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-add-funds.ps1
sed -i "s/^\(\$apiver=\).*/\1$apiver/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-add-funds.ps1
sed -i "s/^\(\$apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-balance.ps1
sed -i "s/^\(\$apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-setup.ps1
sed -i "s/^\(\$apiver=\).*/\1$apiver/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-setup.ps1
sed -i "s/^\(\$apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/trustaking-cold-wallet-withdraw-funds.ps1

# Display information

echo "Website URL: "${DNS_NAME}