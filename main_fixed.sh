#!/bin/bash

# =============================================================================
# Script Mồi Fixed (main_fixed.sh)
# Mục tiêu: Download package đầy đủ thay vì chỉ 1 file
# Author: VPS Management Script
# Version: 1.1 - Fixed dependencies issue
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

# Hàm kiểm tra dependencies
check_dependencies() {
    log_info "Kiểm tra dependencies..."
    
    # Kiểm tra unzip
    if ! command -v unzip &> /dev/null; then
        log_info "Cài đặt unzip..."
        apt update
        apt install -y unzip
    fi
    
    # Kiểm tra curl hoặc wget
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        log_info "Cài đặt curl..."
        apt update
        apt install -y curl
    fi
    
    log_success "Dependencies đã sẵn sàng"
}

# Hàm tải xuống và thiết lập package
download_and_setup_package() {
    local package_name="ubuntu24-lemp-installer.zip"
    local download_url="https://github.com/kh1119/vps-management-script/releases/download/v1.0/$package_name"
    local fallback_url="https://raw.githubusercontent.com/kh1119/vps-management-script/main/$package_name"
    
    log_info "Bắt đầu tải package Ubuntu 24.04 LEMP Installer..."
    
    # Thử download từ releases trước
    local download_success=false
    
    for url in "$download_url" "$fallback_url"; do
        log_info "Thử tải từ: $url"
        
        if command -v curl &> /dev/null; then
            if curl -sSLf "$url" -o "$package_name"; then
                download_success=true
                break
            fi
        elif command -v wget &> /dev/null; then
            if wget -q "$url" -O "$package_name"; then
                download_success=true
                break
            fi
        fi
    done
    
    if [[ "$download_success" == "false" ]]; then
        log_error "Không thể tải package từ GitHub!"
        log_info "Các giải pháp khác:"
        echo "1. Tải thủ công từ: https://github.com/kh1119/vps-management-script"
        echo "2. Clone repository: git clone https://github.com/kh1119/vps-management-script.git"
        echo "3. Chạy script offline nếu có sẵn files"
        exit 1
    fi
    
    # Kiểm tra file đã tải
    if [[ ! -f "$package_name" ]]; then
        log_error "Package không tồn tại sau khi tải!"
        exit 1
    fi
    
    log_success "Tải xuống package thành công!"
    
    # Giải nén package
    log_info "Giải nén package..."
    unzip -q "$package_name"
    
    # Kiểm tra thư mục đã giải nén
    local extracted_dir="ubuntu24_package"
    if [[ ! -d "$extracted_dir" ]]; then
        log_error "Không tìm thấy thư mục sau khi giải nén!"
        exit 1
    fi
    
    # Chạy script setup
    log_info "Thiết lập files..."
    cd "$extracted_dir"
    chmod +x setup.sh
    ./setup.sh
    
    # Dọn dẹp
    cd ..
    rm -rf "$extracted_dir" "$package_name"
    
    log_success "Thiết lập package hoàn tất!"
}

# Hàm chạy cài đặt
run_installer() {
    local target_dir="/root/vps-management-script"
    local installer="$target_dir/install_ubt_24.sh"
    
    if [[ ! -f "$installer" ]]; then
        log_error "Không tìm thấy script cài đặt: $installer"
        exit 1
    fi
    
    log_info "Khởi chạy bộ cài đặt LEMP stack..."
    cd "$target_dir"
    ./install_ubt_24.sh "$@"
}

# Hàm chính
main() {
    echo "=============================================="
    echo "      VPS Management Script - Launcher       "
    echo "              (Fixed Version)                "
    echo "=============================================="
    echo ""
    
    # Kiểm tra quyền root
    log_info "Kiểm tra quyền root..."
    check_root
    
    # Kiểm tra hệ điều hành
    log_info "Kiểm tra hệ điều hành..."
    check_os
    
    # Kiểm tra dependencies
    check_dependencies
    
    # Tải và thiết lập package
    download_and_setup_package
    
    # Chạy cài đặt
    run_installer "$@"
}

# Xử lý tín hiệu ngắt
trap 'log_error "Script bị ngắt bởi người dùng"; exit 1' INT TERM

# Chạy hàm chính
main "$@"
