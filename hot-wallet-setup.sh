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

##### Define Variables ######
source <(curl -s http://redstone.trustaking.com/include/config.sh)
date_stamp="$(date +%y-%m-%d-%s)"
logfile="/tmp/log_$date_stamp_output.log"
HotWalletName="hot-wallet"
HotWalletSecretWords=""
HotWalletPassword=""
HotWalletPassphrase=""
HotWalletInitialFundingAddress=""
HotWalletColdStakingHotAddress=""
ColdWalletColdStakingColdAddress=""
ColdStakingAmount=""
ColdStakingTX=""

######## Get some information from the user about the wallet ############
clear
echo -e "${RED}${BOLD}#############################################################################${NONE}"
echo -e "${RED}${BOLD}##################### REMOTE WALLET - COLD STAKING SETUP ####################${NONE}"
echo -e "${RED}${BOLD}#############################################################################${NONE}"
echo
echo -e "Please enter some details about your Hot wallet (that will used for staking)"
echo 
read -p "Name (default=hot-wallet):" response
if [[ "$response" != "" ]] ; then 
   HotWalletName="$response" 
fi
read -p "Password:" response
HotWalletPassword="$response"
read -p "Passphrase:" response
HotWalletPassphrase="$response"
echo 

##### Setup the hot wallet ########

echo -e "*Creating your Hot wallet ... please wait."

### grab a 12 word mneumonic

HotWalletSecretWords=$(sed -e 's/^"//' -e 's/"$//' <<<$(curl -sX GET "http://localhost:$apiport/api/Wallet/mnemonic?language=english&wordCount=12" -H "accept: application/json")) 

curl -sX POST "http://localhost:$apiport/api/Wallet/recover" -H  "accept: application/json" -H  "Content-Type: application/json-patch+json" -d "{  \"mnemonic\": \"$HotWalletSecretWords\",  \"password\": \"$HotWalletPassword\",  \"passphrase\": \"$HotWalletPassphrase\",  \"name\": \"$HotWalletName\",  \"creationDate\": \"2019-01-01T07:33:09.051Z\"}" &>> ${logfile}

echo -e "${GREEN}Done.${NONE}"
echo

##### Convert the hot wallet to a cold staking wallet ######

echo -e "* Preparing your Hot wallet for cold staking   ... please wait."

curl -sX POST "http://localhost:$apiport/api/ColdStaking/cold-staking-account" -H  "accept: application/json" -H  "Content-Type: application/json-patch+json" -d "{  \"walletName\": \"$HotWalletName\",  \"walletPassword\": \"$HotWalletPassword\",  \"isColdWalletAccount\": false}" &>> ${logfile}

echo -e "${GREEN}Done.${NONE}"
echo

##### Get the Hot Wallet - Hot Address ######

echo -e "* Fetching your Hot wallet details for cold staking   ... please wait."

HotWalletColdStakingHotAddress=$(curl -sX GET "http://localhost:$apiport/api/ColdStaking/cold-staking-address?WalletName=$HotWalletName&IsColdWalletAddress=false" -H  "accept: application/json")

HotWalletColdStakingHotAddress=${HotWalletColdStakingHotAddress:12:34}

#HotWalletColdStakingHotAddress=$(sed -e 's/^"//' -e 's/"$//' <<<$(curl -sX GET "http://localhost:$apiport/api/Wallet/unusedaddress?WalletName=$HotWalletName&AccountName=coldStakingHotAddresses" -H  "accept: application/json"))

echo -e "${GREEN}Done.${NONE}"
echo

##### Start staking on the Hot Wallet ######

echo -e "* Preparing to start cold staking on your Hot wallet   ... please wait."

curl -sX POST "http://localhost:$apiport/api/Staking/startstaking" -H  "accept: application/json" -H  "Content-Type: application/json-patch+json" -d "{  \"password\": \"$HotWalletPassword\",  \"name\": \"$HotWalletName\"}" &>> ${logfile}

curl -X GET "http://localhost:$apiport/api/Staking/getstakinginfo" -H  "accept: application/json" &>> ${logfile}

echo -e "${GREEN}Done.${NONE}"
echo
echo -e "Here's all the Hot wallet details - keep this information safe offline:"
echo
echo -e "Name      	:" $HotWalletName
echo -e "Password  	:" $HotWalletPassword
echo -e "Passphrase	:" $HotWalletPassphrase
echo -e "Mnemonic  	:" $HotWalletSecretWords
echo -e "Hot address     :${RED}" $HotWalletColdStakingHotAddress
echo -e "${NONE}"
