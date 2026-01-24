# Docker Compose - Giải thích chi tiết Variables

File này định nghĩa các "máy ảo container" (Peer, Orderer) và môi trường chạy của chúng.

```yaml
# Copyright Docube System. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

# ...

services:
  # --- ORDERER SERVICE ---
  orderer.docube.com:
    # ...
    environment:
      - FABRIC_LOGGING_SPEC=INFO # Mức độ log (INFO, DEBUG, ERROR). DEBUG sẽ in ra rất nhiều tin.
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0 # Orderer lắng nghe kết nối từ mọi IP (quan trọng trong môi trường container).
      - ORDERER_GENERAL_LISTENPORT=7050 # Cổng mặc định cho Client (Peer/SDK) kết nối.
      
      # Cấu hình MSP (Identity của node này)
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP # Node này thuộc về Org nào? (dùng để ký block).
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp # Đường dẫn chứa private key và cert của node.

      # Cấu hình TLS (Transport Layer Security - Mã hóa đường truyền)
      - ORDERER_GENERAL_TLS_ENABLED=true # Bắt buộc bật TLS cho mạng production.
      - ORDERER_GENERAL_TLS_PRIVATEKEY=... # Private key TLS của server.
      - ORDERER_GENERAL_TLS_CERTIFICATE=... # Public cert TLS của server.
      - ORDERER_GENERAL_TLS_ROOTCAS=[...] # Danh sách CA được tin tưởng (Root CA của Orderer Org).

      # Cấu hình Cluster (Raft Consensus) - Cổng giao tiếp giữa các Orderer node với nhau
      - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=... # Cert dùng để authenticate với Orderer khác.
      - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=...
      - ORDERER_GENERAL_BOOTSTRAPMETHOD=none # Không dùng system channel (deprecated), dùng channel application trực tiếp.
      - ORDERER_CHANNELPARTICIPATION_ENABLED=true # Cho phép dùng lệnh 'osnadmin channel join'.

  # --- PEER SERVICE ---
  peer0.adminorg.docube.com:
    # ...
    environment:
      # --- Core Configuration ---
      - FABRIC_CFG_PATH=/etc/hyperledger/peercfg # Nơi chứa fiel core.yaml (cấu hình cấp thấp của peer).
      - FABRIC_LOGGING_SPEC=INFO
      - CORE_PEER_TLS_ENABLED=true # Bắt buộc TLS.
      - CORE_PEER_PROFILE_ENABLED=false # Tắt profiling để tăng hiệu năng.
      
      # --- Identity & Network ---
      - CORE_PEER_ID=peer0.adminorg.docube.com # Tên định danh duy nhất của Peer trong mạng.
      - CORE_PEER_ADDRESS=peer0.adminorg.docube.com:7051 # Địa chỉ IP:Port mà peer này lắng nghe request.
      - CORE_PEER_LISTENADDRESS=0.0.0.0:7051 # Bind vào mọi interface mạng.
      
      # --- Chaincode Execution ---
      # Cấu hình giao tiếp giữa Peer và Chaincode Container
      - CORE_PEER_CHAINCODEADDRESS=peer0.adminorg.docube.com:7052 # Cổng dành riêng cho chaincode kết nối về Peer.
      - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7052
      
      # --- Gossip Protocol (P2P Discovery) ---
      # Gossip giúp các peer tìm thấy nhau và đồng bộ dữ liệu block (đặc biệt khi có nhiều peer/org).
      - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.adminorg.docube.com:7051 # Peer khởi đầu để hỏi thông tin mạng (thường là chính nó nếu chỉ có 1 peer).
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.adminorg.docube.com:7051 # Địa chỉ public mà org khác nhìn thấy peer này.
      
      # --- MSP Configuration ---
      - CORE_PEER_LOCALMSPID=AdminOrgMSP # Rất quan trọng: Xác định Peer này thuộc Org nào để thực thi Policy.
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp # Thư mục chứa Admin certs, CA certs, KeyStore.
      
      # --- Chaincode-as-a-Service (External Builder) ---
      # Cấu hình này cho phép chạy chaincode như một container rời, thay vì Peer tự spawn container docker-in-docker.
      - CHAINCODE_AS_A_SERVICE_BUILDER_CONFIG={"peername":"peer0adminorg"}
      
      # --- Docker Interop ---
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock # Cho phép Peer điều khiển Docker Daemon của máy chủ (để start chaincode).
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=docube_network # Docker network mà chaincode container sẽ join vào.
```
