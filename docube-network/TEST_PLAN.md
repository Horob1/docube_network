# Docube Network Test Plan

Các lệnh kiểm tra network theo ARCHITECTURE.md.

## Chuẩn bị

```bash
cd ~/fabric-samples/docube-network
source ./setEnv.sh
```

---

## 1. Kiểm tra Network Status

### 1.1 Docker containers
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
**Kết quả mong đợi:**
| Container | Status | Ports |
|-----------|--------|-------|
| orderer.docube.com | Up | 7050, 7053, 9443 |
| peer0.adminorg.docube.com | Up | 7051, 9444 |
| peer0.userorg.docube.com | Up | 9051, 9445 |

---

## 2. Kiểm tra Channel Membership

### 2.1 AdminOrg peer
```bash
setOrg adminorg
peer channel list
```
**Kết quả mong đợi:** `docubechannel`

### 2.2 UserOrg peer
```bash
setOrg userorg
peer channel list
```
**Kết quả mong đợi:** `docubechannel`

---

## 3. Kiểm tra Channel Info

```bash
setOrg adminorg
peer channel getinfo -c docubechannel
```
**Kết quả mong đợi:** Block height, current block hash

---

## 4. Kiểm tra Orderer Channel List

```bash
osnadmin channel list -o localhost:7053 \
  --ca-file $ORDERER_CA \
  --client-cert ${PWD}/organizations/ordererOrganizations/docube.com/orderers/orderer.docube.com/tls/server.crt \
  --client-key ${PWD}/organizations/ordererOrganizations/docube.com/orderers/orderer.docube.com/tls/server.key
```
**Kết quả mong đợi:** `docubechannel` với status "active"

---

## 5. Kiểm tra Gossip (Peer Discovery)

### AdminOrg peer thấy UserOrg
```bash
docker logs peer0.adminorg.docube.com 2>&1 | grep -i "userorg"
```
**Kết quả mong đợi:** Có log về peer0.userorg.docube.com

### UserOrg peer thấy AdminOrg
```bash
docker logs peer0.userorg.docube.com 2>&1 | grep -i "adminorg"
```
**Kết quả mong đợi:** Có log về peer0.adminorg.docube.com

---

## 6. Kiểm tra MSP/Identity

### 6.1 AdminOrg identity
```bash
setOrg adminorg
peer channel fetch config -c docubechannel -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.docube.com --tls --cafile $ORDERER_CA
```
**Kết quả mong đợi:** Tải được config block

### 6.2 UserOrg identity
```bash
setOrg userorg
peer channel fetch config -c docubechannel -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.docube.com --tls --cafile $ORDERER_CA
```
**Kết quả mong đợi:** Tải được config block (read permission)

---

## 7. Kiểm tra Policies (sau khi deploy chaincode)

> ⚠️ Cần deploy chaincode trước để test đầy đủ

### 7.1 Write từ AdminOrg (NÊN THÀNH CÔNG)
```bash
setOrg adminorg
peer chaincode invoke -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.docube.com --tls --cafile $ORDERER_CA \
  -C docubechannel -n docube-test \
  --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
  -c '{"function":"CreateDoc","Args":["doc1","Test Document","Created by AdminOrg","Admin","2026-01-24"]}'
```
**Kết quả mong đợi:** ✅ Success - Transaction committed

### 7.2 Write từ UserOrg (NÊN THÀNH CÔNG)
```bash
setOrg userorg
peer chaincode invoke -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.docube.com --tls --cafile $ORDERER_CA \
  -C docubechannel -n docube-test \
  --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
  -c '{"function":"CreateDoc","Args":["doc2","Test Document","Created by UserOrg","User","2026-01-24"]}'
```
**Kết quả mong đợi:** ✅ Success - Transaction committed

### 7.3 Query từ AdminOrg (NÊN THÀNH CÔNG)
```bash
setOrg adminorg
peer chaincode query -C docubechannel -n docube-test -c '{"Args":["GetAllDocs"]}'
```
**Kết quả mong đợi:** ✅ Trả về danh sách documents

### 7.4 Query từ UserOrg (NÊN THÀNH CÔNG)
```bash
setOrg userorg
peer chaincode query -C docubechannel -n docube-test -c '{"Args":["GetAllDocs"]}'
```
**Kết quả mong đợi:** ✅ Trả về danh sách documents

---

## Tổng kết theo ARCHITECTURE.md (Cập nhật)

| Chức năng | AdminOrg | UserOrg |
|-----------|----------|---------|
| Join channel | ✅ | ✅ |
| Query data | ✅ | ✅ (Own peer) |
| Write/Invoke | ✅ | ✅ (Endorsement) |
| Approve CC | ✅ | ✅ |
| Helper (Write) | ✅ | ✅ |
| Channel admin | ✅ | ❌ (Setup/Config) |
