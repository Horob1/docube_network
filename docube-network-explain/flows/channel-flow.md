# Channel Creation Flow

Mô tả quá trình tạo "đường ống riêng" (channel) và đưa các peer vào đó.

## 1. Create Genesis Block
**Công cụ:** `configtxgen`
**Input:** `configtx.yaml`

```mermaid
graph LR
    A[Configtx.yaml] -->|configtxgen| B(Channel Genesis Block .block)
    B -->|Contains| C[Policy: AdminOrg Only]
    B -->|Contains| D[Consenters: Orderer]
```

## 2. Join Channel (Orderer & Peers)
**Công cụ:** `osnadmin`, `peer channel join`

```mermaid
sequenceDiagram
    participant Admin as Admin Script
    participant Ord as Orderer
    participant PAdmin as Peer AdminOrg
    participant PUser as Peer UserOrg

    Note over Admin,Ord: createChannel.sh
    
    Admin->>Ord: osnadmin join (Gửi Genesis Block)
    Ord-->>Admin: OK (Channel Created & Active)
    
    Admin->>PAdmin: peer channel join (Gửi Block 0)
    PAdmin->>PAdmin: Initialize Ledger with Block 0
    PAdmin-->>Admin: Success
    
    Admin->>PUser: peer channel join (Gửi Block 0)
    PUser->>PUser: Initialize Ledger with Block 0
    PUser-->>Admin: Success
```

## Giải thích biến quan trọng
*   `BLOCKFILE`: File nhị phân chứa cấu hình khởi tạo channel.
*   `osnadmin`: Công cụ mới (Fabric v2.3+) để quản lý channel trên Orderer mà không cần system channel.
*   `peer channel join`: Lệnh bắt buộc để peer biết sự tồn tại của channel và bắt đầu đồng bộ block từ Orderer.
