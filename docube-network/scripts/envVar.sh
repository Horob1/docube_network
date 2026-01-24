#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Environment variables for Docube Network

DOCUBE_NETWORK_HOME=${DOCUBE_NETWORK_HOME:-${PWD}}
. ${DOCUBE_NETWORK_HOME}/scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${DOCUBE_NETWORK_HOME}/organizations/ordererOrganizations/docube.com/tlsca/tlsca.docube.com-cert.pem
export PEER0_ADMINORG_CA=${DOCUBE_NETWORK_HOME}/organizations/peerOrganizations/adminorg.docube.com/tlsca/tlsca.adminorg.docube.com-cert.pem
export PEER0_USERORG_CA=${DOCUBE_NETWORK_HOME}/organizations/peerOrganizations/userorg.docube.com/tlsca/tlsca.userorg.docube.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${DOCUBE_NETWORK_HOME}/organizations/ordererOrganizations/docube.com/orderers/orderer.docube.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${DOCUBE_NETWORK_HOME}/organizations/ordererOrganizations/docube.com/orderers/orderer.docube.com/tls/server.key

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  
  if [ "$USING_ORG" == "adminorg" ] || [ "$USING_ORG" == "1" ]; then
    export CORE_PEER_LOCALMSPID=AdminOrgMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ADMINORG_CA
    export CORE_PEER_MSPCONFIGPATH=${DOCUBE_NETWORK_HOME}/organizations/peerOrganizations/adminorg.docube.com/users/Admin@adminorg.docube.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ "$USING_ORG" == "userorg" ] || [ "$USING_ORG" == "2" ]; then
    export CORE_PEER_LOCALMSPID=UserOrgMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_USERORG_CA
    export CORE_PEER_MSPCONFIGPATH=${DOCUBE_NETWORK_HOME}/organizations/peerOrganizations/userorg.docube.com/users/Admin@userorg.docube.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" = "true" ]; then
    env | grep CORE
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    if [ "$1" == "adminorg" ] || [ "$1" == "1" ]; then
      PEER="peer0.adminorg"
    elif [ "$1" == "userorg" ] || [ "$1" == "2" ]; then
      PEER="peer0.userorg"
    fi
    ## Set peer addresses
    if [ -z "$PEERS" ]; then
      PEERS="$PEER"
    else
      PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    if [ "$1" == "adminorg" ] || [ "$1" == "1" ]; then
      TLSINFO=(--tlsRootCertFiles "${PEER0_ADMINORG_CA}")
    elif [ "$1" == "userorg" ] || [ "$1" == "2" ]; then
      TLSINFO=(--tlsRootCertFiles "${PEER0_USERORG_CA}")
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
