#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Set Anchor Peer for Docube Network

DOCUBE_NETWORK_HOME=${DOCUBE_NETWORK_HOME:-${PWD}}
. ${DOCUBE_NETWORK_HOME}/scripts/configUpdate.sh

# NOTE: This requires jq and configtxlator for execution.
createAnchorPeerUpdate() {
  infoln "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $ORG $CHANNEL_NAME ${DOCUBE_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}config.json

  infoln "Generating anchor peer update transaction for ${ORG} on channel $CHANNEL_NAME"

  if [ "$ORG" == "adminorg" ] || [ "$ORG" == "1" ]; then
    HOST="peer0.adminorg.docube.com"
    PORT=7051
  elif [ "$ORG" == "userorg" ] || [ "$ORG" == "2" ]; then
    HOST="peer0.userorg.docube.com"
    PORT=9051
  else
    errorln "Org ${ORG} unknown"
    exit 1
  fi

  set -x
  # Modify the configuration to append the anchor peer 
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${DOCUBE_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}config.json > ${DOCUBE_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}modified_config.json
  res=$?
  { set +x; } 2>/dev/null
  verifyResult $res "Channel configuration update for anchor peer failed, make sure you have jq installed"
  
  # Compute a config update, based on the differences between 
  # {orgmsp}config.json and {orgmsp}modified_config.json
  createConfigUpdate ${CHANNEL_NAME} ${DOCUBE_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}config.json ${DOCUBE_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}modified_config.json ${DOCUBE_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.docube.com -c $CHANNEL_NAME -f ${DOCUBE_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}

ORG=$1
CHANNEL_NAME=$2

setGlobals $ORG

createAnchorPeerUpdate 

updateAnchorPeer 
