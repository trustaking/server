#!/bin/bash
# ============================================================================================
#bash <( curl -s https://raw.githubusercontent.com/trustaking/server/master/reinstall-web.sh )
# ============================================================================================

if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}* Sorry, this script needs to be run as root. Do \"sudo su root\" and then re-run this script${NONE}"
    exit 1
    echo -e "${NONE}${GREEN}* All Good!${NONE}";
fi
clear
echo -e "${UNDERLINE}${BOLD}Trustaking Web Server Installation Guide${NONE}"
echo
read -p "Which Fork (redstone, x42, impleum, city, strax, xds, solaris, amsterdamcoin)? " fork
read -p "What sub-domain (default=${fork})? " subdomain
read -p "Mainnet (m) or Testnet (t)? " net
read -p "Install hot wallet (y/n)? " hot

if [[ ${subdomain} == '' ]]; then 
    subdomain="${fork}"
fi

SERVER_IP=$(curl --silent whatismyip.akamai.com) #$(curl --silent ipinfo.io/ip)
SERVER_NAME="${subdomain}.trustaking.com"
REDIRECTURL="https://${SERVER_NAME}/activate.php"
IPNURL="" #"https://${SERVER_NAME}/IPNlogger.php"

DNS_NAME="${subdomain}.trustaking.com"
USER="${fork}-web"
WEBFILE="https://github.com/trustaking/node.git"

#Import Web Config

wget https://raw.githubusercontent.com/trustaking/server/master/config/config-$fork.sh -O ~/config-${fork}.sh
source ~/config-${fork}.sh

if [[ "$NET" =~ ^([mM])+$ ]]; then
    setMainVars
 else
    setTestVars
fi

setGeneralVars

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

fi

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

# Install SSL certificate
certbot --nginx \
  --non-interactive \
  --agree-tos \
  --email admin@trustaking.com \
  --domains ${SERVER_NAME}

# Setup User
useradd $USER
mkdir -p /home/$USER/
adduser $USER sudo

# Add User To www-data Group
usermod -a -G www-data $USER
id $USER
groups $USER

# Setup Bash For User
chsh -s /bin/bash $USER
cp /root/.profile /home/$USER/.profile
cp /root/.bashrc /home/$USER/.bashrc

# Remove Sudo Password For User
echo "${USER} ALL=(ALL) NOPASSWD: ALL" &>> /etc/sudoers

# Allow FPM Restart
echo "${USER} ALL=NOPASSWD: /usr/sbin/service php7.3-fpm reload" &>> /etc/sudoers.d/php-fpm

# Setup Site Directory Permissions
chown -R $USER:$USER /home/$USER
chmod -R 755 /home/$USER

# Re-Install Website
cd /
rm -rf /home/${USER}/${SERVER_NAME}
mkdir -p /home/${USER}/${SERVER_NAME}
cd /home/${USER}/
git clone ${WEBFILE} ${SERVER_NAME}
chown ${USER}:www-data /home/${USER}/${SERVER_NAME} -R
chmod g+rw /home/${USER}/${SERVER_NAME} -R
chmod g+s /home/${USER}/${SERVER_NAME} -R
cd /home/${USER}/${SERVER_NAME}
php /usr/local/bin/composer require btcpayserver/btcpayserver-php-client
#php /usr/local/bin/composer require trustaking/btcpayserver-php-client:dev-master

## Grab credentials
if [[ -f /var/secure/cred-${fork}.sh ]]; then
    source /var/secure/cred-${fork}.sh
fi

#Inject API port into wallet setup script
sed -i "s/^\(COINAPIPORT=\).*/\1$COINAPIPORT/" /home/${USER}/${SERVER_NAME}/scripts/hot-wallet-setup.sh
sed -i "s/^\(fork=\).*/\1$fork/" /home/${USER}/${SERVER_NAME}/scripts/hot-wallet-setup.sh

# Install hot wallet setup
if [[ "${hot}" =~ ^([yY])+$ ]]; then
    # This script builds credentials.sh 
    /home/${USER}/${DNS_NAME}/scripts/hot-wallet-setup.sh
fi

## Grab credentials
if [[ -f /var/secure/cred-${fork}.sh ]]; then
    source /var/secure/cred-${fork}.sh
fi

## Re-build the config.ini file and inject parameters
#rm /home/${USER}/${SERVER_NAME}/include/config.ini
cat > /home/${USER}/${SERVER_NAME}/include/config.ini << EOF
### Web Settings ###
redirectURL='${REDIRECTURL}'
ipnURL='${IPNURL}'
howtourl='${howtourl}'
whitelist='${whitelist}'
payment='${payment}'
exchange='${exchange}'
### Wallet name ###
AccountName='coldStakingHotAddresses'
WalletName='${STAKINGNAME}'
WalletPassword='${STAKINGPASSWORD}'
### RPC Details ###
rpcuser='${RPCUSER}'
rpcpass='${RPCPASS}'
### Coin Details ###
ticker='${subdomain}'
api_port='${COINAPIPORT}'
rpc_port='${COINRPCPORT}'
segwit='${segwit}'
### Debug set to 1 for detailed errors ###
debug='1'
maintenance='1'
EOF

# Display information
echo && echo
echo "Website URL: "${DNS_NAME}
echo "nano /home/${USER}/${DNS_NAME}/include/config.ini"
echo
echo "If the dry run was unsuccessful you may need to register & install your SSL certificate manually by running the following command: "
echo
echo "certbot --nginx --non-interactive --agree-tos --email admin@trustaking.com --domains ${DNS_NAME}"