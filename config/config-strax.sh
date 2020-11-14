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
COINRUNCMD="sudo dotnet ./Stratis.StraxD.dll ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.${FORK}node -maxblkmem=2 \${stakeparams} \${rpcparams}"
COINGITHUB=https://github.com/stratisproject/StratisFullNode.git
COINDSRC=/home/${NODE_USER}/code/src/Stratis.StraxD
#COINRUNCMD="dotnet ./StratisD.dll ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.blockcore -maxblkmem=2 \${stakeparams} \${rpcparams}"
#COINGITHUB=https://github.com/block-core/blockcore.git
#COINDSRC=/home/${NODE_USER}/code/src/Networks/Stratis/Stratisd
CONF=release
COINDAEMON=${FORK}d
COINCONFIG=${FORK}.conf
COINSTARTUP=/home/${NODE_USER}/${FORK}d
COINDLOC=/home/${NODE_USER}/${FORK}node
COINSERVICELOC=/etc/systemd/system/
COINSERVICENAME=${COINDAEMON}@${NODE_USER}
SWAPSIZE="1024" ## =1GB
# variables for node website
howtourl="https:/strax.trustaking.com";
segwit="false";
whitelist=1;
payment=0;
exchange=0;
}