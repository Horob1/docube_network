# Network Startup Flow

Mô tả quá trình khởi động mạng Docube từ con số 0.

## 1. Crypto Generation (Sinh danh tính)
**Công cụ:** `cryptogen`
**Input:** `crypto-config-*.yaml`

```mermaid
graph TD
    A[Start ./network.sh up] --> B{Crypto Exists?}
    B -- No --> C[Run cryptogen]
    B -- Yes --> D[Skip Gen]
    
    C --> C1[Generate AdminOrg Certs]
    C --> C2[Generate UserOrg Certs]
    C --> C3[Generate OrdererOrg Certs]
    
    C1 --> E[Output: organizations/peerOrganizations/adminorg.docube.com/...]
    C2 --> F[Output: organizations/peerOrganizations/userorg.docube.com/...]
```

## 2. Docker Containers Start
**Công cụ:** `docker-compose`
**Input:** `compose-docube-net.yaml`

```mermaid
graph TD
    A[Docker Compose Up] --> B[Create Network: docube_network]
    B --> C[Start Volume: orderer.docube.com]
    B --> D[Start Volume: peer0.adminorg]
    
    C --> E[Container: Orderer]
    D --> F[Container: Peer AdminOrg]
    D --> G[Container: Peer UserOrg]
    
    E --> H{Ready to Accept Connections?}
    F --> H
    G --> H
```

## Giải thích chi tiết
1.  **Crypto Gen:** Tạo ra X.509 Certificates (Public/Private Key) cho từng node và user. Đây là bước quan trọng nhất để thiết lập danh tính (Identity).
2.  **Container Start:**
    *   **Orderer:** Khởi động, đọc config, sẵn sàng nhận request tạo channel.
    *   **Peers:** Khởi động, load MSP từ volumes, kết nối gossip (nếu có), mở port 7051/9051 chờ lệnh.
