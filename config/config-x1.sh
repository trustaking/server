function setMainVars() {
## set network dependent variables
NETWORK=""
NODE_USER=${FORK}${NETWORK}
COINPORT=23333
COINRPCPORT=48333
COINAPIPORT=48334
}

function setTestVars() {
## set network dependent variables
NETWORK="-testnet"
NODE_USER=${FORK}${NETWORK}
COINPORT=38334
COINRPCPORT=48334
COINAPIPORT=48335
}

function setGeneralVars() {
## set general variables
COINRUNCMD="dotnet x1d.dll ${NETWORK} -agentprefix="trustaking" -datadir=/home/${NODE_USER}/.blockcore -maxblkmem=2 -EnforceStakingFlag=1 \${stakeparams} \${rpcparams}"
COINGITHUB=https://github.com/x1crypto/x1-blockcore.git
COINDSRC=/home/${NODE_USER}/code/src/X1/X1Daemon
CONF=release
COINDAEMON=${FORK}d
COINCONFIG=${FORK}.conf
COINSTARTUP=/home/${NODE_USER}/${FORK}d
COINDLOC=/home/${NODE_USER}/${FORK}node
COINSERVICELOC=/etc/systemd/system/
COINSERVICENAME=${COINDAEMON}@${NODE_USER}
SWAPSIZE="1024" ## =1GB
# variables for node website
howtourl="how-to.php#trustaking";
withdrawurl="how-to.php#withdraw";
addurl="how-to.php#add-more";
howtovpsurl="how-to.php#vps";
walleturl="https://github.com/x1crypto/x1-core-wallet.git";
vpsurl="";
segwit="true";
whitelist=1;
payment=1;
exchange=0;
}