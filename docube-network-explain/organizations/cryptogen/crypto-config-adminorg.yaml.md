# Crypto Configuration for AdminOrg

File này dùng cho công cụ `cryptogen` để sinh ra chứng chỉ X.509 cho tổ chức AdminOrg.

```yaml
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# ---------------------------------------------------------------------------
# AdminOrg - System Admin Organization
# Đây là tổ chức có quyền lực cao nhất trong mạng.
# ---------------------------------------------------------------------------
PeerOrgs:
  - Name: AdminOrg
    Domain: adminorg.docube.com # Tên miền gốc cho các peer thuộc org này
    EnableNodeOUs: true # Bật tính năng Node Operational Units (phân loại Role trong chứng chỉ: Peer, Client, Admin, Orderer)
    Template:
      Count: 1 # Số lượng Peer cần tạo ban đầu (chỉ cần 1 peer0)
      SANS:
        - localhost # Thêm SANs localhost để test được từ máy host
        - peer0.adminorg.docube.com # Tên miền đầy đủ của container peer
    Users:
      Count: 1 # Tạo thêm 1 User Client identity (Admin đã được tạo mặc định)
```
