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
read -p "Which Fork (redstone, x42, impleum, city, stratis, xds, solaris, amsterdamcoin)? " fork
read -p "What sub-domain (default=${fork})? " subdomain
read -p "Mainnet (m) or Testnet (t)? " net

if [[ ${subdomain} == '' ]]; then 
    subdomain="${fork}"
fi

# =================== YOUR DATA ========================
SERVER_NAME="${subdomain}.trustaking.com"
REDIRECTURL="https://${SERVER_NAME}/activate.php"
IPNURL="" 
#"https://${SERVER_NAME}/IPNlogger.php"
DNS_NAME="${subdomain}.trustaking.com"
USER="$fork-web"
WEBFILE="https://github.com/trustaking/node.git"

#TODO: Replace with config files

if [[ "$net" =~ ^([tT])+$ ]]; then
    case $fork in
         stratis)
            apiport="38221"; # "37221" <Main Stratis
            rpcport="26174";
            ;;
         redstone)
            apiport="38222"; # "37222" <Main Redstone
            rpcport="";
            ;;
        x42)
            apiport="42221"; # "42220" <Main X42
            rpcport="62343";
            whitelist=1;
           ;;
        city)
           apiport="24335"; # "4335" <Main City
           rpcport="24334";
            ;; 
        impleum)
           apiport="39222"; # "38222" <Main Impleum
           rpcport="16272";
            ;;
        xds)
            apiport="48334";
            rpcport="48333";
            segwit="true";
            whitelist=1;
            ;;
        solaris)
            apiport="62009"; # "62000" <Main Solaris
            rpcport="61009";
            ;;
        amsterdamcoin)
            apiport="63009"; # "62000" <Main Amsterdamcoin
            rpcport="51009";
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
            rpcport="16174";
            payment=1;
            ;;
         redstone)
            apiport="37222";
            rpcport="";
            ;;
         x42)
            apiport="42220";
            rpcport="52343";
            payment=1;
            whitelist=1;
            ;;
         city)
            apiport="4335";
            rpcport="4334";
            payment=1;
            whitelist=1;
            ;; 
         impleum)
            apiport="38222";
            rpcport="16172";
            ;;
        xds)
            apiport="48334";
            rpcport="48333";
            segwit="true";
            payment=1;
            whitelist=1;
            ;;
        solaris)
            apiport="62000";
            rpcport="61000";
            payment=1;
            whitelist=1;
            ;;
        amsterdamcoin)
            apiport="63000";
            rpcport="51000";
            payment=1;
            whitelist=1;
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

if [[ "$segwit" = "" ]]; then
    segwit="false"
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

# Install SSL certificate if using DNS

if [[ "$dns" =~ ^([yY])+$ ]]; then
certbot --nginx \
  --non-interactive \
  --agree-tos \
  --email admin@trustaking.com \
  --domains ${SERVER_NAME}
fi

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
sed -i "s/^\(apiport=\).*/\1$apiport/" /home/${USER}/${SERVER_NAME}/scripts/hot-wallet-setup.sh
sed -i "s/^\(fork=\).*/\1$fork/" /home/${USER}/${SERVER_NAME}/scripts/hot-wallet-setup.sh

# Install hot wallet setup
read -p "Hit a key to install hot wallet!" response
# This script builds credentials.sh 
/home/${USER}/${DNS_NAME}/scripts/hot-wallet-setup.sh

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
ticker='${fork}'
api_port='${apiport}'
rpc_port='${rpcport}'
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