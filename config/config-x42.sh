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
#COINRUNCMD="dotnet ./x42.x42D.dll ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.${FORK}node -maxblkmem=2 -EnforceStakingFlag=1 -txindex \${stakeparams} \${rpcparams} -addnode=52.211.235.48:52342 -addnode=18.179.72.204:52342 -addnode=63.32.82.169:52342 -addnode=34.255.35.42:52342"
#COINGITHUB=https://github.com/x42protocol/x42-BlockCore.git
#COINGITHUB=https://github.com/x42-Archive/X42-FullNode
COINRUNCMD="dotnet ./x42.Node.dll ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.blockcore -maxblkmem=2 \${stakeparams} \${rpcparams}"
COINGITHUB=https://github.com/block-core/blockcore.git
COINDSRC=/home/${NODE_USER}/code/src/Networks/x42/x42.Node
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