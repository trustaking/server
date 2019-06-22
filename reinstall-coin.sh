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

read -p "Which Fork (redstone, x42, impleum, city, stratis)? " fork
read -p "Mainnet (m) or Testnet (t)? " net
read -p "Which branch (default=master)? " branch

if [${BRANCH} = ""]; then 
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
        ;; 
        impleum)
           apiport="38222"; # "39222" <Main Impleum
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
            ;; 
         impleum)
            apiport="39222";
            ;;
         *)
            echo "$fork has not been configured."
            exit
            ;;
    esac
fi

# =================== YOUR DATA ========================
read -p "Are you using IP(y) or DNS(n)?" response

if [[ "$response" =~ ^([yY])+$ ]]; then
    DNS_NAME=$(curl --silent ipinfo.io/ip)
fi


# Install Coins Service
wget ${COINSERVICEINSTALLER} -O ~/install-coin.sh
wget ${COINSERVICECONFIG} -O ~/config-${fork}.sh
chmod +x ~/install-coin.sh
cd ~
~/install-coin.sh -f ${fork} -n ${net} -b ${branch}

# Install hot wallet setup
sleep 60
/home/${USER}/${SERVER_NAME}/scripts/hot-wallet-setup.sh

# Display information
echo "Website URL: "${DNS_NAME}
[ ! -d /var/secure ] && mkdir -p /var/secure 
echo "Requires keys.php, btcpayserver.pri & pub in /var/secure/ - run transfer.sh"