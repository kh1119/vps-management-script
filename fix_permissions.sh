#!/bin/bash

# Make this script executable first
chmod +x "$0"

# =============================================================================
# Cấp quyền thực thi cho tất cả scripts (fix_permissions.sh)
# =============================================================================

cd /Users/kth/Documents/code/Scripts/my-super-script

echo "🔧 Cấp quyền thực thi cho tất cả scripts..."

# Cấp quyền cho scripts chính
chmod +x *.sh

# Cấp quyền cho modules
chmod +x modules/ubuntu/24/*.sh 2>/dev/null || true

echo "✅ Đã cấp quyền thực thi!"

echo ""
echo "📋 Scripts có sẵn:"
echo "• ./main.sh                    - Script mồi gốc"
echo "• ./main_offline.sh            - Script mồi offline" 
echo "• ./install_ubt_24.sh          - Script cài đặt chính"
echo "• ./health_check.sh            - Kiểm tra sức khỏe hệ thống"
echo "• ./github_upload_fixed.sh     - Upload lên GitHub (fixed)"
echo "• ./debug_github.sh            - Debug GitHub issues"
echo "• ./prepare_release.sh         - Chuẩn bị release"

echo ""
echo "🚀 Để chạy offline:"
echo "sudo ./main_offline.sh"

echo ""
echo "🔧 Để fix GitHub:"
echo "./github_upload_fixed.sh"
