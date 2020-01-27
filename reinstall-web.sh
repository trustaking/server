#!/bin/bash
# =================== YOUR DATA ========================
#bash <( curl -s https://raw.githubusercontent.com/trustaking/server/master/reinstall-web.sh )
SERVER_IP=$(curl --silent whatismyip.akamai.com)
# =================== YOUR DATA ========================
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}* Sorry, this script needs to be run as root. Do \"sudo su root\" and then re-run this script${NONE}"
    exit 1
    echo -e "${NONE}${GREEN}* All Good!${NONE}";
fi
clear
echo -e "${UNDERLINE}${BOLD}Trustaking Web Server Installation Guide${NONE}"
echo
read -p "Which Fork (redstone, x42, impleum, city, stratis, xds, solaris)? " fork
read -p "What sub-domain (default=${fork})? " subdomain
read -p "Mainnet (m) or Testnet (t)? " net

if [[ ${subdomain} == '' ]]; then 
    subdomain="${fork}"
fi

# =================== YOUR DATA ========================
SERVER_NAME="${subdomain}.trustaking.com"
REDIRECTURL="https:\/\/${SERVER_NAME}\/activate.php"
IPNURL="https:\/\/${SERVER_NAME}\/IPNlogger.php"
DNS_NAME="${subdomain}.trustaking.com"
USER="$fork-web"
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
            coldstakeui=1;
            payment=1;
            whitelist=1;
            printf -v apiver "%q" "&Segwit=true";
            ;;
        city)
            apiport="24335"; # "4335" <Main City
            coldstakeui=1
            ;; 
        impleum)
            apiport="38222"; # "39222" <Main Impleum
            ;;
        xds)
            apiport="48334";
            printf -v apiver "%q" "&Segwit=true";
            coldstakeui=1;
            payment=1;
            whitelist=1;
            ;;
        solaris)
            apiport="62009" # "62000" <Main Solaris
            coldstakeui=1
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
            coldstakeui=1;
            payment=1;
            whitelist=1;
            printf -v apiver "%q" "&Segwit=true";
            ;;
         city)
            apiport="4335";
            coldstakeui=1
            ;; 
         impleum)
            apiport="39222";
            ;;
        xds)
            apiport="48334";
            printf -v apiver "%q" "&Segwit=true";
            coldstakeui=1;
            payment=1;
            whitelist=1;
            ;;
        solaris)
            apiport="62000"
            coldstakeui=1
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

## Add site-available and enable the website
if [ ! -f /etc/nginx/sites-available/${SERVER_NAME} ]; then

cat > /etc/nginx/sites-available/${SERVER_NAME} << EOF
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

# Setup User
useradd $USER
mkdir -p /home/$USER/
adduser $USER sudo

# Setup Bash For User
chsh -s /bin/bash $USER
cp /root/.profile /home/$USER/.profile
cp /root/.bashrc /home/$USER/.bashrc

# Remove Sudo Password For User
echo "${USER} ALL=(ALL) NOPASSWD: ALL" &>> /etc/sudoers

# Setup Site Directory Permissions
chown -R $USER:$USER /home/$USER
chmod -R 755 /home/$USER

# Re-Install Website
rm -rf /home/${USER}/${SERVER_NAME}
mkdir -p /home/${USER}/${SERVER_NAME}
cd /home/${USER}/
git clone ${WEBFILE} ${SERVER_NAME}
chown ${USER}:www-data /home/${USER}/${SERVER_NAME} -R
chmod g+rw /home/${USER}/${SERVER_NAME} -R
chmod g+s /home/${USER}/${SERVER_NAME} -R
cd /home/${USER}/${SERVER_NAME}
#php /usr/local/bin/composer btcpayserver/btcpayserver-php-client
php /usr/local/bin/composer require trustaking/btcpayserver-php-client:dev-master

## Inject apiport & ticker into /include/config.php
sed -i "s/^\(\$ticker='\).*/\1$fork';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$api_port='\).*/\1$apiport';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$redirectURL='\).*/\1${REDIRECTURL}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$ipnURL='\).*/\1${IPNURL}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$api_ver='\).*/\1${apiver}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$coldstakeui='\).*/\1${coldstakeui}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$payment='\).*/\1${payment}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$whitelist='\).*/\1${whitelist}';/" /home/${USER}/${SERVER_NAME}/include/config.php

## Inject hot wallet name & password into keys.php
source /var/secure/credentials.sh
sed -i "s/^\(\$WalletName='\).*/\1${STAKINGNAME}';/" /var/secure/keys.php
sed -i "s/^\(\$WalletPassword='\).*/\1${STAKINGPASSWORD}';/" /var/secure/keys.php

#Inject RPC username & password into config.php
sed -i "s/^\(\$rpc_user='\).*/\1${RPCUSER}';/" /home/${USER}/${SERVER_NAME}/include/config.php
sed -i "s/^\(\$rpc_pass='\).*/\1${RPCPASS}';/" /home/${USER}/${SERVER_NAME}/include/config.php

#Inject API port into wallet setup script
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/hot-wallet-setup.sh

# Display information
echo
echo -e "Running a simulation for SSL renewal"
echo 
certbot renew --dry-run
echo && echo
echo "If the dry run was unsuccessful you may need to register & install your SSL certificate manually by running the following command: "
echo
echo "certbot --nginx --non-interactive --agree-tos --email admin@trustaking.com --domains ${DNS_NAME}"
echo
echo "Website URL: "${DNS_NAME}
[ ! -d /var/secure ] && mkdir -p /var/secure 
echo "Requires keys.php, btcpayserver.pri & pub in /var/secure/ - run transfer.sh"