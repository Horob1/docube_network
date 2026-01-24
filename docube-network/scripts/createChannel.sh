#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Create channel for Docube Network

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"

: ${CHANNEL_NAME:="docubechannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

# Import scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. ${SCRIPT_DIR}/envVar.sh

FABRIC_CFG_PATH=${PWD}/configtx

if [ ! -d "channel-artifacts" ]; then
  mkdir channel-artifacts
fi

createChannelGenesisBlock() {
  setGlobals adminorg
  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatalln "configtxgen tool not found."
  fi
  
  infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
  set -x
  configtxgen -profile DocubeChannel -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    fatalln "Failed to generate channel genesis block..."
  fi
}

createChannel() {
  setGlobals adminorg
  local rc=1
  local COUNTER=1
  infoln "Adding orderer to channel..."
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    set -x
    osnadmin channel join --channelID $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  FABRIC_CFG_PATH=$PWD/../config/
  ORG=$1
  setGlobals $ORG
  local rc=1
  local COUNTER=1
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  verifyResult $res "After $MAX_RETRY attempts, peer0.${ORG} has failed to join channel '$CHANNEL_NAME'"
}

setAnchorPeer() {
  ORG=$1
  ${SCRIPT_DIR}/setAnchorPeer.sh $ORG $CHANNEL_NAME
}

# Main flow
FABRIC_CFG_PATH=${PWD}/configtx

## Create channel genesis block
infoln "Creating channel genesis block..."
createChannelGenesisBlock

FABRIC_CFG_PATH=$PWD/../config/
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel
successln "Channel '$CHANNEL_NAME' created"

## Join AdminOrg peer to the channel
infoln "Joining AdminOrg peer to the channel..."
joinChannel adminorg

## Join UserOrg peer to the channel
infoln "Joining UserOrg peer to the channel..."
joinChannel userorg

## Note: Anchor peers are already defined in configtx.yaml
## No need to update them separately
successln "Channel '$CHANNEL_NAME' joined successfully"
