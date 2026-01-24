# Chaincode Lifecycle Flow (Fabric 2.x)

Quy trình cài đặt và kích hoạt smart contract. Quy trình này phân quyền rất chặt chẽ (Decentralized Governance).

## Quy trình 4 Bước

```mermaid
sequenceDiagram
    participant Dev as Developer/Script
    participant PAdmin as AdminOrg Peer
    participant PUser as UserOrg Peer
    participant Ord as Orderer

    %% Step 1: Package & Install
    Note over Dev,PUser: 1. Package & Install
    Dev->>Dev: Package code -> cc.tar.gz
    Dev->>PAdmin: Install cc.tar.gz
    Dev->>PUser: Install cc.tar.gz
    
    %% Step 2: Approve
    Note over Dev,PUser: 2. Approve (Vote)
    Dev->>Ord: ApproveForMyOrg (AdminOrg Signature)
    Dev->>Ord: ApproveForMyOrg (UserOrg Signature)
    Ord->>Ord: Check Policy in Configtx (ANY Admins) -> OK
    
    %% Step 3: Commit
    Note over Dev,PUser: 3. Commit (Finalize)
    Dev->>Ord: Commit Definition
    Note right of Dev: Policy: OR('Admin', 'User')
    Ord->>Ord: Check Lifecycle Policy (AdminOrg Only!) -> OK
    Ord->>PAdmin: Notify New CC
    Ord->>PUser: Notify New CC
    
    %% Step 4: Init
    Note over Dev,PUser: 4. Init / Invoke
    Dev->>PAdmin: Invoke InitLedger
    PAdmin-->>Dev: Success
```

## Giải thích chi tiết
1.  **Network Logic:** Chaincode không "được cài" lên mạng, nó được cài lên từng Peer.
2.  **Approve:** Mỗi tổ chức phải tự "ký nháy" (Approve) vào definition (tên, version, sequence ID) để đồng ý chạy nó.
3.  **Commit:** Đây là bước "ký chính thức". Trong mạng Docube, chỉ **AdminOrg** mới có quyền gửi lệnh Commit này (do cấu hình `LifecycleEndorsement`). Nếu UserOrg tự ý commit, Orderer sẽ từ chối.
4.  **Endorsement Policy:** Được định nghĩa lúc Approve/Commit. `OR('Admin', 'User')` nghĩa là sau này giao dịch chỉ cần 1 trong 2 chữ ký là hợp lệ.
