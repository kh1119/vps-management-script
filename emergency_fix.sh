#!/bin/bash

# =============================================================================
# VPS Management Script - Self-Contained Installer
# Khắc phục lỗi: config.sh not found
# =============================================================================

set -e

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🚨 VPS Management Script - Emergency Fix"
echo "========================================="
echo ""

log_info "Phát hiện lỗi: config.sh not found"
log_info "Đang khắc phục bằng cách clone toàn bộ repository..."

# Cài đặt Git nếu chưa có
if ! command -v git &> /dev/null; then
    log_info "Cài đặt Git..."
    apt update
    apt install -y git
fi

# Clone repository
WORK_DIR="/root/vps-management-script"

if [[ -d "$WORK_DIR" ]]; then
    log_info "Xóa thư mục cũ..."
    rm -rf "$WORK_DIR"
fi

log_info "Clone repository đầy đủ..."

# Thử clone từ các URLs có thể
REPO_URLS=(
    "https://github.com/kh1119/vps-management-script.git"
    "https://github.com/kth/vps-management-script.git"
)

CLONED=false
for url in "${REPO_URLS[@]}"; do
    log_info "Thử clone từ: $url"
    if git clone "$url" "$WORK_DIR" 2>/dev/null; then
        log_success "Clone thành công!"
        CLONED=true
        break
    fi
done

if [[ "$CLONED" == "false" ]]; then
    log_error "Không thể clone repository!"
    log_info "Tạo structure thủ công..."
    
    # Tạo structure cơ bản
    mkdir -p "$WORK_DIR"/{logs,backups,modules/ubuntu/24,templates/nginx}
    
    # Tạo config.sh cơ bản
    cat > "$WORK_DIR/config.sh" << 'EOF'
#!/bin/bash
# Basic config for emergency mode
SCRIPT_NAME="VPS Management Script"
SCRIPT_VERSION="1.0"
SCRIPT_AUTHOR="Emergency Mode"

WORK_DIR="/root/vps-management-script"
LOG_DIR="$WORK_DIR/logs"
BACKUP_DIR="$WORK_DIR/backups"
TEMPLATES_DIR="$WORK_DIR/templates"
MODULES_DIR="$WORK_DIR/modules"

INSTALL_MARKER_FILE="$WORK_DIR/.installed"
CREDENTIALS_FILE="/root/.my_script_credentials"
LOG_FILE="$LOG_DIR/script.log"

PHP_VERSIONS=("7.4" "8.3")
DEFAULT_PHP_VERSION="8.3"

generate_password() {
    local length=${1:-16}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

log_with_timestamp() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

export SCRIPT_NAME SCRIPT_VERSION WORK_DIR LOG_DIR BACKUP_DIR TEMPLATES_DIR MODULES_DIR
export INSTALL_MARKER_FILE CREDENTIALS_FILE LOG_FILE PHP_VERSIONS DEFAULT_PHP_VERSION
EOF
    
    log_success "Đã tạo config.sh cơ bản!"
fi

# Di chuyển vào thư mục và cấp quyền
cd "$WORK_DIR"
find . -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# Chạy installer
if [[ -f "install_ubt_24.sh" ]]; then
    log_success "Khởi chạy installer..."
    ./install_ubt_24.sh "$@"
else
    log_error "Không tìm thấy install_ubt_24.sh"
    log_info "Vui lòng clone repository thủ công:"
    echo "git clone https://github.com/kh1119/vps-management-script.git /root/vps-management-script"
    echo "cd /root/vps-management-script"
    echo "chmod +x *.sh modules/ubuntu/24/*.sh"
    echo "./install_ubt_24.sh"
fi
