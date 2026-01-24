# Crypto Configuration for UserOrg

File này dùng cho công cụ `cryptogen` để sinh ra chứng chỉ X.509 cho tổ chức UserOrg.

```yaml
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# ---------------------------------------------------------------------------
# UserOrg - User Participant Organization
# Tổ chức dành cho người dùng cuối tham gia đọc/ghi dữ liệu.
# ---------------------------------------------------------------------------
PeerOrgs:
  - Name: UserOrg
    Domain: userorg.docube.com
    EnableNodeOUs: true
    Template:
      Count: 1 # Số lượng Peer: 1 (peer0)
      SANS:
        - localhost
        - peer0.userorg.docube.com
    Users:
      Count: 1
```
