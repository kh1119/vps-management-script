#!/bin/bash

# =============================================================================
# Script Cài đặt Lõi cho Ubuntu 24.04 (install_ubt_24.sh)
# Mục tiêu: Cài đặt và quản lý toàn bộ LEMP stack trên Ubuntu 24.04
# Author: Your Name
# Version: 1.0
# =============================================================================

set -e  # Thoát ngay khi có lỗi

# Import cấu hình
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Biến toàn cục
SILENT_MODE=false
CURRENT_USER=$(whoami)

# Hàm hiển thị thông báo
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_with_timestamp "[INFO] $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_with_timestamp "[SUCCESS] $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_with_timestamp "[WARNING] $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_with_timestamp "[ERROR] $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
    log_with_timestamp "[STEP] $1"
}

# Hàm xử lý tham số dòng lệnh
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --silent)
                SILENT_MODE=true
                log_info "Chế độ im lặng được kích hoạt"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_warning "Tham số không xác định: $1"
                shift
                ;;
        esac
    done
}

# Hàm hiển thị trợ giúp
show_help() {
    cat << EOF
Sử dụng: $0 [OPTIONS]

OPTIONS:
    --silent    Chạy ở chế độ im lặng (không hỏi người dùng)
    --help, -h  Hiển thị trợ giúp này

Ví dụ:
    $0                  # Chạy ở chế độ tương tác
    $0 --silent         # Chạy ở chế độ im lặng

EOF
}

# Hàm thiết lập logging
setup_logging() {
    # Tạo thư mục logs nếu chưa có
    mkdir -p "$LOG_DIR"
    
    # Redirect output vào file log
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
    
    log_info "Logging được thiết lập: $LOG_FILE"
}

# Hàm kiểm tra điều kiện tiền cài đặt
preflight_checks() {
    log_step "Kiểm tra điều kiện tiền cài đặt"
    
    # Kiểm tra quyền root
    if [[ $EUID -ne 0 ]]; then
        log_error "Script cần được chạy với quyền root!"
        exit 1
    fi
    
    # Kiểm tra Ubuntu version
    if ! grep -q "Ubuntu 24.04" /etc/os-release; then
        log_error "Script chỉ hỗ trợ Ubuntu 24.04"
        exit 1
    fi
    
    # Thu thập thông tin hệ thống
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    CPU_CORES=$(nproc)
    DISK_SPACE=$(df -h / | awk 'NR==2{print $4}')
    
    log_info "Thông tin hệ thống:"
    log_info "  - RAM: ${RAM_GB}GB"
    log_info "  - CPU: ${CPU_CORES} cores"
    log_info "  - Dung lượng trống: ${DISK_SPACE}"
    
    # Kiểm tra RAM tối thiểu (1GB)
    if [[ $RAM_GB -lt 1 ]]; then
        log_warning "RAM thấp (<1GB). Script vẫn tiếp tục nhưng có thể gặp vấn đề."
    fi
    
    log_success "Kiểm tra điều kiện hoàn tất"
}

# Hàm kiểm tra trạng thái cài đặt
check_installation_status() {
    if [[ -f "$INSTALL_MARKER_FILE" ]]; then
        log_info "Phát hiện cài đặt trước đó"
        return 0  # Đã cài đặt
    else
        return 1  # Chưa cài đặt
    fi
}

# Hàm chạy module
run_module() {
    local module_name="$1"
    local module_path="$MODULES_DIR/ubuntu/24/$module_name"
    
    if [[ -f "$module_path" ]]; then
        log_step "Chạy module: $module_name"
        bash "$module_path"
        log_success "Module $module_name hoàn tất"
    else
        log_error "Không tìm thấy module: $module_path"
        exit 1
    fi
}

# Menu cài đặt ban đầu
show_installation_menu() {
    cat << EOF

============================================
      VPS Management Script v$SCRIPT_VERSION
============================================

Chào mừng bạn đến với script quản lý VPS!
Script này sẽ cài đặt LEMP stack hoàn chỉnh bao gồm:

📦 Các thành phần sẽ được cài đặt:
  • Nginx (Web server)
  • MariaDB (Database server) 
  • PHP 7.4 & 8.3 (with PHP-FPM)
  • Redis (Caching server)
  • Certbot (SSL certificates)
  • phpMyAdmin (Database management)
  • UFW Firewall (Security)

⚠️  Lưu ý quan trọng:
  • Script cần kết nối Internet để tải packages
  • Quá trình cài đặt có thể mất 10-15 phút
  • Tất cả cấu hình sẽ được backup tự động

EOF

    if [[ "$SILENT_MODE" == "false" ]]; then
        echo -n "Bạn có muốn tiếp tục cài đặt? (y/N): "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Cài đặt đã bị hủy bởi người dùng"
            exit 0
        fi
    fi
}

# Menu quản lý (sau khi đã cài đặt)
show_management_menu() {
    while true; do
        cat << EOF

============================================
      VPS Management - Menu Quản lý
============================================

1. 🌐 Quản lý Website
2. 🗄️  Quản lý Database  
3. 🔒 Quản lý SSL Certificate
4. 📊 Xem trạng thái hệ thống
5. 🔧 Cấu hình nâng cao
6. 📋 Xem logs
7. 🔄 Cập nhật script
8. ❌ Thoát

EOF

        echo -n "Chọn tùy chọn (1-8): "
        read -r choice
        
        case $choice in
            1) run_module "10_manage_website.sh" ;;
            2) manage_database ;;
            3) manage_ssl ;;
            4) show_system_status ;;
            5) advanced_config ;;
            6) show_logs ;;
            7) update_script ;;
            8) 
                log_info "Tạm biệt!"
                exit 0
                ;;
            *)
                log_warning "Lựa chọn không hợp lệ!"
                ;;
        esac
    done
}

# Hàm cài đặt chính
main_installation() {
    log_step "Bắt đầu quá trình cài đặt LEMP stack"
    
    # Giai đoạn 1: Chuẩn bị hệ thống
    run_module "00_prepare_system.sh"
    
    # Giai đoạn 2: Cài đặt Nginx
    run_module "01_install_nginx.sh"
    
    # Giai đoạn 3: Cài đặt MariaDB
    run_module "02_install_mariadb.sh"
    
    # Giai đoạn 4: Cài đặt PHP
    run_module "03_install_php.sh"
    
    # Giai đoạn 5: Cài đặt Redis
    run_module "04_install_redis.sh"
    
    # Giai đoạn 6: Cài đặt Tools
    run_module "05_install_tools.sh"
    
    # Đánh dấu đã cài đặt xong
    touch "$INSTALL_MARKER_FILE"
    
    # Hiển thị thông tin tóm tắt
    show_installation_summary
    
    log_success "🎉 Cài đặt hoàn tất! LEMP stack đã sẵn sàng sử dụng."
}

# Hàm hiển thị tóm tắt sau cài đặt
show_installation_summary() {
    local mysql_root_password
    mysql_root_password=$(grep "MYSQL_ROOT_PASSWORD" "$CREDENTIALS_FILE" | cut -d'=' -f2)
    
    cat << EOF

============================================
        📋 THÔNG TIN CÀI ĐẶT
============================================

🌐 Web Server: Nginx đã được cài đặt và khởi động
🗄️  Database: MariaDB với mật khẩu root đã được tạo
🐘 PHP: Phiên bản 7.4 và 8.3 đã sẵn sàng
⚡ Redis: Server caching đã được cấu hình
🔒 SSL: Certbot đã sẵn sàng cho HTTPS
🛡️  Firewall: UFW đã được kích hoạt

📁 Thông tin đăng nhập:
  • File credentials: $CREDENTIALS_FILE
  • MariaDB root password: $mysql_root_password
  • phpMyAdmin: http://your-ip/phpmyadmin

📂 Đường dẫn quan trọng:
  • Web root: /var/www/html
  • Nginx config: /etc/nginx/sites-available/
  • PHP config: /etc/php/*/fpm/php.ini
  • Logs: $LOG_DIR

⚠️  Lưu ý bảo mật:
  • Hãy đổi mật khẩu mặc định
  • Cấu hình SSL cho domain của bạn
  • Thường xuyên cập nhật hệ thống

============================================

EOF
}

# Placeholder functions (sẽ được implement sau)
manage_database() {
    log_info "Chức năng quản lý database đang được phát triển..."
}

manage_ssl() {
    log_info "Chức năng quản lý SSL đang được phát triển..."
}

show_system_status() {
    log_info "Hiển thị trạng thái hệ thống..."
    systemctl status nginx mariadb php*-fpm redis-server --no-pager
}

advanced_config() {
    log_info "Cấu hình nâng cao đang được phát triển..."
}

show_logs() {
    log_info "Hiển thị 50 dòng cuối của log..."
    tail -50 "$LOG_FILE"
}

update_script() {
    log_info "Chức năng cập nhật script đang được phát triển..."
}

# Hàm chính
main() {
    # Thiết lập logging
    setup_logging
    
    # Phân tích tham số
    parse_arguments "$@"
    
    # Kiểm tra điều kiện tiền cài đặt
    preflight_checks
    
    # Kiểm tra trạng thái cài đặt
    if check_installation_status; then
        # Đã cài đặt - hiển thị menu quản lý
        show_management_menu
    else
        # Chưa cài đặt - bắt đầu cài đặt
        show_installation_menu
        main_installation
    fi
}

# Xử lý tín hiệu ngắt
trap 'log_error "Script bị ngắt bởi người dùng"; exit 1' INT TERM

# Chạy hàm chính
main "$@"
