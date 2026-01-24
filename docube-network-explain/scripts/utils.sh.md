# Utility Script

File chứa các hàm tiện ích logging (in màu) để format output cho dễ đọc.

```bash
#!/usr/bin/env bash
#
# Copyright Docube System. All Rights Reserved.
#

# Định nghĩa các mã màu ANSI
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

# Hàm in hướng dẫn sử dụng (Help)
function printHelp() {
  # ... (Hiển thị các flag và mode hỗ trợ) ...
}

# Các hàm logging helper
function errorln() {
  println "${C_RED}${1}${C_RESET}" # In màu đỏ (Lỗi)
}

function successln() {
  println "${C_GREEN}${1}${C_RESET}" # In màu xanh lá (Thành công)
}

function infoln() {
  println "${C_BLUE}${1}${C_RESET}" # In màu xanh dương (Thông tin)
}

function warnln() {
  println "${C_YELLOW}${1}${C_RESET}" # In màu vàng (Cảnh báo)
}

function fatalln() {
  errorln "$1"
  exit 1 # In lỗi và thoát script ngay lập tức
}
```
