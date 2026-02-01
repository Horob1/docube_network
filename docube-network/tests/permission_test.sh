#!/bin/bash
# =============================================================================
# COMPREHENSIVE PERMISSION TEST - Docube Chaincode v5.0
# Tests USER/OWNER/ADMIN authorization model
# =============================================================================

SCRIPT_DIR=$(dirname "$0")
cd "${SCRIPT_DIR}/.."

OUTPUT="/home/horob1/fabric-samples/docube-network/tests/PERMISSION_TEST_RESULTS.txt"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

PASS=0
FAIL=0

log() {
    echo -e "$1" | tee -a $OUTPUT
}

run_invoke() {
    local ORG=$1
    local ARGS=$2
    source setEnv.sh $ORG 2>/dev/null
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.docube.com --tls --cafile $ORDERER_CA -C docubechannel -n document_nft_cc --peerAddresses localhost:7051 --tlsRootCertFiles /home/horob1/fabric-samples/docube-network/organizations/peerOrganizations/adminorg.docube.com/tlsca/tlsca.adminorg.docube.com-cert.pem -c "$ARGS" 2>&1
}

run_query() {
    local ORG=$1
    local ARGS=$2
    source setEnv.sh $ORG 2>/dev/null
    peer chaincode query -C docubechannel -n document_nft_cc -c "$ARGS" 2>&1
}

test_case() {
    local TEST_NAME="$1"
    local ORG="$2"
    local ARGS="$3"
    local IS_INVOKE="$4"
    local EXPECT_SUCCESS="$5"
    
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TEST: $TEST_NAME"
    log "ORG: $ORG | EXPECT: $([ "$EXPECT_SUCCESS" = "true" ] && echo 'SUCCESS' || echo 'FAIL')"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ "$IS_INVOKE" = "true" ]; then
        RESULT=$(run_invoke "$ORG" "$ARGS")
        sleep 2
    else
        RESULT=$(run_query "$ORG" "$ARGS")
    fi
    
    log "RESULT: $(echo "$RESULT" | tail -3)"
    
    if echo "$RESULT" | grep -q "Error\|error\|ERR_"; then
        if [ "$EXPECT_SUCCESS" = "false" ]; then
            log "${GREEN}✓ PASS${NC} (Expected failure)"
            ((PASS++))
        else
            log "${RED}✗ FAIL${NC} (Expected success)"
            ((FAIL++))
        fi
    else
        if [ "$EXPECT_SUCCESS" = "true" ]; then
            log "${GREEN}✓ PASS${NC}"
            ((PASS++))
        else
            log "${RED}✗ FAIL${NC} (Expected failure)"
            ((FAIL++))
        fi
    fi
}

# =============================================================================
# INIT
# =============================================================================
echo "" > $OUTPUT
log "============================================================"
log " DOCUBE CHAINCODE v5.0 - PERMISSION TEST SUITE"
log " Date: $(date)"
log " Permission Model: USER / OWNER / ADMIN"
log "============================================================"

# =============================================================================
# 1. USER PERMISSION TESTS - CreateDocument (Any user can create)
# =============================================================================
log ""
log "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
log "▓  SECTION 1: USER CAN CREATE DOCUMENTS          ▓"
log "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"

test_case "AdminOrg creates document (admin-doc-1)" "adminorg" \
    '{"function":"document:CreateDocument","Args":["admin-doc-1","hash1","SHA256","sysuser1"]}' "true" "true"

test_case "UserOrg creates document (user-doc-1)" "userorg" \
    '{"function":"document:CreateDocument","Args":["user-doc-1","hash2","SHA256","sysuser2"]}' "true" "true"

# =============================================================================
# 2. OWNER PERMISSION TESTS - Only owner can modify
# =============================================================================
log ""
log "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
log "▓  SECTION 2: OWNER CAN MODIFY OWN DOCUMENTS     ▓"
log "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"

test_case "AdminOrg updates own document" "adminorg" \
    '{"function":"document:UpdateDocument","Args":["admin-doc-1","newhash1","SHA256","1"]}' "true" "true"

test_case "UserOrg updates own document" "userorg" \
    '{"function":"document:UpdateDocument","Args":["user-doc-1","newhash2","SHA256","1"]}' "true" "true"

test_case "AdminOrg grants access on own document" "adminorg" \
    '{"function":"access:GrantAccess","Args":["admin-doc-1","TestUser1","UserOrgMSP","sys1"]}' "true" "true"

test_case "UserOrg grants access on own document" "userorg" \
    '{"function":"access:GrantAccess","Args":["user-doc-1","TestUser2","AdminOrgMSP","sys2"]}' "true" "true"

# =============================================================================
# 3. NON-OWNER REJECTION TESTS - Users can't modify others' documents
# =============================================================================
log ""
log "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
log "▓  SECTION 3: NON-OWNER CANNOT MODIFY DOCUMENTS  ▓"
log "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"

test_case "UserOrg tries to update AdminOrg's doc (REJECT)" "userorg" \
    '{"function":"document:UpdateDocument","Args":["admin-doc-1","hackhash","SHA256","2"]}' "true" "false"

test_case "UserOrg tries to grant access on AdminOrg's doc (REJECT)" "userorg" \
    '{"function":"access:GrantAccess","Args":["admin-doc-1","HackerUser","UserOrgMSP","sysX"]}' "true" "false"

test_case "UserOrg tries to delete AdminOrg's doc (REJECT)" "userorg" \
    '{"function":"document:SoftDeleteDocument","Args":["admin-doc-1"]}' "true" "false"

test_case "UserOrg tries to transfer AdminOrg's doc (REJECT)" "userorg" \
    '{"function":"document:TransferOwnership","Args":["admin-doc-1","HackerID","UserOrgMSP"]}' "true" "false"

# =============================================================================
# 4. ADMIN OVERRIDE TESTS - AdminOrg can modify any document
# =============================================================================
log ""
log "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
log "▓  SECTION 4: ADMIN CAN OVERRIDE ANY DOCUMENT    ▓"
log "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"

test_case "AdminOrg updates UserOrg's doc (ADMIN OVERRIDE)" "adminorg" \
    '{"function":"document:UpdateDocument","Args":["user-doc-1","admin-override-hash","SHA256","2"]}' "true" "true"

test_case "AdminOrg grants access on UserOrg's doc (ADMIN OVERRIDE)" "adminorg" \
    '{"function":"access:GrantAccess","Args":["user-doc-1","AdminGrantedUser","AdminOrgMSP","sys3"]}' "true" "true"

test_case "AdminOrg revokes access on UserOrg's doc (ADMIN OVERRIDE)" "adminorg" \
    '{"function":"access:RevokeAccess","Args":["user-doc-1","AdminGrantedUser"]}' "true" "true"

# =============================================================================
# 5. QUERY PERMISSIONS - Any user can query
# =============================================================================
log ""
log "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
log "▓  SECTION 5: ANY USER CAN QUERY                 ▓"
log "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"

test_case "UserOrg queries AdminOrg's document" "userorg" \
    '{"function":"document:GetDocument","Args":["admin-doc-1"]}' "false" "true"

test_case "AdminOrg queries all documents" "adminorg" \
    '{"function":"document:GetAllDocuments","Args":[]}' "false" "true"

test_case "UserOrg queries all access by document" "userorg" \
    '{"function":"access:GetAllAccessByDocument","Args":["admin-doc-1"]}' "false" "true"

# =============================================================================
# SUMMARY
# =============================================================================
log ""
log "============================================================"
log "                    TEST SUMMARY"
log "============================================================"
log "TOTAL TESTS: $((PASS + FAIL))"
log "PASSED: ${GREEN}$PASS${NC}"
log "FAILED: ${RED}$FAIL${NC}"
log ""
if [ $FAIL -eq 0 ]; then
    log "🎉 ALL TESTS PASSED!"
    log "Permission Model: USER/OWNER/ADMIN verified successfully"
else
    log "❌ SOME TESTS FAILED"
fi
log ""
log "Results saved to: $OUTPUT"
