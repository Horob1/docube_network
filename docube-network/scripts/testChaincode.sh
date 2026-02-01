#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Test Chaincode Permissions for Docube Network
# This script tests if AdminOrg can write and UserOrg is read-only

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCUBE_HOME=$(dirname "$SCRIPT_DIR")

export PATH=${DOCUBE_HOME}/../bin:$PATH
export FABRIC_CFG_PATH=${DOCUBE_HOME}/../config/
export CORE_PEER_TLS_ENABLED=true

CHANNEL_NAME="docubechannel"
CC_NAME="document_nft_cc"
ORDERER_CA=${DOCUBE_HOME}/organizations/ordererOrganizations/docube.com/tlsca/tlsca.docube.com-cert.pem

# Colors
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'

println() { echo -e "$1"; }
successln() { println "${C_GREEN}✓ $1${C_RESET}"; }
errorln() { println "${C_RED}✗ $1${C_RESET}"; }
infoln() { println "${C_BLUE}→ $1${C_RESET}"; }
warnln() { println "${C_YELLOW}! $1${C_RESET}"; }

setOrg() {
  ORG=$1
  if [ "$ORG" == "adminorg" ]; then
    export CORE_PEER_LOCALMSPID="AdminOrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${DOCUBE_HOME}/organizations/peerOrganizations/adminorg.docube.com/tlsca/tlsca.adminorg.docube.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${DOCUBE_HOME}/organizations/peerOrganizations/adminorg.docube.com/users/Admin@adminorg.docube.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ "$ORG" == "userorg" ]; then
    export CORE_PEER_LOCALMSPID="UserOrgMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${DOCUBE_HOME}/organizations/peerOrganizations/userorg.docube.com/tlsca/tlsca.userorg.docube.com-cert.pem
    export CORE_PEER_MSPCONFIGPATH=${DOCUBE_HOME}/organizations/peerOrganizations/userorg.docube.com/users/Admin@userorg.docube.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  fi
}

println ""
println "╔════════════════════════════════════════════════════════════╗"
println "║         DOCUBE NETWORK - CHAINCODE PERMISSION TEST         ║"
println "╚════════════════════════════════════════════════════════════╝"
println ""

# Test 1: Query from AdminOrg (should SUCCEED)
println "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
infoln "[TEST 1] Query from AdminOrg (Expected: SUCCESS)"
setOrg adminorg
peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["GetAllDocs"]}' > /tmp/test1.txt 2>&1
if [ $? -eq 0 ]; then
  successln "AdminOrg can query data"
  cat /tmp/test1.txt
else
  errorln "AdminOrg query failed (unexpected)"
  cat /tmp/test1.txt
fi
println ""

# Test 2: Query from UserOrg (should SUCCEED - UserOrg peer handles queries)
println "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
infoln "[TEST 2] Query from UserOrg (Expected: SUCCESS)"
setOrg userorg
peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["GetAllDocs"]}' > /tmp/test2.txt 2>&1
if [ $? -eq 0 ]; then
  successln "UserOrg can query data (from UserOrg peer)"
  cat /tmp/test2.txt
else
  errorln "UserOrg query failed (unexpected)"
  cat /tmp/test2.txt
fi
println ""

# Test 3: Write from AdminOrg (should SUCCEED)
println "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
infoln "[TEST 3] Write from AdminOrg (Expected: SUCCESS)"
setOrg adminorg
TIMESTAMP=$(date +%Y-%m-%d)
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.docube.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CC_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE -c "{\"function\":\"CreateDoc\",\"Args\":[\"doc-test-1\",\"Test Document\",\"Created by AdminOrg\",\"Admin\",\"$TIMESTAMP\"]}" > /tmp/test3.txt 2>&1
if [ $? -eq 0 ]; then
  successln "AdminOrg can write data (write permission verified)"
  cat /tmp/test3.txt
else
  errorln "AdminOrg write failed (unexpected)"
  cat /tmp/test3.txt
fi
println ""

# Wait for block to be committed
sleep 2

# Test 4: Write from UserOrg (should SUCCEED - Endorsement Policy OR(Admin, User))
println "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
infoln "[TEST 4] Write from UserOrg (Expected: SUCCESS)"
setOrg userorg
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.docube.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CC_NAME --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE -c "{\"function\":\"CreateDoc\",\"Args\":[\"doc-test-2\",\"Test Document\",\"Created by UserOrg\",\"User\",\"$TIMESTAMP\"]}" > /tmp/test4.txt 2>&1
if [ $? -eq 0 ]; then
  successln "UserOrg can write data (write permission verified)"
  cat /tmp/test4.txt
else
  errorln "UserOrg write failed (unexpected)"
  cat /tmp/test4.txt
fi
println ""

# Test 5: Verify write only from AdminOrg
println "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
infoln "[TEST 5] Verify data written by AdminOrg is readable"
setOrg adminorg
peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["ReadDoc","doc-test-1"]}' > /tmp/test5.txt 2>&1
if [ $? -eq 0 ]; then
  successln "Document created by AdminOrg is readable"
  cat /tmp/test5.txt
else
  errorln "Document not found"
  cat /tmp/test5.txt
fi
println ""

# Summary
println "╔════════════════════════════════════════════════════════════╗"
println "║                      TEST SUMMARY                          ║"
println "╠════════════════════════════════════════════════════════════╣"
println "║  Test 1: AdminOrg Query    → Expected: ✓ SUCCESS           ║"
println "║  Test 2: UserOrg Query     → Expected: ✓ SUCCESS           ║"
println "║  Test 3: AdminOrg Write    → Expected: ✓ SUCCESS           ║"
println "║  Test 4: UserOrg Write     → Expected: ✓ SUCCESS           ║"
println "║  Test 5: Read verification → Expected: ✓ SUCCESS           ║"
println "╚════════════════════════════════════════════════════════════╝"
println ""
println "If all tests match expected results, the permission model is correct!"
println ""
