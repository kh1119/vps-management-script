#!/bin/bash

# =============================================================================
# Fix Nginx URL Rewriting for Existing Installations
# Sửa cấu hình Nginx để hỗ trợ URL rewriting đúng cách
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

echo "🔧 Fix Nginx URL Rewriting"
echo "=========================="

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   log_error "Script này cần quyền root!"
   log_info "Chạy: sudo $0"
   exit 1
fi

# Backup directory
BACKUP_DIR="/root/nginx-rewrite-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

log_info "Backup sẽ được lưu tại: $BACKUP_DIR"

# Find all enabled sites
SITES_DIR="/etc/nginx/sites-enabled"
FIXED_COUNT=0

if [[ ! -d "$SITES_DIR" ]]; then
    log_error "Thư mục $SITES_DIR không tồn tại!"
    exit 1
fi

log_info "Đang kiểm tra và sửa cấu hình Nginx..."

# Process each site config
for site_config in "$SITES_DIR"/*; do
    if [[ -f "$site_config" ]]; then
        site_name=$(basename "$site_config")
        log_info "Xử lý: $site_name"
        
        # Backup original
        cp "$site_config" "$BACKUP_DIR/$site_name.backup"
        
        # Check if rewriting is already properly configured
        if grep -q "try_files.*index\.php.*query_string" "$site_config"; then
            log_success "✅ $site_name: URL rewriting đã được cấu hình đúng"
            continue
        fi
        
        # Check if basic try_files exists but needs fixing
        if grep -q "try_files.*=404" "$site_config"; then
            log_warning "🔧 $site_name: Cần sửa try_files"
            
            # Fix try_files directive
            sed -i 's/try_files $uri $uri\/ =404;/try_files $uri $uri\/ \/index.php?$query_string;/' "$site_config"
            FIXED_COUNT=$((FIXED_COUNT + 1))
            log_success "✅ Đã sửa try_files cho $site_name"
            
        elif grep -q "location \/ {" "$site_config"; then
            log_warning "🔧 $site_name: Thêm try_files directive"
            
            # Add try_files to existing location / block
            sed -i '/location \/ {/a\        try_files $uri $uri\/ \/index.php?$query_string;' "$site_config"
            FIXED_COUNT=$((FIXED_COUNT + 1))
            log_success "✅ Đã thêm try_files cho $site_name"
        else
            log_warning "⚠️  $site_name: Không tìm thấy location / block, cần kiểm tra thủ công"
        fi
        
        # Enhance PHP handling if needed
        if grep -q "location ~ \.php\$" "$site_config" && ! grep -q "fastcgi_buffer_size" "$site_config"; then
            log_info "🔧 $site_name: Cải thiện PHP handling"
            
            # Add enhanced PHP configuration
            sed -i '/include fastcgi_params;/a\        \n\        # Enhanced PHP security and performance\n        fastcgi_hide_header X-Powered-By;\n        fastcgi_param SERVER_NAME $host;\n        fastcgi_param HTTPS $https if_not_empty;\n        fastcgi_read_timeout 300;\n        fastcgi_connect_timeout 300;\n        fastcgi_send_timeout 300;\n        fastcgi_buffer_size 128k;\n        fastcgi_buffers 256 16k;\n        fastcgi_busy_buffers_size 256k;\n        fastcgi_temp_file_write_size 256k;' "$site_config"
            
            log_success "✅ Đã cải thiện PHP handling cho $site_name"
        fi
    fi
done

# Test nginx configuration
log_info "Kiểm tra cấu hình Nginx..."
if nginx -t; then
    log_success "✅ Nginx configuration hợp lệ"
    
    # Reload nginx
    log_info "Reload Nginx..."
    systemctl reload nginx
    log_success "✅ Nginx đã được reload"
    
else
    log_error "❌ Nginx configuration có lỗi!"
    log_warning "🔄 Khôi phục từ backup..."
    
    # Restore from backup
    for backup_file in "$BACKUP_DIR"/*.backup; do
        if [[ -f "$backup_file" ]]; then
            site_name=$(basename "$backup_file" .backup)
            cp "$backup_file" "$SITES_DIR/$site_name"
            log_info "Khôi phục: $site_name"
        fi
    done
    
    log_warning "Đã khôi phục cấu hình gốc"
    exit 1
fi

echo ""
echo "🎯 **Kết quả:**"
echo "============="
if [[ $FIXED_COUNT -gt 0 ]]; then
    log_success "✅ Đã sửa $FIXED_COUNT site(s)"
    echo ""
    echo "📋 **URL Rewriting đã được enable cho:**"
    echo "• WordPress: /post-name/"
    echo "• Laravel: /api/users/123"
    echo "• CodeIgniter: /controller/method/param"
    echo "• Custom routes: /category/subcategory"
    echo ""
    echo "🧪 **Test URL rewriting:**"
    echo "sudo ./test_nginx_rewrite.sh"
    echo ""
    echo "💾 **Backup location:**"
    echo "$BACKUP_DIR"
else
    log_success "✅ Tất cả sites đã được cấu hình đúng"
fi

echo ""
echo "📖 **Common rewrite patterns:**"
echo "• WordPress: try_files \$uri \$uri/ /index.php?\$args;"
echo "• Laravel: try_files \$uri \$uri/ /index.php?\$query_string;"
echo "• Drupal: try_files \$uri /index.php?\$query_string;"
echo ""
echo "🔧 **Manual check:**"
echo "• Config files: /etc/nginx/sites-enabled/"
echo "• Error logs: /var/log/nginx/error.log"
echo "• Access logs: /var/log/nginx/access.log"
echo ""
