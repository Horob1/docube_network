# Configtx.yaml - Giải thích chi tiết Variables & Policies

File này là "trái tim" cấu hình của mạng Fabric. Nó định nghĩa AI là ai, AI làm được gì (Policy), và BLOCK đầu tiên (Genesis Block) trông như thế nào.

```yaml
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

---
################################################################################
#
#   SECTION: Organizations
#   Định nghĩa danh tính và quyền hạn của các tổ chức (Org).
#
################################################################################
Organizations:
  - &OrdererOrg
    Name: OrdererOrg  # Tên định danh của Org trong file config
    ID: OrdererMSP    # MSP ID (Membership Service Provider ID) - Chuỗi định danh quan trọng nhất dùng trong certificate.
                      # Các node thuộc org này phải có chứng chỉ X.509 với OU (Organizational Unit) hoặc Subject khớp với MSP này.
    MSPDir: ../organizations/ordererOrganizations/docube.com/msp # Đường dẫn tới thư mục chứa chứng chỉ CA, Admin certs, TLS CA của Org này.
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('OrdererMSP.member')" # Quy tắc: Chỉ cần chữ ký của bất kỳ "member" nào thuộc OrdererMSP là thỏa mãn quyền Đọc.
      Writers:
        Type: Signature
        Rule: "OR('OrdererMSP.member')" # Quy tắc: Bất kỳ member nào cũng có quyền Ghi (trong phạm vi quản lý của Orderer).
      Admins:
        Type: Signature
        Rule: "OR('OrdererMSP.admin')"  # Quy tắc: Bắt buộc phải là role "admin" (có cờ admin trong cert) mới được quyền Admin.
    OrdererEndpoints:
      - orderer.docube.com:7050 # Địa chỉ host:port mà các Peer dùng để gửi giao dịch tới Orderer này.

  - &AdminOrg
    Name: AdminOrgMSP
    ID: AdminOrgMSP
    MSPDir: ../organizations/peerOrganizations/adminorg.docube.com/msp
    Policies:
      # ... (Readers/Writers tương tự trên) ...
      Endorsement:
        Type: Signature
        Rule: "OR('AdminOrgMSP.peer')" # QUAN TRỌNG: Định nghĩa ai có quyền "ký xác thực" (Endorse) cho Org này.
                                       # Ở đây là bất kỳ Peer nào thuộc AdminOrgMSP.
    AnchorPeers:
      # Anchor Peer là "cổng giao tiếp" để các Org khác tìm thấy peer của Org này (dùng cho Gossip Protocol).
      - Host: peer0.adminorg.docube.com
        Port: 7051

  - &UserOrg
    # (Tương tự AdminOrg nhưng dành cho User)
    Name: UserOrgMSP
    ID: UserOrgMSP
    # ...

################################################################################
#
#   SECTION: Capabilities
#   Định nghĩa phiên bản giao thức mạng. Để đảm bảo tính tương thích, tất cả các node
#   phải hỗ trợ capability này mới được tham gia.
#
################################################################################
Capabilities:
  Channel: &ChannelCapabilities
    V2_0: true # Sử dụng giao thức channel v2.0 (hỗ trợ lifecycle mới)
  Orderer: &OrdererCapabilities
    V2_0: true # Orderer hỗ trợ v2.0
  Application: &ApplicationCapabilities
    V2_5: true # Application channel hỗ trợ v2.5 (cho phép purge private data,...)

################################################################################
#
#   SECTION: Application
#   Quy định luật chơi trong "Application Channel" (nơi diễn ra giao dịch nghiệp vụ).
#
################################################################################
Application: &ApplicationDefaults
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers" # "ANY": Nếu có 10 org, chỉ cần policy "Readers" của 1 org thỏa mãn là được.
                          # => Ai trong channel cũng đọc được.
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers" # "ANY": Bất kỳ Org nào cũng được quyền gửi transaction write.
                          # Nếu sửa thành "MAJORITY Writers", cần >50% số Org đồng ý (ít dùng cho writer).
    Admins:
      Type: ImplicitMeta
      Rule: "ANY Admins"  # Cho phép Admin của bất kỳ Org nào thực hiện tác vụ admin mức app (như Approve chaincode cho org mình).
    
    LifecycleEndorsement:
      Type: Signature
      # ĐÂY LÀ CHỐT CHẶN QUYỀN LỰC CỦA ADMINORG.
      # Rule này quy định ai được quyền COMMIT chaincode definition (bước cuối cùng của deploy).
      # Chỉ định rõ ràng Org "AdminOrgMSP" => UserOrg không thể deploy contract mới.
      Rule: "OR('AdminOrgMSP.peer')"
    
    Endorsement:
      Type: Signature
      # Default endorsement policy nếu smart contract không quy định riêng.
      Rule: "OR('AdminOrgMSP.peer')"

################################################################################
#
#   SECTION: Orderer
#   Cấu hình thuật toán đồng thuận.
#
################################################################################
Orderer: &OrdererDefaults
  OrdererType: etcdraft # Sử dụng Raft consensus (Leader-Follower model), an toàn cho production.
  Addresses:
    - orderer.docube.com:7050
  BatchTimeout: 2s # Nếu không đủ transaction để đóng block, sau 2s sẽ tự đóng block.
                   # Giúp mạng không bị treo nếu ít giao dịch.
  BatchSize:
    MaxMessageCount: 10 # Một block chứa tối đa 10 transaction.
                        # Số này nhỏ giúp độ trễ thấp (low latency), số lớn giúp thông lượng cao (high throughput).
    AbsoluteMaxBytes: 99 MB # Kích thước tuyệt đối tối đa của block.
    PreferredMaxBytes: 512 KB # Kích thước mong muốn, block thường sẽ cắt ở khoảng này.
  Organizations:
  Policies:
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins" # Để thay đổi cấu hình Orderer (vd: thêm node consensus), cần đa số Admin đồng ý.

################################################################################
#
#   CHANNEL
#   Cấu hình chung cho Channel.
#
################################################################################
Channel: &ChannelDefaults
  Policies:
    Admins:
      Type: Signature
      # QUYỀN LỰC TỐI CAO VỀ CẤU HÌNH.
      # Chỉ AdminOrg được phép thay đổi config channel (vd: thêm Org mới, đổi batch size).
      # "OR('AdminOrgMSP.admin')" => Chỉ AdminOrg, UserOrg bị loại.
      Rule: "OR('AdminOrgMSP.admin')"
    # ...

################################################################################
#
#   Profile: DocubeChannel
#   Profile này được configtxgen dùng để "render" ra file genesis block (.block).
#   Nó ghép nối tất cả các mảnh ghép (Orderer, Application, Policies) lại với nhau.
#
################################################################################
Profiles:
  DocubeChannel:
    <<: *ChannelDefaults
    Orderer:
      <<: *OrdererDefaults
      OrdererType: etcdraft
      EtcdRaft:
        Consenters: # Danh sách các node tham gia đồng thuận Raft.
          - Host: orderer.docube.com
            Port: 7050
            ClientTLSCert: ../organizations/ordererOrganizations/docube.com/orderers/orderer.docube.com/tls/server.crt
            ServerTLSCert: ...
      Organizations:
        - *OrdererOrg
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *AdminOrg # Kích hoạt AdminOrg trong channel này
        - *UserOrg  # Kích hoạt UserOrg trong channel này
```
