function setMainVars() {
## set network dependent variables
NETWORK=""
NODE_USER=${FORK}${NETWORK}
COINPORT=17105
COINRPCPORT=17104
COINAPIPORT=17103
}

function setTestVars() {
## set network dependent variables
NETWORK="-testnet"
NODE_USER=${FORK}${NETWORK}
COINPORT=27105
COINRPCPORT=27104
COINAPIPORT=27103
}

function setGeneralVars() {
## set general variables for coin install 
COINRUNCMD="sudo dotnet ./Stratis.StraxD.dll ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.${FORK}node -maxblkmem=2 -minimumsplitcoinvalue=15000000000 -enablecoinstakesplitting=1 \${stakeparams} \${rpcparams}"
COINGITHUB=https://github.com/stratisproject/StratisFullNode.git
COINDSRC=/home/${NODE_USER}/code/src/Stratis.StraxD
# COINRUNCMD="dotnet Blockcore.Node.dll --chain=STRAX ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.blockcore -maxblkmem=2 -minimumsplitcoinvalue=15000000000 -enablecoinstakesplitting=1 -EnforceStakingFlag=1 \${stakeparams} \${rpcparams}"
# COINGITHUB=https://github.com/block-core/blockcore.git
# COINDSRC=/home/${NODE_USER}/code/src/Node/Blockcore.Node/
CONF=release
COINDAEMON=${FORK}d
COINCONFIG=${FORK}.conf
COINSTARTUP=/home/${NODE_USER}/${FORK}d
COINDLOC=/home/${NODE_USER}/${FORK}node
COINSERVICELOC=/etc/systemd/system/
COINSERVICENAME=${COINDAEMON}@${NODE_USER}
SWAPSIZE="1024" ## =1GB
# variables for node website
howtourl="https://www.stratisplatform.com/wp-content/uploads/2020/12/Stratis-Cold-Staking-Guide-v1.0.pdf";
walleturl="https://github.com/stratisproject/StraxUI/releases";
withdrawurl="";
addurl="";
vpsurl="https://github.com/thecrypt0hunter/node-installer";
rewardsurl="https://www.stakingrewards.com/earn/stratis";
segwit="false";
whitelist=0;
payment=0;
exchange=0;
}