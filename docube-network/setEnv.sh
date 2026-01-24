#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Docube Network - Environment Setup Script
# Usage: source ./setEnv.sh [adminorg|userorg]

DOCUBE_NETWORK_HOME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Set PATH and FABRIC_CFG_PATH
export PATH=${DOCUBE_NETWORK_HOME}/../bin:$PATH
export FABRIC_CFG_PATH=${DOCUBE_NETWORK_HOME}/../config

# Common TLS settings
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${DOCUBE_NETWORK_HOME}/organizations/ordererOrganizations/docube.com/tlsca/tlsca.docube.com-cert.pem

# Function to set environment for an organization
setOrg() {
  ORG=$1
  
  if [ "$ORG" == "adminorg" ] || [ "$ORG" == "1" ]; then
    echo "Setting environment for AdminOrg..."
    export CORE_PEER_LOCALMSPID="AdminOrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${DOCUBE_NETWORK_HOME}/organizations/peerOrganizations/adminorg.docube.com/tlsca/tlsca.adminorg.docube.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${DOCUBE_NETWORK_HOME}/organizations/peerOrganizations/adminorg.docube.com/users/Admin@adminorg.docube.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
    echo "✓ AdminOrg environment set (localhost:7051)"
    
  elif [ "$ORG" == "userorg" ] || [ "$ORG" == "2" ]; then
    echo "Setting environment for UserOrg..."
    export CORE_PEER_LOCALMSPID="UserOrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${DOCUBE_NETWORK_HOME}/organizations/peerOrganizations/userorg.docube.com/tlsca/tlsca.userorg.docube.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${DOCUBE_NETWORK_HOME}/organizations/peerOrganizations/userorg.docube.com/users/Admin@userorg.docube.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
    echo "✓ UserOrg environment set (localhost:9051)"
    
  else
    echo "Usage: source ./setEnv.sh [adminorg|userorg]"
    echo "  adminorg - Set environment for AdminOrg (write permission)"
    echo "  userorg  - Set environment for UserOrg (read-only)"
    return 1
  fi
}

# Print current environment
printEnv() {
  echo ""
  echo "Current Fabric Environment:"
  echo "  PATH includes: $(which peer 2>/dev/null || echo 'peer not found')"
  echo "  FABRIC_CFG_PATH: ${FABRIC_CFG_PATH}"
  echo "  CORE_PEER_LOCALMSPID: ${CORE_PEER_LOCALMSPID}"
  echo "  CORE_PEER_ADDRESS: ${CORE_PEER_ADDRESS}"
  echo ""
}

# If argument provided, set org
if [ -n "$1" ]; then
  setOrg $1
  printEnv
else
  echo "Docube Network Environment loaded."
  echo "PATH and FABRIC_CFG_PATH set."
  echo ""
  echo "To set organization context, run:"
  echo "  setOrg adminorg   # For AdminOrg (write permission)"
  echo "  setOrg userorg    # For UserOrg (read-only)"
  echo ""
fi
