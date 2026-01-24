# Deploy Chaincode Script

Script quản lý vòng đời (lifecycle) của Smart Contract: Package -> Install -> Approve -> Commit.

```bash
#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#

# Các biến cấu hình mặc định (tên chaincode, version...)
CHANNEL_NAME="${1:-docubechannel}"
CC_NAME="${2:-docube-test}"
# ...

# 1. Package Chaincode
# Đóng gói source code thành file .tar.gz
packageChaincode() {
  peer lifecycle chaincode package ${CC_NAME}.tar.gz ...
}

# 2. Install Chaincode
# Cài đặt gói .tar.gz lên Peer node
installChaincode() {
  ORG=$1
  setGlobals $ORG
  peer lifecycle chaincode install ${CC_NAME}.tar.gz
}

# 3. Approve Chaincode
# Mỗi Org "vote" đồng ý với định nghĩa chaincode (version, policy...)
# QUAN TRỌNG: Tại đây ta set Endorsement Policy cho chaincode
approveForMyOrg() {
  # ...
  # --signature-policy "OR('AdminOrgMSP.peer','UserOrgMSP.peer')"
  # Policy này cho phép cả AdminOrg và UserOrg đều có quyền Endorse (Write) transaction
  peer lifecycle chaincode approveformyorg ... --signature-policy "OR('AdminOrgMSP.peer','UserOrgMSP.peer')"
}

# 4. Commit Chaincode Definition
# Gửi giao dịch Commit tới Orderer sau khi đã đủ số phiếu Approve
# QUAN TRỌNG: Chỉ AdminOrg mới có quyền chạy hàm này (do LifecycleEndorsement policy trong configtx.yaml)
commitChaincodeDefinitionAdminOnly() {
  setGlobals adminorg
  # Gửi lệnh commit
  # Cần gửi kèm --signature-policy để public policy cho toàn mạng biết
  peer lifecycle chaincode commit ... --signature-policy "OR('AdminOrgMSP.peer','UserOrgMSP.peer')"
}

# 5. Init Chaincode (Optional)
chaincodeInvokeInit() {
  # Gọi hàm InitLedger để khởi tạo dữ liệu mẫu
  peer chaincode invoke ... -c '{"function":"InitLedger","Args":[]}'
}

## Main Flow ##
# Thực hiện tuần tự các bước trên cho cả AdminOrg và UserOrg
# ...
```
