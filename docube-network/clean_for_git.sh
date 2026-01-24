#!/bin/bash
#
# Script để dọn dẹp sạch sẽ toàn bộ file rác/generated
# Chuẩn bị cho việc commit lên Git
#

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "🧹 Đang dọn dẹp mạng Docube..."

# 1. Tắt mạng và xóa volumes/containers
if [ -f "${ROOT_DIR}/network.sh" ]; then
    echo "⬇️  Running network.sh down..."
    "${ROOT_DIR}/network.sh" down
fi

# 2. Xóa các thư mục Generated Artifacts
echo "🗑️  Xóa thư mục generated artifacts..."
rm -rf "${ROOT_DIR}/organizations/peerOrganizations"
rm -rf "${ROOT_DIR}/organizations/ordererOrganizations"
rm -rf "${ROOT_DIR}/channel-artifacts"
rm -rf "${ROOT_DIR}/system-genesis-block"

# 3. Xóa các file tạm và logs
echo "🗑️  Xóa file tạm và logs (log.txt, .tar.gz, .block)..."
find "${ROOT_DIR}" -name "log.txt" -delete
find "${ROOT_DIR}" -name "*.tar.gz" -delete
find "${ROOT_DIR}" -name "*.block" -delete
find "${ROOT_DIR}" -name "tmp" -type d -exec rm -rf {} +

# 4. Xóa chaincode binaries/vendor (không xóa source code)
echo "🗑️  Xóa chaincode binaries..."
rm -rf "${ROOT_DIR}/chaincode/docube-test/vendor"
rm -f "${ROOT_DIR}/chaincode/docube-test/docube-test" 

echo "✅ Dọn dẹp hoàn tất! Thư mục đã sạch để push lên Git."
echo "ℹ️  Lưu ý: Chỉ những file cấu hình gốc (yaml, sh, go) được giữ lại."
