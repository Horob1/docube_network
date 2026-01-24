# Test Chaincode Script

Script kiểm thử tự động để xác minh quyền hạn (Permissions) của các Org.

```bash
#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#

# ... (Setup environment) ...

# Test 1: Query từ AdminOrg
# Mong đợi: THÀNH CÔNG
setOrg adminorg
peer chaincode query ... -c '{"Args":["GetAllDocs"]}'

# Test 2: Query từ UserOrg
# Mong đợi: THÀNH CÔNG (UserOrg có quyền đọc)
setOrg userorg
peer chaincode query ... -c '{"Args":["GetAllDocs"]}'

# Test 3: Write từ AdminOrg
# Mong đợi: THÀNH CÔNG (AdminOrg có quyền ghi)
setOrg adminorg
peer chaincode invoke ... -c '{"function":"CreateDoc",...}'

# Test 4: Write từ UserOrg
# Mong đợi: THÀNH CÔNG
# (Do Endorsement Policy "OR(Admin, User)" nên UserOrg được phép ghi)
setOrg userorg
peer chaincode invoke ... -c '{"function":"CreateDoc",...}'

# Test 5: Verify dữ liệu
# Đọc lại dữ liệu vừa ghi để đảm bảo tính toàn vẹn
setOrg adminorg
peer chaincode query ...
```
