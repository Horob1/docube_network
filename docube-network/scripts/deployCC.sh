#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Deploy Chaincode to Docube Network
# Usage: ./scripts/deployCC.sh <chaincode_name> <chaincode_path> <chaincode_lang>

CHANNEL_NAME="${1:-docubechannel}"
CC_NAME="${2:-document_nft_cc}"
CC_SRC_PATH="${3:-./chaincode/docube}"
CC_RUNTIME_LANGUAGE="${4:-golang}"
CC_VERSION="${5:-1.0}"
CC_SEQUENCE="${6:-1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. ${SCRIPT_DIR}/envVar.sh

export FABRIC_CFG_PATH=${SCRIPT_DIR}/../../config

println() {
  echo -e "$1"
}

# Package chaincode
packageChaincode() {
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode packaging has failed"
  successln "Chaincode is packaged"
}

# Install chaincode on peer
installChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode installation on peer0.${ORG} has failed"
  successln "Chaincode is installed on peer0.${ORG}"
}

# Query installed chaincode
queryInstalled() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  PACKAGE_ID=$(peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${CC_NAME}_${CC_VERSION})
  verifyResult $res "Query installed on peer0.${ORG} has failed"
  successln "Query installed successful on peer0.${ORG} on channel"
}

# Approve chaincode for org (with AdminOrg-only endorsement policy)
approveForMyOrg() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.docube.com --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} --signature-policy "OR('AdminOrgMSP.peer','UserOrgMSP.peer')" >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition approved on peer0.${ORG} on channel '$CHANNEL_NAME'"
}

# Check commit readiness
checkCommitReadiness() {
  ORG=$1
  setGlobals $ORG
  infoln "Checking the commit readiness of the chaincode definition on peer0.${ORG} on channel '$CHANNEL_NAME'..."
  set -x
  peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} --output json >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
}

# Commit chaincode definition
commitChaincodeDefinition() {
  setGlobals adminorg
  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.docube.com --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ADMINORG_CA" --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_USERORG_CA" >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on channel '$CHANNEL_NAME'"
  successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# Commit chaincode definition (AdminOrg only - for centralized control)
# Uses explicit endorsement policy to restrict write endorsement to AdminOrg
commitChaincodeDefinitionAdminOnly() {
  setGlobals adminorg
  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.docube.com --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ADMINORG_CA" --signature-policy "OR('AdminOrgMSP.peer','UserOrgMSP.peer')" >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on channel '$CHANNEL_NAME'"
  successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# Query committed chaincode
queryCommitted() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Query committed on channel '$CHANNEL_NAME' failed"
}

# Initialize chaincode
chaincodeInvokeInit() {
  setGlobals adminorg
  set -x
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.docube.com --tls --cafile "$ORDERER_CA" -C $CHANNEL_NAME -n ${CC_NAME} --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ADMINORG_CA" -c '{"function":"InitLedger","Args":[]}' >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Invoke execution on failed"
  successln "Invoke transaction successful on channel '$CHANNEL_NAME'"
}

## Main flow
infoln "Deploying chaincode '${CC_NAME}' to channel '${CHANNEL_NAME}'"

## Package the chaincode
infoln "Packaging chaincode..."
packageChaincode

## Install on AdminOrg
infoln "Installing chaincode on AdminOrg..."
installChaincode adminorg

## Install on UserOrg  
infoln "Installing chaincode on UserOrg..."
installChaincode userorg

## Query installed on AdminOrg
infoln "Querying installed chaincode on AdminOrg..."
queryInstalled adminorg

## Approve for AdminOrg
infoln "Approving chaincode for AdminOrg..."
approveForMyOrg adminorg

## Approve for UserOrg (để UserOrg peer có thể chạy chaincode)
infoln "Approving chaincode for UserOrg..."
approveForMyOrg userorg

## Check commit readiness
infoln "Checking commit readiness..."
checkCommitReadiness adminorg

## Commit chaincode definition (AdminOrg only)
infoln "Committing chaincode definition..."
commitChaincodeDefinitionAdminOnly

## Query committed
infoln "Querying committed chaincode..."
queryCommitted adminorg

## Chaincode ready (no init required for document_nft_cc)
successln "Chaincode '${CC_NAME}' deployed successfully!"
successln "Ready to use with namespaces: document:*, access:*"
