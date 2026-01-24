# Network Management Script

Đây là script chính (EntryPoint) để quản lý vòng đời mạng blockchain. Nó kết nối các script con khác để thực hiện các tác vụ Up, Down, Create Channel.

```bash
#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#

# Script quản lý Docube Network:
# - Điều phối việc tạo certs (crypto)
# - Khởi động container (docker-compose)
# - Tạo channel (createChannel.sh)

ROOTDIR=$(cd "$(dirname "$0")" && pwd)
export PATH=${ROOTDIR}/../bin:${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

# ... helper functions ...

# Hàm tạo Certificates (Crypto Material)
# Gọi cryptogen với các file cấu hình tương ứng cho 3 orgs
function createOrgs() {
  # Xóa certs cũ
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  # Tạo certs cho AdminOrg, UserOrg, OrdererOrg
  cryptogen generate --config=./organizations/cryptogen/crypto-config-adminorg.yaml --output="organizations"
  cryptogen generate --config=./organizations/cryptogen/crypto-config-userorg.yaml --output="organizations"
  cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
}

# Hàm khởi động mạng
function networkUp() {
  checkPrereqs
  # Tạo certs nếu chưa có
  if [ ! -d "organizations/peerOrganizations" ]; then
    createOrgs
  fi

  # Chạy Docker Compose
  COMPOSE_FILES="-f compose/${COMPOSE_FILE_BASE} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_BASE}"
  ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} up -d 2>&1
}

# Hàm tạo Channel
# Gọi script createChannel.sh để thực hiện các bước tạo block và join peer
function createChannel() {
  # ... check network running ...
  scripts/createChannel.sh $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE
}

# Hàm tắt mạng và dọn dẹp
function networkDown() {
  # ... docker compose down ...
  # Xóa volumes docker và các artifacts đã tạo (certs, blocks)
}

# ... (Parsing arguments và gọi hàm tương ứng) ...
```
