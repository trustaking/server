function setMainVars() {
## set network dependent variables
NETWORK=""
NODE_USER=${FORK}${NETWORK}
COINPORT=52342
COINRPCPORT=52343
COINAPIPORT=42220
}

function setTestVars() {
## set network dependent variables
NETWORK="-testnet"
NODE_USER=${FORK}${NETWORK}
COINPORT=62342
COINRPCPORT=62343
COINAPIPORT=42221
}

function setGeneralVars() {
## set general variables
COINRUNCMD="dotnet Blockcore.Node.dll --chain=X42 ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.blockcore -maxblkmem=2 -minimumsplitcoinvalue=15000000000 -enablecoinstakesplitting=1 -EnforceStakingFlag=1 \${stakeparams} \${rpcparams}"
COINGITHUB=https://github.com/block-core/blockcore.git
COINDSRC=/home/${NODE_USER}/code/src/Node/Blockcore.Node/
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
walleturl="https://github.com/thecrypt0hunter/CoreWallet/releases";
vpsurl="https://github.com/thecrypt0hunter/node-installer";
segwit="false";
whitelist=1;
payment=1;
exchange=0;
}