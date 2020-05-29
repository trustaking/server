function setMainVars() {
## set network dependent variables
NETWORK=""
NODE_USER=${FORK}${NETWORK}
COINPORT=4333
COINRPCPORT=4334
COINAPIPORT=4335
}

function setTestVars() {
## set network dependent variables
NETWORK="-testnet"
NODE_USER=${FORK}${NETWORK}
COINPORT=24333
COINRPCPORT=24334
COINAPIPORT=24335
}

function setGeneralVars() {
## set general variables
#COINRUNCMD="dotnet ./City.Chain.dll ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.${FORK}chain -maxblkmem=2 -txindex=1 \${stakeparams} \${rpcparams}"
#COINGITHUB=https://github.com/CityChainFoundation/city-chain.git
#COINDSRC=/home/${NODE_USER}/code/src/City.Chain
COINRUNCMD="dotnet ./City.Node.dll ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.blockcore -maxblkmem=2 \${stakeparams} \${rpcparams}"
COINGITHUB=https://github.com/block-core/blockcore.git
COINDSRC=/home/${NODE_USER}/code/src/Networks/City/City.Node
CONF=release
COINDAEMON=${FORK}d
COINCONFIG=${FORK}.conf
COINSTARTUP=/home/${NODE_USER}/${FORK}d
COINDLOC=/home/${NODE_USER}/${FORK}node
COINSERVICELOC=/etc/systemd/system/
COINSERVICENAME=${COINDAEMON}@${NODE_USER}
SWAPSIZE="1024" ## =1GB
}