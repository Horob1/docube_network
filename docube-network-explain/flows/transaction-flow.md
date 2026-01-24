# Transaction Flow (Write & Query)

Làm thế nào dữ liệu đi từ User vào Ledger?

## 1. Write Transaction (Ghi dữ liệu/Invoke)

```mermaid
sequenceDiagram
    participant Client as User Client/App
    participant Peer as Endorsing Peer (UserOrg/AdminOrg)
    participant Ord as OrdererService
    participant Committer as All Peers

    Client->>Peer: 1. Proposal (CreateDoc)
    Note right of Client: Ký bởi User Identity
    
    Peer->>Peer: 2. Execute & Simulate
    Peer->>Peer: Check: User có quyền Write? (Policy check)
    Peer-->>Client: 3. Proposal Response (RWSet + Signature)
    
    Client->>Ord: 4. Submit Transaction (Kèm chữ ký Peer)
    
    Ord->>Ord: 5. Order & Cut Block
    Ord->>Committer: 6. Deliver Block
    
    Committer->>Committer: 7. Validate (VSCC) & Commit
    Note right of Committer: Ledger Updated!
```

## 2. Query Transaction (Đọc dữ liệu)

```mermaid
sequenceDiagram
    participant Client as User Client
    participant Peer as UserOrg Peer

    Client->>Peer: 1. Query Proposal (GetAllDocs)
    Peer->>Peer: 2. Query World State (LevelDB/CouchDB)
    Peer-->>Client: 3. Return Data
    
    Note over Client,Peer: Không cần gửi Orderer. Nhanh & Rẻ.
```

## Điểm nhấn bảo mật
*   **Write:** Cần chữ ký của Peer (Endorsement) để chứng minh transaction hợp lệ theo business logic.
*   **Read:** Chỉ cần hỏi Peer của chính mình, không lộ thông tin query ra ngoài mạng (Privacy).
