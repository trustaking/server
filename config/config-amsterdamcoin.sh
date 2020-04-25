function setMainVars() {
## set network dependent variables
NETWORK=""
NODE_USER=${FORK}${NETWORK}
#COINCORE=/home/${NODE_USER}/.${FORK}node/${FORK}node/AmsterdamCoinMain
COINCORE=/home/${NODE_USER}/.blockcore/ams/AMSMain
COINPORT=50000
COINRPCPORT=51000
COINAPIPORT=63000
}

function setTestVars() {
## set network dependent variables
NETWORK="-testnet"
NODE_USER=${FORK}${NETWORK}
#COINCORE=/home/${NODE_USER}/.${FORK}node/${FORK}/AmsterdamCoinTest
COINCORE=/home/${NODE_USER}/.blockcore/ams/AMSTest
COINPORT=50009
COINRPCPORT=51009
COINAPIPORT=63009
}

function setGeneralVars() {
## set general variables
#COINRUNCMD="sudo Stratis.AmsterdamCoinD ${NETWORK} -agentprefix="trustaking" -datadir=/home/${NODE_USER}/.${FORK}node -maxblkmem=2 -EnforceStakingFlag=1 \${stakeparams} \${rpcparams}"
#COINGITHUB=https://github.com/AmsterdamCoin/AmsterdamCoinBitcoinFullNode.git
#COINDSRC=/home/${NODE_USER}/code/src/Stratis.AmsterdamCoinD
COINRUNCMD="sudo dotnet ./AMS.Node.dll ${NETWORK} -agentprefix=trustaking -datadir=/home/${NODE_USER}/.blockcore -maxblkmem=2 \${stakeparams} \${rpcparams}"
COINGITHUB=https://github.com/block-core/blockcore-nodes.git
COINDSRC=/home/${NODE_USER}/code/AMS/src/AMS.Node
CONF=release
COINDAEMON=${FORK}d
COINCONFIG=${FORK}.conf
COINSTARTUP=/home/${NODE_USER}/${FORK}d
COINDLOC=/home/${NODE_USER}/${FORK}node
COINSERVICELOC=/etc/systemd/system/
COINSERVICENAME=${COINDAEMON}@${NODE_USER}
SWAPSIZE="1024" ## =1GB
}