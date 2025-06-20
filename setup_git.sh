#!/bin/bash

# =============================================================================
# Setup Git và chuẩn bị upload (setup_git.sh)
# Chạy script này trước khi upload lên GitHub
# =============================================================================

set -e

PROJECT_DIR="/Users/kth/Documents/code/Scripts/vps-management-script"

echo "🔧 Chuẩn bị Git repository cho VPS Management Script..."

# Di chuyển vào thư mục project
cd "$PROJECT_DIR"

# Cấp quyền thực thi cho tất cả scripts
echo "⚡ Cấp quyền thực thi cho scripts..."
chmod +x *.sh
chmod +x modules/ubuntu/24/*.sh

# Kiểm tra Git đã được cài đặt
if ! command -v git &> /dev/null; then
    echo "❌ Git chưa được cài đặt!"
    echo "💡 Cài đặt Git:"
    echo "   macOS: brew install git"
    echo "   Ubuntu: sudo apt install git"
    exit 1
fi

echo "✅ Git đã sẵn sàng"

# Hiển thị cấu trúc project
echo ""
echo "📁 Cấu trúc project:"
tree -a -I '.DS_Store' || find . -type f -name "*.sh" -o -name "*.md" -o -name "*.conf" | head -20

echo ""
echo "📋 Các bước tiếp theo:"
echo "1. 🌐 Tạo repository 'vps-management-script' trên GitHub"
echo "2. 🚀 Chạy: ./upload_to_github.sh"
echo "3. ✅ Kiểm tra repository trên GitHub"
echo ""

# Kiểm tra các file quan trọng
echo "🔍 Kiểm tra files quan trọng..."
files_to_check=(
    "main.sh"
    "install_ubt_24.sh"
    "config.sh"
    "README.md"
    "modules/ubuntu/24/00_prepare_system.sh"
    "modules/ubuntu/24/01_install_nginx.sh"
    "modules/ubuntu/24/02_install_mariadb.sh"
    "modules/ubuntu/24/03_install_php.sh"
    "modules/ubuntu/24/04_install_redis.sh"
    "modules/ubuntu/24/05_install_tools.sh"
    "modules/ubuntu/24/10_manage_website.sh"
    "templates/nginx/site.conf"
    "health_check.sh"
)

all_files_exist=true
for file in "${files_to_check[@]}"; do
    if [[ -f "$file" ]]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
        all_files_exist=false
    fi
done

if [[ "$all_files_exist" == "true" ]]; then
    echo ""
    echo "🎉 Tất cả files đã sẵn sàng!"
    echo "🚀 Có thể upload lên GitHub!"
else
    echo ""
    echo "⚠️  Một số files bị thiếu. Vui lòng kiểm tra lại."
fi

echo ""
echo "📊 Thống kê project:"
echo "  • Scripts: $(find . -name "*.sh" | wc -l) files"
echo "  • Modules: $(find modules -name "*.sh" | wc -l) files"  
echo "  • Templates: $(find templates -name "*.conf" | wc -l) files"
echo "  • Documentation: $(find . -maxdepth 1 -name "*.md" | wc -l) files"
echo "  • Total files: $(find . -type f | wc -l) files"
