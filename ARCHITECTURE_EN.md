# Blockchain System Based on Hyperledger Fabric with Goals:

* Document Sharing
* Document Trading
* Ensure centralized system configuration control (Admin), but allow users to participate in writing/reading data (User)

## 🏛️ Organizational Architecture

The system consists of 2 main Organizations:

### 1️⃣ AdminOrg (System Admin Organization)

This organization represents the central system.

**Privileges:**

* Administers the entire Fabric network
* Manages: Organizations, Channels, Peers, Orderers
* **Channel Setup & Config Update Rights:** EXCLUSIVE (UserOrg does NOT have this right).
* **Lifecycle Rights:** Commit chaincode definition (UserOrg can only vote/approve).
* **Data Rights:** Write and Query all data.

📌 **AdminOrg acts as the supreme administrator of the network.**

### 2️⃣ UserOrg (Participant Organization)

This organization represents users participating in the system.

**Privileges & Characteristics:**

* Users join the network through UserOrg
* Has its own Peer to store the Ledger and verify transactions
* **Write Rights (Write/Invoke):** HAS RIGHT to create transactions (Create/Update documents).
* **Read Rights (Query):** HAS RIGHT to query data from its own Peer.
* **Chaincode Rights:** Participates in Approve (vote) to run chaincode on its own Peer.
* **NO RIGHTS:** Setup channel, change network configuration, commit chaincode definition.

📌 **UserOrg is an active member, able to read/write data but cannot administer the system.**

## 🔗 Channel Design

The system uses a single Channel: `docubechannel`

📌 **Channel policy:**

* **Admin/Config Policy:** AdminOrg ONLY (UserOrg cannot modify channel configuration).
* **Writers/Readers Policy:** Both AdminOrg and UserOrg (Both can submit transactions).

## ⚙️ Peer & Transaction Flow

### 🔁 WRITE Transaction Flow (Create Document):

1. User sends request (via App/Backend)
2. Backend uses **UserOrg identity**
3. Sends transaction proposal to Peer (AdminOrg or UserOrg)
4. Peer verifies and Endorses
5. Sends to Orderer to commit to Ledger

### 🔍 QUERY Transaction Flow (Read Document):

1. User sends request
2. Backend uses **UserOrg identity**
3. Queries directly from **UserOrg's Peer**
4. Returns data to client

## 🔐 Identity & Security Model

**ACL & Policy Configuration:**

* **Channel Admin:** AdminOrg Only.
* **Chaincode Endorsement:** `OR('AdminOrg.peer', 'UserOrg.peer')` (Verification from either organization is sufficient).
* **Chaincode Lifecycle:** AdminOrg MUST Commit.

## 📦 Chaincode Design

**Permissions:**

* Create / Update / Delete → AdminOrg + UserOrg
* Query → AdminOrg + UserOrg

**Endorsement policy:**

* `OR('AdminOrg.peer', 'UserOrg.peer')`
