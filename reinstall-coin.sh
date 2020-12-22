#!/bin/bash
# =================== YOUR DATA ========================
#bash <( curl -s https://raw.githubusercontent.com/trustaking/server/master/reinstall-coin.sh )
# =================== YOUR DATA ========================
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}* Sorry, this script needs to be run as root. Do \"sudo su root\" and then re-run this script${NONE}"
    exit 1
    echo -e "${NONE}${GREEN}* All Good!${NONE}";
fi
clear
echo -e "${UNDERLINE}${BOLD}Blockcore Node Installation Guide${NONE}"
echo
read -p "Which Fork (redstone, x42, impleum, city, strax, xds, x1, solaris, amsterdamcoin)? " fork
read -p "Mainnet (m) or Testnet (t)? " net
read -p "Which branch (default=master)? " branch

if [ "${branch}" == "" ]; then 
branch="master";
fi

read -p "What version of dotnet is required - if you want to specify a downgrade here's an example \"3.1=3.1.102-1\" (default=3.1)? " dotnetver
if [ "${dotnetver}" = "" ]; then 
dotnetver="3.1";
fi

# =================== YOUR DATA ========================
DNS_NAME="$fork.trustaking.com"
USER="$fork-web"
COINSERVICEINSTALLER="https://raw.githubusercontent.com/trustaking/server/master/install-coin.sh"
COINSERVICECONFIG="https://raw.githubusercontent.com/trustaking/server/master/config/config-$fork.sh"
WEBFILE="https://github.com/trustaking/node.git"

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
~/install-coin.sh -f ${fork} -n ${net} -b ${branch} -d ${dotnetver}

# Display information
echo
echo -e "Re-install Complete!"