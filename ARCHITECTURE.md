# Hệ thống blockchain dựa trên Hyperledger Fabric với mục tiêu:

* Chia sẻ tài liệu
* Mua bán tài liệu
* Đảm bảo quyền kiểm soát cấu hình hệ thống (Admin), nhưng cho phép người dùng tham gia ghi/đọc dữ liệu (User)

## 🏛️ Kiến trúc tổ chức (Organizations)

Hệ thống gồm 2 Organizations chính:

### 1️⃣ AdminOrg (System Admin Organization)

Đây là tổ chức đại diện cho hệ thống trung tâm.

**Quyền hạn:**

* Quản trị toàn bộ mạng Fabric
* Quản lý: Organizations, Channels, Peers, Orderers
* **Quyền Setup Channel & Config Update:** ĐỘC QUYỀN (UserOrg không có quyền này).
* **Quyền Lifecycle:** Commit chaincode definition (UserOrg chỉ có thể vote/approve).
* **Quyền Dữ liệu:** Ghi (Write) và Đọc (Query) toàn bộ dữ liệu.

📌 **AdminOrg đóng vai trò nhà quản trị tối cao của mạng.**

### 2️⃣ UserOrg (Participant Organization)

Đây là tổ chức đại diện cho người dùng tham gia hệ thống.

**Quyền hạn & Đặc điểm:**

* Người dùng tham gia mạng thông qua UserOrg
* Có Peer riêng để lưu trữ sổ cái (Ledger) và xác thực giao dịch
* **Quyền Ghi (Write/Invoke):** CÓ QUYỀN tạo giao dịch (Create/Update documents).
* **Quyền Đọc (Query):** CÓ QUYỀN truy vấn dữ liệu từ Peer của chính mình.
* **Quyền Chaincode:** Tham gia Approve (vote) để chạy chaincode trên Peer của mình.
* **KHÔNG CÓ QUYỀN:** Setup channel, thay đổi cấu hình mạng, commit chaincode definition.

📌 **UserOrg là thành viên tích cực, có thể đọc/ghi dữ liệu nhưng không được quản trị hệ thống.**

## 🔗 Channel Design

Hệ thống sử dụng 1 Channel duy nhất: `docubechannel`

📌 **Channel policy:**

* **Admin/Config Policy:** CHỈ AdminOrg (UserOrg không thể sửa cấu hình channel).
* **Writers/Readers Policy:** Cả AdminOrg và UserOrg (Cả 2 đều có thể gửi transaction).

## ⚙️ Peer & Transaction Flow

### 🔁 Luồng giao dịch WRITE (Tạo tài liệu):

1. User gửi request (qua App/Backend)
2. Backend sử dụng **UserOrg identity**
3. Gửi transaction proposal đến Peer (AdminOrg hoặc UserOrg)
4. Peer kiểm tra và Endorse (Ký duyệt)
5. Gửi lên Orderer để commit vào Ledger

### 🔍 Luồng giao dịch QUERY (Đọc tài liệu):

1. User gửi request
2. Backend sử dụng **UserOrg identity**
3. Query trực tiếp **Peer của UserOrg**
4. Trả dữ liệu về client

## 🔐 Identity & Security Model

**ACL & Policy được cấu hình:**

* **Channel Admin:** Chỉ AdminOrg.
* **Chaincode Endorsement:** `OR('AdminOrg.peer', 'UserOrg.peer')` (Một trong hai tổ chức xác thực là đủ).
* **Chaincode Lifecycle:** AdminOrg bắt buộc phải Commit.

## 📦 Chaincode Design

**Permissions:**

* Create / Update / Delete → AdminOrg + UserOrg
* Query → AdminOrg + UserOrg

**Endorsement policy:**

* `OR('AdminOrg.peer', 'UserOrg.peer')`