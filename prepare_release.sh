#!/bin/bash

# Make this script executable first
chmod +x "$0"

# =============================================================================
# Script chuẩn bị cuối cùng trước khi upload (prepare_release.sh)
# =============================================================================

set -e

PROJECT_DIR="/Users/kth/Documents/code/Scripts/my-super-script"
cd "$PROJECT_DIR"

echo "🚀 Chuẩn bị VPS Management Script v1.0 cho release..."

# Cấp quyền thực thi cho tất cả scripts
echo "⚡ Cấp quyền thực thi..."
find . -name "*.sh" -exec chmod +x {} \;

# Tạo file CONTRIBUTORS.md
cat > CONTRIBUTORS.md << 'EOF'
# Contributors

Cảm ơn tất cả những người đã đóng góp cho VPS Management Script! 🎉

## 👨‍💻 Core Team

- **kth** - Project Creator & Lead Developer
  - Initial architecture and implementation
  - LEMP stack automation
  - Security hardening
  - Website management system

## 🤝 Contributors

<!-- Add contributors here -->
_Danh sách sẽ được cập nhật khi có đóng góp từ cộng đồng_

## 🙏 Special Thanks

- **Ubuntu Team** - Cho hệ điều hành tuyệt vời
- **Nginx Team** - Web server hiệu suất cao
- **MariaDB Foundation** - Database engine mạnh mẽ
- **PHP Community** - Ngôn ngữ web phổ biến
- **Redis Labs** - Cache solution tốt nhất
- **Let's Encrypt** - SSL miễn phí cho mọi người

## 🤖 Tools & Services

- **GitHub** - Code hosting và collaboration
- **Certbot** - SSL automation
- **Fail2Ban** - Security protection
- **UFW** - Firewall management

---

Want to contribute? Check out [CONTRIBUTING.md](CONTRIBUTING.md)!
EOF

# Kiểm tra tất cả files quan trọng
echo ""
echo "🔍 Kiểm tra files..."

required_files=(
    "main.sh"
    "install_ubt_24.sh" 
    "config.sh"
    "health_check.sh"
    "setup_git.sh"
    "upload_to_github.sh"
    "README.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "CONTRIBUTORS.md"
    "LICENSE"
    ".gitignore"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
        missing_files+=("$file")
    fi
done

# Kiểm tra modules
echo ""
echo "🔧 Kiểm tra modules..."
modules=(
    "modules/ubuntu/24/00_prepare_system.sh"
    "modules/ubuntu/24/01_install_nginx.sh"
    "modules/ubuntu/24/02_install_mariadb.sh"
    "modules/ubuntu/24/03_install_php.sh"
    "modules/ubuntu/24/04_install_redis.sh"
    "modules/ubuntu/24/05_install_tools.sh"
    "modules/ubuntu/24/10_manage_website.sh"
)

for module in "${modules[@]}"; do
    if [[ -f "$module" ]]; then
        echo "  ✅ $module"
    else
        echo "  ❌ $module (missing)"
        missing_files+=("$module")
    fi
done

# Kiểm tra templates
echo ""
echo "📋 Kiểm tra templates..."
if [[ -f "templates/nginx/site.conf" ]]; then
    echo "  ✅ templates/nginx/site.conf"
else
    echo "  ❌ templates/nginx/site.conf (missing)"
    missing_files+=("templates/nginx/site.conf")
fi

# Tạo summary
echo ""
echo "📊 Project Summary:"
echo "  • Scripts: $(find . -name "*.sh" | wc -l) files"
echo "  • Modules: $(find modules -name "*.sh" 2>/dev/null | wc -l) files"
echo "  • Templates: $(find templates -name "*.conf" 2>/dev/null | wc -l) files"
echo "  • Documentation: $(find . -maxdepth 1 -name "*.md" | wc -l) files"
echo "  • Total size: $(du -sh . | cut -f1)"

# Kiểm tra kết quả
if [[ ${#missing_files[@]} -eq 0 ]]; then
    echo ""
    echo "🎉 Tất cả files đã sẵn sàng!"
    echo ""
    echo "📋 Các bước tiếp theo:"
    echo "1. 🌐 Tạo repository 'vps-management-script' trên GitHub"
    echo "   - Repository name: vps-management-script"
    echo "   - Description: 🚀 Automated VPS Management Script for Ubuntu 24.04 - Complete LEMP Stack Installation & Website Management Tool"
    echo "   - Public repository"
    echo "   - Add README file"
    echo "   - Choose MIT license"
    echo ""
    echo "2. 🔧 Cập nhật GitHub username trong upload_to_github.sh"
    echo "   - Sửa GITHUB_USERNAME=\"kth\" thành username thực của bạn"
    echo ""
    echo "3. 🚀 Upload lên GitHub:"
    echo "   ./upload_to_github.sh"
    echo ""
    echo "4. 🏷️ Tạo release v1.0 trên GitHub"
    echo ""
    echo "5. 🧪 Test script trên VPS Ubuntu 24.04:"
    echo "   curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/vps-management-script/main/main.sh | sudo bash"
    echo ""
    echo "✨ VPS Management Script v1.0 đã sẵn sàng cho production!"
else
    echo ""
    echo "⚠️ Các files sau đây bị thiếu:"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Vui lòng tạo các files này trước khi upload!"
fi

echo ""
echo "🎯 Quick Commands:"
echo "  Setup Git: ./setup_git.sh"
echo "  Upload: ./upload_to_github.sh"
echo "  Health Check: ./health_check.sh"
