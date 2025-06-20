#!/bin/bash

# =============================================================================
# Script Mồi Offline (main_offline.sh)
# Chạy được mà không cần download từ GitHub
# =============================================================================

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Hàm hiển thị thông báo
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Hàm kiểm tra quyền root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script này cần được chạy với quyền root!"
        log_info "Vui lòng chạy: sudo $0 $*"
        exit 1
    fi
}

# Hàm kiểm tra hệ điều hành
check_os() {
    if ! command -v lsb_release &> /dev/null; then
        log_error "Không thể xác định hệ điều hành. Vui lòng cài đặt lsb-release."
        exit 1
    fi
    
    OS_NAME=$(lsb_release -is)
    OS_VERSION=$(lsb_release -rs)
    
    log_info "Phát hiện hệ điều hành: $OS_NAME $OS_VERSION"
    
    if [[ "$OS_NAME" == "Ubuntu" && "$OS_VERSION" == "24.04" ]]; then
        log_success "Hệ điều hành được hỗ trợ!"
        return 0
    else
        log_error "Hệ điều hành không được hỗ trợ!"
        log_info "Script này chỉ hỗ trợ Ubuntu 24.04"
        exit 1
    fi
}

# Hàm tải script hoặc sử dụng local
setup_installer() {
    local installer_name="install_ubt_24.sh"
    
    # Kiểm tra file local trước
    if [[ -f "$installer_name" ]]; then
        log_success "Sử dụng file cài đặt local: $installer_name"
        chmod +x "$installer_name"
        return 0
    fi
    
    # Nếu không có local, thử download
    log_info "Tải script cài đặt từ GitHub..."
    
    # Danh sách các GitHub usernames có thể
    local github_urls=(
        "https://raw.githubusercontent.com/kh1119/vps-management-script/main/$installer_name"
        "https://raw.githubusercontent.com/YOUR_USERNAME/vps-management-script/main/$installer_name"
    )
    
    for url in "${github_urls[@]}"; do
        log_info "Thử tải từ: $url"
        
        if command -v curl &> /dev/null; then
            if curl -sSLf "$url" -o "$installer_name" 2>/dev/null; then
                chmod +x "$installer_name"
                log_success "Tải xuống thành công từ GitHub!"
                return 0
            fi
        elif command -v wget &> /dev/null; then
            if wget -q "$url" -O "$installer_name" 2>/dev/null; then
                chmod +x "$installer_name"
                log_success "Tải xuống thành công từ GitHub!"
                return 0
            fi
        fi
    done
    
    # Nếu không tải được, hướng dẫn user
    log_error "Không thể tải script cài đặt!"
    echo ""
    echo "🛠️ Các giải pháp:"
    echo "1. Clone repository đầy đủ:"
    echo "   git clone https://github.com/YOUR_USERNAME/vps-management-script.git"
    echo "   cd vps-management-script"
    echo "   sudo ./install_ubt_24.sh"
    echo ""
    echo "2. Tải file thủ công:"
    echo "   wget https://raw.githubusercontent.com/YOUR_USERNAME/vps-management-script/main/install_ubt_24.sh"
    echo "   chmod +x install_ubt_24.sh"
    echo "   sudo ./install_ubt_24.sh"
    echo ""
    echo "3. Kiểm tra GitHub repository đã public chưa"
    echo ""
    exit 1
}

# Hàm chính
main() {
    echo "=============================================="
    echo "      VPS Management Script - Launcher       "
    echo "            (Offline Compatible)             "
    echo "=============================================="
    echo ""
    
    log_info "Kiểm tra quyền root..."
    check_root
    
    log_info "Kiểm tra hệ điều hành..."
    check_os
    
    log_info "Chuẩn bị script cài đặt..."
    setup_installer
    
    log_info "Khởi chạy bộ cài đặt..."
    ./install_ubt_24.sh "$@"
}

# Xử lý tín hiệu ngắt
trap 'log_error "Script bị ngắt bởi người dùng"; exit 1' INT TERM

# Chạy hàm chính
main "$@"
