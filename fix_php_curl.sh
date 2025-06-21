#!/bin/bash

# =============================================================================
# Fix CURL Functions Disabled in PHP
# Script này sửa lỗi curl_exec() bị disable trong PHP
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo "🔧 Fix PHP CURL Functions Disabled Error"
echo "========================================"

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   log_error "Script này cần quyền root!"
   log_info "Chạy: sudo $0"
   exit 1
fi

# Tìm các file php.ini
PHP_INI_FILES=(
    "/etc/php/7.4/fpm/php.ini"
    "/etc/php/8.3/fpm/php.ini"
    "/etc/php/7.4/cli/php.ini"
    "/etc/php/8.3/cli/php.ini"
)

log_info "Đang kiểm tra và sửa PHP configuration..."

FIXED_COUNT=0
for ini_file in "${PHP_INI_FILES[@]}"; do
    if [[ -f "$ini_file" ]]; then
        log_info "Kiểm tra: $ini_file"
        
        # Backup file gốc
        if [[ ! -f "$ini_file.backup-curl-fix" ]]; then
            cp "$ini_file" "$ini_file.backup-curl-fix"
            log_info "Đã backup: $ini_file.backup-curl-fix"
        fi
        
        # Kiểm tra xem có disable curl_exec không
        if grep -q "curl_exec" "$ini_file"; then
            log_warning "Tìm thấy curl functions bị disable trong $ini_file"
            
            # Sửa disable_functions - remove curl_exec và curl_multi_exec
            sed -i 's/disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source/disable_functions = exec,passthru,shell_exec,system,proc_open,popen,parse_ini_file,show_source/' "$ini_file"
            
            # Enable allow_url_fopen if disabled
            sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/' "$ini_file"
            
            log_success "Đã sửa: $ini_file"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        else
            log_info "OK: $ini_file không có vấn đề curl"
        fi
    else
        log_info "Skip: $ini_file không tồn tại"
    fi
done

if [[ $FIXED_COUNT -gt 0 ]]; then
    log_info "Khởi động lại PHP-FPM và Nginx..."
    
    # Restart PHP-FPM cho các phiên bản
    for version in "7.4" "8.3"; do
        if systemctl is-active --quiet "php$version-fpm"; then
            systemctl restart "php$version-fpm"
            log_success "Đã restart PHP $version FPM"
        fi
    done
    
    # Restart Nginx
    if systemctl is-active --quiet nginx; then
        systemctl restart nginx
        log_success "Đã restart Nginx"
    fi
    
    echo ""
    log_success "✅ Đã sửa $FIXED_COUNT file(s) PHP configuration"
    echo ""
    log_info "🧪 Test CURL:"
    echo "   php -r \"echo extension_loaded('curl') ? 'CURL extension: OK' : 'CURL extension: MISSING'; echo PHP_EOL;\""
    echo "   php -r \"echo function_exists('curl_exec') ? 'curl_exec(): OK' : 'curl_exec(): DISABLED'; echo PHP_EOL;\""
    echo ""
    log_info "📋 Các functions đã được enable:"
    echo "   • curl_exec()"
    echo "   • curl_multi_exec()"
    echo "   • allow_url_fopen"
    echo ""
    log_info "🔒 Các functions vẫn được disable (bảo mật):"
    echo "   • exec(), passthru(), shell_exec(), system()"
    echo "   • proc_open(), popen()"
    echo "   • parse_ini_file(), show_source()"
    
else
    log_success "✅ Không cần sửa gì, PHP configuration đã OK"
fi

echo ""
echo "🎯 Completed! Lỗi curl_exec() đã được khắc phục."
