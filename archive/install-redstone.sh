#!/bin/bash
NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'

OS_VER="Ubuntu*"
ARCH="linux-x64"
DATE_STAMP="$(date +%y-%m-%d-%s)"
SCRIPT_LOGFILE="/tmp/${NODE_USER}_${DATE_STAMP}_output.log"
NODE_IP=$(curl --silent ipinfo.io/ip)

function setMainVars() {
## set network dependent variables
NETWORK=""
NODE_USER=redstone${NETWORK}
COINCORE=/home/${NODE_USER}/.redstonenode/redstone/RedstoneMain
COINPORT=19056
COINRPCPORT=19057
COINAPIPORT=37222
DNSPORT=53
}

function setTestVars() {
## set network dependent variables
NETWORK="-testnet"
NODE_USER=redstone${NETWORK}
COINCORE=/home/${NODE_USER}/.redstonenode/redstone/RedstoneTest
COINPORT=19156
COINRPCPORT=19157
COINAPIPORT=38222
DNSPORT=53
}

function setDNSVars() {
## set DNS specific variables
if [ "${NETWORK}" = "" ] ; then
   DNS="-iprangefiltering=0 -externalip=${NODE_IP} -dnshostname=seed.redstonecoin.com -dnsnameserver=dns1.seed.redstonecoin.com -dnsmailbox=admin@redstoneplatform.com -dnsfullnode=1 -dnslistenport=${DNSPORT}"
 else
   DNS="-iprangefiltering=0 -externalip=${NODE_IP} -dnshostname=seed.redstoneplatform.com -dnsnameserver=testdns1.seed.redstoneplatform.com -dnsmailbox=admin@redstoneplatform.com -dnsfullnode=1 -dnslistenport=${DNSPORT}"
fi
## Stop port 53 from being used by systemd-resovled
echo 'DNSStubListener=no' | sudo tee -a /etc/systemd/resolved.conf &>> ${SCRIPT_LOGFILE}
sudo service systemd-resolved restart
}

function setGeneralVars() {
## set general variables

COINRUNCMD="sudo dotnet ./Redstone.RedstoneFullNodeD.dll ${NETWORK} -datadir=/home/${NODE_USER}/.redstonenode -iprangefiltering=0 ${DNS}"  ## additional commands can be used here e.g. -testnet or -stake=1
CONF=release
#COINGITHUB=https://github.com/RedstonePlatform/Redstone.git
COINGITHUB=https://github.com/spartacrypt/RedstoneServiceNode.git
COINDAEMON=redstoned
COINCONFIG=redstone.conf
COINSTARTUP=/home/${NODE_USER}/redstoned
COINDLOC=/home/${NODE_USER}/RedstoneNode
COINDSRC=/home/${NODE_USER}/code/src/Redstone/Programs/Redstone.RedstoneFullNodeD
COINSERVICELOC=/etc/systemd/system/
COINSERVICENAME=${COINDAEMON}@${NODE_USER}
SWAPSIZE="1024" ## =1GB
}

function check_root() {
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}* Sorry, this script needs to be run as root. Do \"sudo su root\" and then re-run this script${NONE}"
    exit 1
    echo -e "${NONE}${GREEN}* All Good!${NONE}";
fi
}

function create_user() {
    echo
    echo "* Checking for user & add if required. Please wait..."
    # our new mnode unpriv user acc is added
    if id "${NODE_USER}" >/dev/null 2>&1; then
        echo "user exists already, do nothing"
    else
        echo -e "${NONE}${GREEN}* Adding new system user ${NODE_USER}${NONE}"
        sudo adduser --disabled-password --gecos "" ${NODE_USER} &>> ${SCRIPT_LOGFILE}
        sudo echo -e "${NODE_USER} ALL=(ALL) NOPASSWD:ALL" &>> /etc/sudoers.d/90-cloud-init-users
    fi
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

function set_permissions() {
    chown -R ${NODE_USER}:${NODE_USER} ${COINCORE} ${COINSTARTUP} ${COINDLOC} &>> ${SCRIPT_LOGFILE}
    # make group permissions same as user, so vps-user can be added to node group
    chmod -R g=u ${COINCORE} ${COINSTARTUP} ${COINDLOC} ${COINSERVICELOC} &>> ${SCRIPT_LOGFILE}
}

checkOSVersion() {
   echo
   echo "* Checking OS version..."
    if [[ `cat /etc/issue.net`  == ${OS_VER} ]]; then
        echo -e "${GREEN}* You are running `cat /etc/issue.net` . Setup will continue.${NONE}";
    else
        echo -e "${RED}* You are not running ${OS_VER}. You are running `cat /etc/issue.net` ${NONE}";
        echo && echo "Installation cancelled" && echo;
        exit;
    fi
}

updateAndUpgrade() {
    echo
    echo "* Running update and upgrade. Please wait..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq -y &>> ${SCRIPT_LOGFILE}
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq &>> ${SCRIPT_LOGFILE}
    sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -qq &>> ${SCRIPT_LOGFILE}
    echo -e "${GREEN}* Done${NONE}";
}

setupSwap() {
#check if swap is available
    echo
    echo "* Creating Swap File. Please wait..."
    if [ $(free | awk '/^Swap:/ {exit !$2}') ] || [ ! -f "/var/mnode_swap.img" ];then
    echo -e "${GREEN}* No proper swap, creating it.${NONE}";
    # needed because ant servers are ants
    sudo rm -f /var/mnode_swap.img &>> ${SCRIPT_LOGFILE}
    sudo dd if=/dev/zero of=/var/mnode_swap.img bs=1024k count=${SWAPSIZE} &>> ${SCRIPT_LOGFILE}
    sudo chmod 0600 /var/mnode_swap.img &>> ${SCRIPT_LOGFILE}
    sudo mkswap /var/mnode_swap.img &>> ${SCRIPT_LOGFILE}
    sudo swapon /var/mnode_swap.img &>> ${SCRIPT_LOGFILE}
    echo '/var/mnode_swap.img none swap sw 0 0' | sudo tee -a /etc/fstab &>> ${SCRIPT_LOGFILE}
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
else
    echo -e "${GREEN}* All good, we have a swap.${NONE}";
fi
}

installFail2Ban() {
    echo
    echo -e "* Installing fail2ban. Please wait..."
    sudo apt-get -y install fail2ban &>> ${SCRIPT_LOGFILE}
    sudo systemctl enable fail2ban &>> ${SCRIPT_LOGFILE}
    sudo systemctl start fail2ban &>> ${SCRIPT_LOGFILE}
    # Add Fail2Ban memory hack if needed
    if ! grep -q "ulimit -s 256" /etc/default/fail2ban; then
       echo "ulimit -s 256" | sudo tee -a /etc/default/fail2ban &>> ${SCRIPT_LOGFILE}
       sudo systemctl restart fail2ban &>> ${SCRIPT_LOGFILE}
    fi
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

installFirewall() {
    echo
    echo -e "* Installing UFW. Please wait..."
    sudo apt-get -y install ufw &>> ${SCRIPT_LOGFILE}
    sudo ufw allow OpenSSH &>> ${SCRIPT_LOGFILE}
    sudo ufw allow $COINPORT/tcp &>> ${SCRIPT_LOGFILE}
    sudo ufw allow $COINRPCPORT/tcp &>> ${SCRIPT_LOGFILE}
    if [ "${DNSPORT}" != "" ] ; then
        sudo ufw allow ${DNSPORT}/tcp &>> ${SCRIPT_LOGFILE}
        sudo ufw allow ${DNSPORT}/udp &>> ${SCRIPT_LOGFILE}
    fi
    echo "y" | sudo ufw enable &>> ${SCRIPT_LOGFILE}
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

installDependencies() {
    echo
    echo -e "* Installing dependencies. Please wait..."
    sudo timedatectl set-ntp no &>> ${SCRIPT_LOGFILE}
    sudo apt-get install git ntp nano wget curl software-properties-common -y &>> ${SCRIPT_LOGFILE}
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        if [[ "${VERSION_ID}" = "16.04" ]]; then
            wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb &>> ${SCRIPT_LOGFILE}
            sudo dpkg -i packages-microsoft-prod.deb &>> ${SCRIPT_LOGFILE}
            sudo apt-get install apt-transport-https -y &>> ${SCRIPT_LOGFILE}
            sudo apt-get update -y &>> ${SCRIPT_LOGFILE}
            sudo apt-get install dotnet-sdk-2.2 -y &>> ${SCRIPT_LOGFILE}
            echo -e "${NONE}${GREEN}* Done${NONE}";
        fi
        if [[ "${VERSION_ID}" = "18.04" ]]; then
            wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb &>> ${SCRIPT_LOGFILE}
            sudo dpkg -i packages-microsoft-prod.deb &>> ${SCRIPT_LOGFILE}
            sudo add-apt-repository universe -y &>> ${SCRIPT_LOGFILE}
            sudo apt-get install apt-transport-https -y &>> ${SCRIPT_LOGFILE}
            sudo apt-get update -y &>> ${SCRIPT_LOGFILE}
            sudo apt-get install dotnet-sdk-2.2 -y &>> ${SCRIPT_LOGFILE}
            echo -e "${NONE}${GREEN}* Done${NONE}";
        fi
        else
        echo -e "${NONE}${RED}* Version: ${VERSION_ID} not supported.${NONE}";
    fi
}

compileWallet() {
    echo
    echo -e "* Compiling wallet. Please wait, this might take a while to complete..."
    cd /home/${NODE_USER}/
    git clone ${COINGITHUB} code &>> ${SCRIPT_LOGFILE}
    cd /home/${NODE_USER}/code
    git submodule update --init --recursive &>> ${SCRIPT_LOGFILE}
    cd ${COINDSRC}
    dotnet publish -c ${CONF} -r ${ARCH} -v m -o ${COINDLOC} &>> ${SCRIPT_LOGFILE}	   ### compile & publish code
    rm -rf /home/${NODE_USER}/code &>> ${SCRIPT_LOGFILE} 	   ### Remove source
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

installWallet() {
    echo
    echo -e "* Installing wallet. Please wait..."
    cd /home/${NODE_USER}/
    echo -e "#!/bin/bash\nexport DOTNET_CLI_TELEMETRY_OPTOUT=1\ncd $COINDLOC\n$COINRUNCMD" > ${COINSTARTUP}
    echo -e "[Unit]\nDescription=${COINDAEMON}\nAfter=network-online.target\n\n[Service]\nType=simple\nUser=${NODE_USER}\nGroup=${NODE_USER}\nExecStart=${COINSTARTUP}\nRestart=always\nRestartSec=5\nPrivateTmp=true\nTimeoutStopSec=60s\nTimeoutStartSec=5s\nStartLimitInterval=120s\nStartLimitBurst=15\n\n[Install]\nWantedBy=multi-user.target" >${COINSERVICENAME}.service
    chown -R ${NODE_USER}:${NODE_USER} ${COINSERVICELOC} &>> ${SCRIPT_LOGFILE}
    sudo mv $COINSERVICENAME.service ${COINSERVICELOC} &>> ${SCRIPT_LOGFILE}
    sudo chmod 777 ${COINSTARTUP} &>> ${SCRIPT_LOGFILE}
    sudo systemctl --system daemon-reload &>> ${SCRIPT_LOGFILE}
    sudo systemctl enable ${COINSERVICENAME} &>> ${SCRIPT_LOGFILE}
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

configureWallet() {
    echo
    echo -e "* Configuring wallet. Please wait..."
    cd /home/${NODE_USER}/
    rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    rpcpass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    sudo mkdir -p $COINCORE
    echo -e "externalip=${NODE_IP}\ntxindex=1\nlisten=1\ndaemon=1\nmaxconnections=64" > $COINCONFIG
    sudo mv $COINCONFIG $COINCORE
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

startWallet() {
    echo
    echo -e "* Starting wallet daemon...${COINSERVICENAME}"
    sudo service ${COINSERVICENAME} start &>> ${SCRIPT_LOGFILE}
    sleep 2
    echo -e "${GREEN}* Done${NONE}";
}
stopWallet() {
    echo
    echo -e "* Stopping wallet daemon...${COINSERVICENAME}"
    sudo service ${COINSERVICENAME} stop &>> ${SCRIPT_LOGFILE}
    sleep 2
    echo -e "${GREEN}* Done${NONE}";
}

function installUnattendedUpgrades() {
    echo
    echo "* Installing Unattended Upgrades..."
    sudo apt install unattended-upgrades -y &>> ${SCRIPT_LOGFILE}
    sleep 3
    sudo sh -c 'echo "Unattended-Upgrade::Allowed-Origins {" >> /etc/apt/apt.conf.d/50unattended-upgrades'
    sudo sh -c 'echo "        "${distro_id}:${distro_codename}";" >> /etc/apt/apt.conf.d/50unattended-upgrades'
    sudo sh -c 'echo "        "${distro_id}:${distro_codename}-security";" >> /etc/apt/apt.conf.d/50unattended-upgrades'
    sudo sh -c 'echo "APT::Periodic::AutocleanInterval "7";" >> /etc/apt/apt.conf.d/20auto-upgrades'
    sudo sh -c 'echo "APT::Periodic::Unattended-Upgrade "1";" >> /etc/apt/apt.conf.d/20auto-upgrades'
    cat /etc/apt/apt.conf.d/20auto-upgrades &>> ${SCRIPT_LOGFILE}
    echo -e "${GREEN}* Done${NONE}";
}

displayServiceStatus() {
	echo
	echo
	on="${GREEN}ACTIVE${NONE}"
	off="${RED}OFFLINE${NONE}"

	if systemctl is-active --quiet ${COINSERVICENAME}; then echo -e "Service: ${on}"; else echo -e "Service: ${off}"; fi
}

clear
cd
echo && echo
echo -e ${RED}
echo -e "${RED}██████╗ ███████╗██████╗ ███████╗████████╗ ██████╗ ███╗   ██╗███████╗${NONE}"  
echo -e "${RED}██╔══██╗██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗████╗  ██║██╔════╝${NONE}"    
echo -e "${RED}██████╔╝█████╗  ██║  ██║███████╗   ██║   ██║   ██║██╔██╗ ██║█████╗  ${NONE}"    
echo -e "${RED}██╔══██╗██╔══╝  ██║  ██║╚════██║   ██║   ██║   ██║██║╚██╗██║██╔══╝  ${NONE}"    
echo -e "${RED}██║  ██║███████╗██████╔╝███████║   ██║   ╚██████╔╝██║ ╚████║███████╗${NONE}"    
echo -e "${RED}╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚══════╝${NONE}"  
echo -e ${RED}
echo -e "${PURPLE}**********************************************************************${NONE}"
echo -e "${PURPLE}*    This script will install and configure your Redstone node.      *${NONE}"
echo -e "${PURPLE}**********************************************************************${NONE}"
echo -e "${BOLD}"

    check_root

echo -e "${BOLD}"
read -p " Do you want to setup on Mainnet (m), Testnet (t) or upgrade (u) your Redstone node. (m/t/u)?" response

if [[ "$response" =~ ^([mM])+$ ]]; then
    setMainVars
    read -p " Do you want to setup your Redstone node as a DNS Server (y/n)?" response
    echo -e "${NONE}"
    if [[ "$response" =~ ^([yY])+$ ]]; then
        setDNSVars
    fi
    setGeneralVars
    echo -e "${BOLD} The log file can be monitored here: ${SCRIPT_LOGFILE}${NONE}"
    echo -e "${BOLD}"
    checkOSVersion
    updateAndUpgrade
    create_user
    setupSwap
    installFail2Ban
    installFirewall
    installDependencies
    compileWallet
    installWallet
    #configureWallet ### commented out so uses the default configuration
    installUnattendedUpgrades
    startWallet
    set_permissions
    displayServiceStatus

echo
echo -e "${GREEN} Installation complete. Check service with: journalctl -f -u ${COINSERVICENAME} ${NONE}"
echo -e "${GREEN} thecrypt0hunter(2019)${NONE}"

 else
    if [[ "$response" =~ ^([tT])+$ ]]; then
        setTestVars
        read -p " Do you want to setup your Redstone node as a DNS Server (y/n)?" response
        echo -e "${NONE}"
        if [[ "$response" =~ ^([yY])+$ ]]; then
           setDNSVars
        fi
        setGeneralVars
        echo -e "${BOLD} The log file can be monitored here: ${SCRIPT_LOGFILE}${NONE}"
        echo -e "${BOLD}"
        checkOSVersion
        updateAndUpgrade
        create_user
        setupSwap
        installFail2Ban
        installFirewall
        installDependencies
        compileWallet
        installWallet
        #configureWallet ### commented out so uses the default configuration
        installUnattendedUpgrades
        startWallet
        set_permissions
        displayServiceStatus
	
echo
echo -e "${GREEN} Installation complete. Check service with: journalctl -f -u ${COINSERVICENAME} ${NONE}"
echo -e "${GREEN} thecrypt0hunter(2019)${NONE}"
 else
    if [[ "$response" =~ ^([uU])+$ ]]; then
        check_root
        ##TODO: Test for servicefile and only upgrade as required 
        #Stop Test Service
        setTestVars
        setGeneralVars
        stopWallet
	    updateAndUpgrade
        compileWallet
        #Stop Main Service
        setMainVars
        setGeneralVars
        stopWallet
        compileWallet
        #Start Test Service
        setTestVars
        setGeneralVars
        startWallet
        #Start Main Service
        setMainVars
        setGeneralVars
        startWallet
        echo -e "${GREEN} thecrypt0hunter 2019${NONE}"
    else
      echo && echo -e "${RED} Installation cancelled! ${NONE}" && echo
    fi
  fi
fi
    cd ~
