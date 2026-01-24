#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Config Update utilities for Docube Network

DOCUBE_NETWORK_HOME=${DOCUBE_NETWORK_HOME:-${PWD}}
. ${DOCUBE_NETWORK_HOME}/scripts/envVar.sh

# fetchChannelConfig <org> <channel_id> <output_json>
fetchChannelConfig() {
  ORG=$1
  CHANNEL=$2
  OUTPUT=$3

  setGlobals $ORG

  infoln "Fetching the most recent configuration block for the channel"
  set -x
  peer channel fetch config ${DOCUBE_NETWORK_HOME}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.docube.com -c $CHANNEL --tls --cafile "$ORDERER_CA"
  { set +x; } 2>/dev/null

  infoln "Decoding config block to JSON and isolating config to ${OUTPUT}"
  set -x
  configtxlator proto_decode --input ${DOCUBE_NETWORK_HOME}/channel-artifacts/config_block.pb --type common.Block --output ${DOCUBE_NETWORK_HOME}/channel-artifacts/config_block.json
  jq .data.data[0].payload.data.config ${DOCUBE_NETWORK_HOME}/channel-artifacts/config_block.json >"${OUTPUT}"
  res=$?
  { set +x; } 2>/dev/null
  verifyResult $res "Failed to parse channel configuration, make sure you have jq installed"
}

# createConfigUpdate <channel_id> <original_config.json> <modified_config.json> <output.pb>
createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config --output ${DOCUBE_NETWORK_HOME}/channel-artifacts/original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config --output ${DOCUBE_NETWORK_HOME}/channel-artifacts/modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original ${DOCUBE_NETWORK_HOME}/channel-artifacts/original_config.pb --updated ${DOCUBE_NETWORK_HOME}/channel-artifacts/modified_config.pb --output ${DOCUBE_NETWORK_HOME}/channel-artifacts/config_update.pb
  configtxlator proto_decode --input ${DOCUBE_NETWORK_HOME}/channel-artifacts/config_update.pb --type common.ConfigUpdate --output ${DOCUBE_NETWORK_HOME}/channel-artifacts/config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat ${DOCUBE_NETWORK_HOME}/channel-artifacts/config_update.json)'}}}' | jq . > ${DOCUBE_NETWORK_HOME}/channel-artifacts/config_update_in_envelope.json
  configtxlator proto_encode --input ${DOCUBE_NETWORK_HOME}/channel-artifacts/config_update_in_envelope.json --type common.Envelope --output "${OUTPUT}"
  { set +x; } 2>/dev/null
}

# signConfigtxAsPeerOrg <org> <configtx.pb>
signConfigtxAsPeerOrg() {
  ORG=$1
  CONFIGTXFILE=$2
  setGlobals $ORG
  set -x
  peer channel signconfigtx -f "${CONFIGTXFILE}"
  { set +x; } 2>/dev/null
}
