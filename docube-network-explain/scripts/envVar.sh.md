# Environment Variables Script - Giải thích chi tiết

File này giống như "thẻ bài" danh tính. Khi bạn chạy lệnh `peer` trên terminal, lệnh đó cần biết "Tôi đang là ai?". File này cung cấp câu trả lời đó bằng cách set các biến môi trường.

```bash
#!/usr/bin/env bash

# ...

# Biến Global thường dùng
export CORE_PEER_TLS_ENABLED=true # Luôn bật TLS khi giao tiếp
export ORDERER_CA=... # Đường dẫn CA Cert của Orderer. Để client tin tưởng Orderer (SSL handshake).

# Hàm setGlobals($ORG)
# Chức năng: Chuyển đổi "nhân cách" của terminal hiện tại.
# Khi gọi setGlobals adminorg, terminal sẽ đóng vai Admin của AdminOrg.
setGlobals() {
  local USING_ORG=""
  # ... (logic xử lý input)

  if [ "$USING_ORG" == "adminorg" ]; then
    # 1. Định danh MSP
    export CORE_PEER_LOCALMSPID=AdminOrgMSP 
    # Khi gửi transaction, nó sẽ được ký bởi MSP ID này. Peer phía nhận sẽ kiểm tra xem MSP này có quyền không.

    # 2. Định danh Root CA (TLS)
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ADMINORG_CA 
    # File chứa Public Key của CA đã cấp chứng chỉ cho Peer AdminOrg.
    # Dùng để verify rằng "peer0.adminorg.docube.com" đúng là peer thật, không phải giả mạo.

    # 3. Định danh User Identity (Signing Identity)
    export CORE_PEER_MSPCONFIGPATH=${DOCUBE_NETWORK_HOME}/organizations/.../users/Admin@.../msp
    # ĐÂY LÀ CHÌA KHÓA QUYỀN LỰC.
    # Thư mục này chứa Private Key của user "Admin".
    # Bất kỳ lệnh nào chạy sau đó (peer chaincode install...) sẽ được ký bằng Private Key này.
    # Vì User này có role "ADMIN" trong cert, nên nó làm được mọi thứ.

    # 4. Địa chỉ Peer mục tiêu mặc định
    export CORE_PEER_ADDRESS=localhost:7051 
    # Nếu chạy lệnh mà không chỉ định --peerAddresses, nó sẽ gửi tới địa chỉ này.

  elif [ "$USING_ORG" == "userorg" ]; then
    export CORE_PEER_LOCALMSPID=UserOrgMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_USERORG_CA
    export CORE_PEER_MSPCONFIGPATH=${DOCUBE_NETWORK_HOME}/organizations/.../users/Admin@.../msp
    # Lưu ý: Ở đây ta dùng Admin@userorg.
    # Đây là Admin nội bộ của UserOrg (quản lý peer UserOrg), KHÔNG PHẢI Admin hệ thống.
    # User này chỉ quản lý được Peer của mình, không quản lý được Channel.
    export CORE_PEER_ADDRESS=localhost:9051
  fi
}

# Hàm parsePeerConnectionParameters
# Dùng cho các lệnh cần sự đồng thuận của nhiều tổ chức (như Lifecycle Commit).
# Ví dụ: peer lifecycle chaincode commit ... --peerAddresses peerAdmin --tlsRootCertFiles ... --peerAddresses peerUser --tlsRootCertFiles ...
# Hàm này tự động tạo chuỗi dài đó.
```
