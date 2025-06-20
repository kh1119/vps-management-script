#!/bin/bash

# =============================================================================
# Script Mồi (main.sh)
# Mục tiêu: Kiểm tra môi trường, phân tích tham số và khởi động script cài đặt
# Author: Your Name
# Version: 1.0
# =============================================================================

set -e  # Thoát ngay khi có lỗi

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    
    # Kiểm tra hỗ trợ
    if [[ "$OS_NAME" == "Ubuntu" && "$OS_VERSION" == "24.04" ]]; then
        log_success "Hệ điều hành được hỗ trợ!"
        return 0
    else
        log_error "Hệ điều hành không được hỗ trợ!"
        log_info "Script này chỉ hỗ trợ Ubuntu 24.04"
        exit 1
    fi
}

# Hàm tải xuống script cài đặt
download_installer() {
    local installer_name="install_ubt_24.sh"
    local download_url="https://raw.githubusercontent.com/kh1119/vps-management-script/main/$installer_name"
    
    log_info "Bắt đầu tải bộ cài đặt cho Ubuntu 24.04..."
    
    # Kiểm tra curl hoặc wget
    if command -v curl &> /dev/null; then
        curl -sSL "$download_url" -o "$installer_name"
    elif command -v wget &> /dev/null; then
        wget -q "$download_url" -O "$installer_name"
    else
        log_error "Không tìm thấy curl hoặc wget để tải file!"
        exit 1
    fi
    
    # Kiểm tra file đã tải
    if [[ ! -f "$installer_name" ]]; then
        log_error "Không thể tải file cài đặt!"
        exit 1
    fi
    
    # Gán quyền thực thi
    chmod +x "$installer_name"
    log_success "Tải xuống hoàn tất!"
}

# Hàm chính
main() {
    echo "=============================================="
    echo "      VPS Management Script - Launcher       "
    echo "=============================================="
    echo ""
    
    # Kiểm tra quyền root
    log_info "Kiểm tra quyền root..."
    check_root
    
    # Kiểm tra hệ điều hành
    log_info "Kiểm tra hệ điều hành..."
    check_os
    
    # Tải script cài đặt
    download_installer
    
    # Chạy script cài đặt với các tham số đã truyền
    log_info "Khởi chạy bộ cài đặt..."
    ./install_ubt_24.sh "$@"
}

# Xử lý tín hiệu ngắt
trap 'log_error "Script bị ngắt bởi người dùng"; exit 1' INT TERM

# Chạy hàm chính
main "$@"
