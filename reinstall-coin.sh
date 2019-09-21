#!/bin/bash
# =================== YOUR DATA ========================
#bash <( curl -s https://raw.githubusercontent.com/trustaking/server/master/reinstall-coin.sh )
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
clear
echo -e "${UNDERLINE}${BOLD}Blockcore Node Installation Guide${NONE}"
echo

read -p "Which Fork (redstone, x42, impleum, city, stratis, obsidian)? " fork
read -p "Mainnet (m) or Testnet (t)? " net
read -p "Which branch (default=master)? " branch

if [${branch} = ""]; then 
branch="master";
fi

# =================== YOUR DATA ========================
SERVER_NAME="$fork.trustaking.com"
REDIRECTURL="http:\/\/${SERVER_NAME}\/activate.php"
DNS_NAME="$fork.trustaking.com"
USER="$fork-web"
SUDO_PASSWORD="$fork-web"
MYSQL_ROOT_PASSWORD="$fork-web"
COINSERVICEINSTALLER="https://raw.githubusercontent.com/trustaking/server/master/install-coin.sh"
COINSERVICECONFIG="https://raw.githubusercontent.com/trustaking/server/master/config/config-$fork.sh"
WEBFILE="https://github.com/trustaking/node.git"
RPCUSER=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
RPCPASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

# =================== YOUR DATA ========================
read -p "Are you using DNS(y) or IP(n)?" dns

if [[ "$dns" =~ ^([nN])+$ ]]; then
    DNS_NAME=$(curl --silent ipinfo.io/ip)
fi

# Install Coins Service
read -p "Hit a key to install Coin service!" response
wget ${COINSERVICEINSTALLER} -O ~/install-coin.sh
wget ${COINSERVICECONFIG} -O ~/config-${fork}.sh
chmod +x ~/install-coin.sh
cd ~
~/install-coin.sh -f ${fork} -n ${net} -b ${branch}

# Install hot wallet setup
read -p "Hit a key to install hot wallet!" response
/home/${USER}/${SERVER_NAME}/scripts/hot-wallet-setup.sh

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