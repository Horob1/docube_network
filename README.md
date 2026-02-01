# docube_network

## Kiểm tra docker
```bash
docker version
docker ps
```

## Cài đặt dependencies
```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
  curl \
  git \
  jq \
  build-essential \
  ca-certificates \
  gnupg \
  lsb-release
```

## Cài đặt go
```bash
wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

go version
```

## Cài đặt node js
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

node -v
npm -v
```

## Cài đặt hyperledger fabric
```bash
cd ~
git clone https://github.com/hyperledger/fabric-samples.git
cd fabric-samples

curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.6

echo 'export PATH=$PATH:$HOME/fabric-samples/bin' >> ~/.bashrc
source ~/.bashrc
```