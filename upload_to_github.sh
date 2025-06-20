#!/bin/bash

# =============================================================================
# Script upload lên GitHub
# Hướng dẫn: Chạy script này sau khi tạo repo trên GitHub
# =============================================================================

set -e

# Cấu hình
REPO_NAME="vps-management-script"
GITHUB_USERNAME="kh1119"  # Thay bằng username thực của bạn
PROJECT_DIR="/Users/kth/Documents/code/Scripts/my-super-script"

echo "🚀 Chuẩn bị upload VPS Management Script lên GitHub..."

# Di chuyển vào thư mục project
cd "$PROJECT_DIR"

# Kiểm tra Git đã được cài đặt
if ! command -v git &> /dev/null; then
    echo "❌ Git chưa được cài đặt!"
    exit 1
fi

# Khởi tạo Git repository nếu chưa có
if [[ ! -d ".git" ]]; then
    echo "📂 Khởi tạo Git repository..."
    git init
    git branch -M main
fi

# Thêm remote origin
echo "🔗 Thêm remote origin..."
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

# Cấp quyền thực thi cho các script
echo "🔧 Cấp quyền thực thi..."
find . -name "*.sh" -exec chmod +x {} \;

# Thêm tất cả files
echo "📁 Thêm files vào Git..."
git add .

# Tạo commit
echo "💾 Tạo commit..."
git commit -m "🎉 Initial release: VPS Management Script v1.0

✨ Features:
- 🚀 Automated LEMP stack installation (Nginx + MariaDB + PHP + Redis)
- 🔒 SSL/TLS automation with Certbot
- 🛡️ Security hardening (UFW + Fail2Ban + Security headers)
- 🌐 Website management system
- 📊 Health monitoring and backup automation
- 🔧 Developer tools (Composer, WP-CLI, Node.js)

🎯 Target: Ubuntu 24.04 LTS
🛠️ Architecture: Modular design with 7 installation modules
📚 Documentation: Complete setup and usage guide

Ready for production deployment! 🚀"

# Push lên GitHub
echo "⬆️ Đang push lên GitHub..."
git push -u origin main

echo ""
echo "✅ Upload thành công!"
echo "🌐 Repository: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo ""
echo "📋 Bước tiếp theo:"
echo "1. Truy cập repository trên GitHub"
echo "2. Kiểm tra README.md hiển thị đúng"
echo "3. Tạo release đầu tiên (v1.0)"
echo "4. Test script trên VPS Ubuntu 24.04"
echo ""
echo "🎉 VPS Management Script đã sẵn sàng!"
