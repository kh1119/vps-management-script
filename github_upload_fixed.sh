#!/bin/bash

# ==========================================# Cập nhật main.sh
sed -i '' "s|https://raw.githubusercontent.com/kh1119/vps-management-script|https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME|g" main.sh

# Cập nhật README.md
sed -i '' "s|https://github.com/kh1119/vps-management-script|https://github.com/$GITHUB_USERNAME/$REPO_NAME|g" README.md
sed -i '' "s|https://raw.githubusercontent.com/kh1119/vps-management-script|https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME|g" README.md

# Cập nhật upload script
sed -i '' "s/GITHUB_USERNAME=\"kh1119\"/GITHUB_USERNAME=\"$GITHUB_USERNAME\"/" upload_to_github.sh==========================
# Script Upload lên GitHub (cập nhật)
# =============================================================================

set -e

echo "🔧 VPS Management Script - GitHub Upload Tool"
echo "=============================================="

# Kiểm tra thông tin GitHub
echo ""
echo "📋 Bước 1: Xác định thông tin GitHub"
echo -n "Nhập GitHub username của bạn: "
read -r GITHUB_USERNAME

if [[ -z "$GITHUB_USERNAME" ]]; then
    echo "❌ GitHub username không được để trống!"
    exit 1
fi

REPO_NAME="vps-management-script"
PROJECT_DIR="/Users/kth/Documents/code/Scripts/my-super-script"

echo "✅ GitHub username: $GITHUB_USERNAME"
echo "✅ Repository name: $REPO_NAME"
echo ""

# Kiểm tra repository có tồn tại không
echo "🔍 Bước 2: Kiểm tra repository trên GitHub"
echo "Vui lòng kiểm tra link này: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo ""
echo -n "Repository đã được tạo chưa? (y/N): "
read -r repo_exists

if [[ ! "$repo_exists" =~ ^[Yy]$ ]]; then
    echo ""
    echo "📝 Vui lòng tạo repository trước:"
    echo "1. Truy cập: https://github.com/new"
    echo "2. Repository name: $REPO_NAME" 
    echo "3. Description: 🚀 Automated VPS Management Script for Ubuntu 24.04 - Complete LEMP Stack Installation & Website Management Tool"
    echo "4. Public repository"
    echo "5. ✅ Add a README file"
    echo "6. Choose MIT license"
    echo "7. Click 'Create repository'"
    echo ""
    echo "Sau khi tạo xong, chạy lại script này."
    exit 0
fi

# Di chuyển vào thư mục project
cd "$PROJECT_DIR"

# Cập nhật GitHub username trong tất cả files
echo "🔄 Bước 3: Cập nhật GitHub URLs..."

# Cập nhật main.sh
sed -i '' "s|https://raw.githubusercontent.com/kh1119/vps-management-script|https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME|g" main.sh

# Cập nhật README.md
sed -i '' "s|https://github.com/kh1119/vps-management-script|https://github.com/$GITHUB_USERNAME/$REPO_NAME|g" README.md
sed -i '' "s|https://raw.githubusercontent.com/kh1119/vps-management-script|https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME|g" README.md

# Cập nhật upload script
sed -i '' "s/GITHUB_USERNAME=\"kth\"/GITHUB_USERNAME=\"$GITHUB_USERNAME\"/" upload_to_github.sh

echo "✅ Đã cập nhật GitHub URLs"

# Kiểm tra Git
if ! command -v git &> /dev/null; then
    echo "❌ Git chưa được cài đặt!"
    echo "💡 Cài đặt Git:"
    echo "   macOS: brew install git"
    echo "   Ubuntu: sudo apt install git"
    exit 1
fi

# Kiểm tra Git config
if [[ -z "$(git config --global user.name)" ]]; then
    echo -n "📝 Nhập Git user name: "
    read -r git_name
    git config --global user.name "$git_name"
fi

if [[ -z "$(git config --global user.email)" ]]; then
    echo -n "📝 Nhập Git email: "
    read -r git_email
    git config --global user.email "$git_email"
fi

# Khởi tạo Git repository nếu chưa có
if [[ ! -d ".git" ]]; then
    echo "📂 Khởi tạo Git repository..."
    git init
    git branch -M main
fi

# Xóa remote cũ nếu có
git remote remove origin 2>/dev/null || true

# Thêm remote mới
echo "🔗 Thêm remote origin..."
git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

# Cấp quyền thực thi
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

Ready for production deployment! 🚀" || echo "⚠️ Có thể đã commit rồi"

# Push lên GitHub
echo "⬆️ Đang push lên GitHub..."
git push -u origin main

if [[ $? -eq 0 ]]; then
    echo ""
    echo "🎉 Upload thành công!"
    echo "🌐 Repository: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
    echo ""
    echo "📋 Test script:"
    echo "curl -sSL https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/main.sh | sudo bash"
    echo ""
    echo "✅ VPS Management Script đã sẵn sàng!"
else
    echo ""
    echo "❌ Lỗi khi push lên GitHub!"
    echo "💡 Có thể cần:"
    echo "1. Xác thực GitHub (personal access token)"
    echo "2. Kiểm tra repository đã được tạo chưa"
    echo "3. Kiểm tra quyền truy cập repository"
fi
