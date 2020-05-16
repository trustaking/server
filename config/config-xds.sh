function setMainVars() {
## set network dependent variables
NETWORK=""
NODE_USER=${FORK}${NETWORK}
COINPORT=38333
COINRPCPORT=48333
COINAPIPORT=48334
}

function setTestVars() {
## set network dependent variables
NETWORK="-testnet"
NODE_USER=${FORK}${NETWORK}
COINPORT=38333
COINRPCPORT=48333
COINAPIPORT=48334
}

function setGeneralVars() {
## set general variables
COINRUNCMD="dotnet blockcore.xdsd.dll ${NETWORK} -agentprefix="trustaking" -datadir=/home/${NODE_USER}/.blockcore -maxblkmem=2 -EnforceStakingFlag=1 \${stakeparams} \${rpcparams}"
#COINGITHUB=https://github.com/sonofsatoshi2020/xds.git
COINGITHUB=https://github.com/block-core/blockcore-nodes.git
COINDSRC=/home/${NODE_USER}/code/XDS/src/XdsD
CONF=release
COINDAEMON=${FORK}d
COINCONFIG=${FORK}.conf
COINSTARTUP=/home/${NODE_USER}/${FORK}d
COINDLOC=/home/${NODE_USER}/${FORK}node
COINSERVICELOC=/etc/systemd/system/
COINSERVICENAME=${COINDAEMON}@${NODE_USER}
SWAPSIZE="1024" ## =1GB
}