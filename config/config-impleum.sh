function setMainVars() {
## set network dependent variables
NETWORK=""
NODE_USER=${FORK}${NETWORK}
COINPORT=16271
COINRPCPORT=16172
COINAPIPORT=38222
}

function setTestVars() {
## set network dependent variables
NETWORK="-testnet"
NODE_USER=${FORK}${NETWORK}
COINPORT=16271
COINRPCPORT=16272
COINAPIPORT=39222
}

function setGeneralVars() {
## set general variables
COINRUNCMD="dotnet Blockcore.Node.dll --chain=IMPLX ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.blockcore -maxblkmem=2 -minimumsplitcoinvalue=15000000000 -enablecoinstakesplitting=1 -EnforceStakingFlag=1 \${stakeparams} \${rpcparams}"
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
howtourl="";
withdrawurl="";
addurl="";
howtovpsurl="";
walleturl="";
vpsurl="";
segwit="false";
whitelist=0;
payment=0;
exchange=0;
}