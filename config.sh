#!/bin/bash

# =============================================================================
# File cấu hình trung tâm (config.sh)
# Chứa các thiết lập mặc định và cấu hình cho chế độ silent
# =============================================================================

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1" >&2
    fi
}

# Cấu hình cơ bản
SCRIPT_NAME="VPS Management Script"
SCRIPT_VERSION="1.0"
SCRIPT_AUTHOR="Your Name"

# Thư mục làm việc
WORK_DIR="/root/vps-management-script"
LOG_DIR="$WORK_DIR/logs"
BACKUP_DIR="$WORK_DIR/backups"
TEMPLATES_DIR="$WORK_DIR/templates"
MODULES_DIR="$WORK_DIR/modules"

# File quan trọng
INSTALL_MARKER_FILE="$WORK_DIR/.installed"
CREDENTIALS_FILE="/root/.my_script_credentials"
LOG_FILE="$LOG_DIR/script.log"

# Cấu hình MariaDB (cho chế độ silent)
DEFAULT_MYSQL_ROOT_PASSWORD=""  # Sẽ được tạo tự động
MYSQL_BIND_ADDRESS="127.0.0.1"
MYSQL_PORT="3306"

# Cấu hình Nginx
NGINX_USER="www-data"
NGINX_WORKER_PROCESSES="auto"
NGINX_WORKER_CONNECTIONS="1024"

# Cấu hình PHP
PHP_VERSIONS=("7.4" "8.3")
DEFAULT_PHP_VERSION="8.3"

# Extensions PHP cần thiết
PHP_EXTENSIONS=(
    "cli"
    "fpm"
    "mysql"
    "curl"
    "gd"
    "mbstring"
    "xml"
    "zip"
    "bcmath"
    "soap"
    "intl"
    "readline"
    "ldap"
    "msgpack"
    "igbinary"
    "redis"
    "memcached"
    "imagick"
)

# Cấu hình Redis
REDIS_PORT="6379"
REDIS_BIND_ADDRESS="127.0.0.1"
REDIS_MAXMEMORY="256mb"
REDIS_MAXMEMORY_POLICY="allkeys-lru"

# Cấu hình UFW Firewall
UFW_RULES=(
    "22/tcp"    # SSH
    "80/tcp"    # HTTP
    "443/tcp"   # HTTPS
)

# Cấu hình PHPMyAdmin
PMA_BLOWFISH_SECRET=""  # Sẽ được tạo tự động
PMA_TEMP_DIR="/tmp"
PMA_UPLOAD_DIR="/tmp"

# Cấu hình SSL
SSL_COUNTRY="VN"
SSL_STATE="Ho Chi Minh"
SSL_CITY="Ho Chi Minh City"
SSL_ORG="Your Organization"
SSL_EMAIL="admin@yourdomain.com"

# Cấu hình backup
BACKUP_RETENTION_DAYS="7"
BACKUP_COMPRESSION="gzip"

# Cấu hình bảo mật
SECURE_HEADERS_ENABLED="true"
RATE_LIMITING_ENABLED="true"
FAIL2BAN_ENABLED="true"

# Packages cần thiết
SYSTEM_PACKAGES=(
    "curl"
    "wget"
    "unzip"
    "git"
    "htop"
    "nano"
    "vim"
    "tree"
    "ncdu"
    "software-properties-common"
    "apt-transport-https"
    "ca-certificates"
    "gnupg"
    "lsb-release"
    "ufw"
    "fail2ban"
)

# PPAs cần thêm (có thể để trống nếu không cần)
PPAS=(
    "ppa:ondrej/php"
    # "ppa:ondrej/nginx"  # Ubuntu 24.04 đã có nginx mới, comment out để dùng repo mặc định
)

# Hàm tạo mật khẩu ngẫu nhiên
generate_password() {
    local length=${1:-16}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Hàm tạo secret key cho PHPMyAdmin
generate_blowfish_secret() {
    openssl rand -base64 32 | tr -d "=+/"
}

# Hàm kiểm tra tồn tại của package
package_exists() {
    dpkg -l | grep -q "^ii  $1 "
}

# Hàm kiểm tra service đang chạy
service_running() {
    systemctl is-active --quiet "$1"
}

# Hàm log với timestamp
log_with_timestamp() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Export các biến để modules có thể sử dụng
export SCRIPT_NAME SCRIPT_VERSION SCRIPT_AUTHOR
export WORK_DIR LOG_DIR BACKUP_DIR TEMPLATES_DIR MODULES_DIR
export INSTALL_MARKER_FILE CREDENTIALS_FILE LOG_FILE
export DEFAULT_MYSQL_ROOT_PASSWORD MYSQL_BIND_ADDRESS MYSQL_PORT
export NGINX_USER NGINX_WORKER_PROCESSES NGINX_WORKER_CONNECTIONS
export PHP_VERSIONS DEFAULT_PHP_VERSION PHP_EXTENSIONS
export REDIS_PORT REDIS_BIND_ADDRESS REDIS_MAXMEMORY REDIS_MAXMEMORY_POLICY
export UFW_RULES PMA_BLOWFISH_SECRET PMA_TEMP_DIR PMA_UPLOAD_DIR
export SSL_COUNTRY SSL_STATE SSL_CITY SSL_ORG SSL_EMAIL
export BACKUP_RETENTION_DAYS BACKUP_COMPRESSION
export SECURE_HEADERS_ENABLED RATE_LIMITING_ENABLED FAIL2BAN_ENABLED
export SYSTEM_PACKAGES PPAS

# Helper function để import config.sh từ bất kỳ đâu
load_config() {
    local script_path="$1"
    local config_path=""
    
    # Nếu được gọi từ module (3 levels deep)
    if [[ "$script_path" =~ modules/ubuntu/[0-9]+/ ]]; then
        config_path="$(dirname "$(dirname "$(dirname "$script_path")")")/config.sh"
    # Nếu được gọi từ root directory
    else
        config_path="$(dirname "$script_path")/config.sh"
    fi
    
    if [[ -f "$config_path" ]]; then
        source "$config_path"
        log_debug "Config loaded from: $config_path"
    else
        echo "ERROR: Cannot find config.sh at $config_path" >&2
        exit 1
    fi
}

# Đánh dấu config đã được load
export CONFIG_LOADED="true"
