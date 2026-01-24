# Create Channel Script

Script này chịu trách nhiệm tạo channel blockchain và join các peer vào channel đó.

```bash
#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#

# Import các biến môi trường
. ${SCRIPT_DIR}/envVar.sh

# Hàm tạo Genesis Block cho Channel
# Sử dụng configtxgen và profile DocubeChannel đã định nghĩa trong configtx.yaml
createChannelGenesisBlock() {
  setGlobals adminorg # Dùng identity AdminOrg để tạo
  
  infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
  # Tạo block 0 đầu tiên cho channel
  configtxgen -profile DocubeChannel -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
}

# Hàm gửi lệnh tạo channel tới Orderer
createChannel() {
  setGlobals adminorg
  # Sử dụng osnadmin (Orderer Service Node Admin) để join orderer vào channel system
  # Đây là cách mới trong Fabric 2.x (không dùng peer channel create)
  osnadmin channel join --channelID $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block -o localhost:7053 ...
}

# Hàm Join Peer vào Channel
joinChannel() {
  ORG=$1
  setGlobals $ORG # Switch sang identity của Org cần join
  
  # Lệnh peer channel join sẽ đọc genesis block và đồng bộ với Orderer
  peer channel join -b $BLOCKFILE
}

## Main Flow ##

# 1. Tạo Genesis Block
createChannelGenesisBlock

# 2. Tạo Channel (gửi request tới Orderer)
createChannel

# 3. Join AdminOrg Peer
joinChannel adminorg

# 4. Join UserOrg Peer (để UserOrg cũng có ledger)
joinChannel userorg
```
