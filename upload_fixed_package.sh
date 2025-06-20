#!/bin/bash

# =============================================================================
# Script upload package và update GitHub (upload_fixed_package.sh)  
# =============================================================================

set -e

cd /Users/kth/Documents/code/Scripts/vps-management-script

echo "🚀 Upload VPS Management Script Package lên GitHub"
echo "================================================="

# Bước 1: Tạo package
echo ""
echo "📦 Bước 1: Tạo Ubuntu 24.04 package..."
chmod +x create_ubuntu24_package.sh
./create_ubuntu24_package.sh

# Bước 2: Xác định GitHub info
echo ""
echo "📋 Bước 2: Xác định thông tin GitHub"
echo -n "Nhập GitHub username: "
read -r GITHUB_USERNAME

if [[ -z "$GITHUB_USERNAME" ]]; then
    echo "❌ GitHub username không được để trống!"
    exit 1
fi

REPO_NAME="vps-management-script"
PACKAGE_FILE="ubuntu24-lemp-installer.zip"

echo "✅ GitHub username: $GITHUB_USERNAME"
echo "✅ Repository: $REPO_NAME"
echo "✅ Package file: $PACKAGE_FILE"

# Bước 3: Cập nhật các URLs trong scripts
echo ""
echo "🔄 Bước 3: Cập nhật GitHub URLs..."

# Cập nhật main.sh gốc để dùng package
cat > main.sh << EOF
#!/bin/bash

# =============================================================================
# Script Mồi (main.sh) - Updated to use package
# Mục tiêu: Download package đầy đủ và cài đặt LEMP stack
# Version: 1.1 - Fixed dependencies issue
# =============================================================================

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "\${BLUE}[INFO]\${NC} \$1"; }
log_success() { echo -e "\${GREEN}[SUCCESS]\${NC} \$1"; }
log_warning() { echo -e "\${YELLOW}[WARNING]\${NC} \$1"; }
log_error() { echo -e "\${RED}[ERROR]\${NC} \$1"; }

check_root() {
    if [[ \$EUID -ne 0 ]]; then
        log_error "Script này cần được chạy với quyền root!"
        log_info "Vui lòng chạy: sudo \$0 \$*"
        exit 1
    fi
}

check_os() {
    if ! command -v lsb_release &> /dev/null; then
        log_error "Không thể xác định hệ điều hành. Vui lòng cài đặt lsb-release."
        exit 1
    fi
    
    OS_NAME=\$(lsb_release -is)
    OS_VERSION=\$(lsb_release -rs)
    
    log_info "Phát hiện hệ điều hành: \$OS_NAME \$OS_VERSION"
    
    if [[ "\$OS_NAME" == "Ubuntu" && "\$OS_VERSION" == "24.04" ]]; then
        log_success "Hệ điều hành được hỗ trợ!"
        return 0
    else
        log_error "Hệ điều hành không được hỗ trợ!"
        log_info "Script này chỉ hỗ trợ Ubuntu 24.04"
        exit 1
    fi
}

download_and_setup() {
    local package_name="ubuntu24-lemp-installer.zip"
    local download_url="https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/\$package_name"
    
    log_info "Cài đặt dependencies..."
    apt update
    apt install -y unzip curl
    
    log_info "Tải package Ubuntu 24.04 LEMP Installer..."
    
    if curl -sSLf "\$download_url" -o "\$package_name"; then
        log_success "Tải xuống thành công!"
    else
        log_error "Không thể tải package!"
        log_info "Thử clone repository: git clone https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
        exit 1
    fi
    
    log_info "Giải nén và thiết lập..."
    unzip -q "\$package_name"
    cd ubuntu24_package
    chmod +x setup.sh
    ./setup.sh
    
    cd ..
    rm -rf ubuntu24_package "\$package_name"
    
    log_success "Thiết lập hoàn tất!"
}

main() {
    echo "=============================================="
    echo "      VPS Management Script - Launcher       "
    echo "=============================================="
    echo ""
    
    check_root
    check_os
    download_and_setup
    
    log_info "Khởi chạy bộ cài đặt..."
    cd /root/vps-management-script
    ./install_ubt_24.sh "\$@"
}

trap 'log_error "Script bị ngắt bởi người dùng"; exit 1' INT TERM
main "\$@"
EOF

# Cập nhật main_fixed.sh
sed -i '' "s/kh1119/$GITHUB_USERNAME/g" main_fixed.sh

# Cập nhật README.md
sed -i '' "s/kh1119/$GITHUB_USERNAME/g" README.md

echo "✅ Đã cập nhật tất cả GitHub URLs"

# Bước 4: Upload lên GitHub
echo ""
echo "⬆️ Bước 4: Upload lên GitHub..."

# Khởi tạo Git nếu cần
if [[ ! -d ".git" ]]; then
    git init
    git branch -M main
fi

# Remove và add lại remote
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

# Add và commit
git add .
git commit -m "🔧 Fix dependencies issue - Add package-based installer

✨ Changes:
- 📦 Created Ubuntu 24.04 complete package (ubuntu24-lemp-installer.zip)
- 🔧 Updated main.sh to download full package instead of single file
- ✅ Fixed missing config.sh and modules dependencies
- 🚀 Added main_fixed.sh as alternative launcher

🎯 Now includes all required files:
- install_ubt_24.sh + config.sh
- All modules in modules/ubuntu/24/
- Templates and configurations
- Auto setup script

Ready for production! 🎉" || echo "⚠️ Có thể đã commit rồi"

# Push
git push -u origin main

if [[ $? -eq 0 ]]; then
    echo ""
    echo "🎉 Upload thành công!"
    echo ""
    echo "📋 Test commands:"
    echo "1. Package method (recommended):"
    echo "   curl -sSL https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/main.sh | sudo bash"
    echo ""
    echo "2. Fixed method (alternative):"
    echo "   curl -sSL https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/main_fixed.sh | sudo bash"
    echo ""
    echo "3. Manual method:"
    echo "   git clone https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    echo "   cd $REPO_NAME"
    echo "   sudo ./install_ubt_24.sh"
    echo ""
    echo "📦 Package file: $PACKAGE_FILE ($(du -h $PACKAGE_FILE | cut -f1))"
    echo "✅ All dependencies included!"
else
    echo ""
    echo "❌ Lỗi khi push!"
    echo "💡 Có thể cần xác thực GitHub hoặc tạo repository trước"
fi
