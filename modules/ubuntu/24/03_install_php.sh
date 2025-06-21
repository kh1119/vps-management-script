#!/bin/bash

# =============================================================================
# Module 03: Cài đặt PHP (03_install_php.sh)
# Mục tiêu: Cài đặt đa phiên bản PHP (7.4, 8.3) với các extension cần thiết
# =============================================================================

set -e

# Import cấu hình
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
source "$SCRIPT_ROOT/config.sh"

log_info "=== BƯỚC 4: CÀI ĐẶT PHP ==="

# Cài đặt các phiên bản PHP
for version in "${PHP_VERSIONS[@]}"; do
    log_info "Cài đặt PHP $version và extensions..."
    
    # Tạo danh sách packages cho phiên bản này
    packages=()
    for ext in "${PHP_EXTENSIONS[@]}"; do
        packages+=("php$version-$ext")
    done
    
    # Cài đặt PHP và extensions
    apt install -y "${packages[@]}"
    
    log_success "PHP $version đã được cài đặt!"
done

# Cấu hình PHP-FPM cho từng phiên bản
for version in "${PHP_VERSIONS[@]}"; do
    log_info "Cấu hình PHP $version-FPM..."
    
    # Backup cấu hình gốc
    cp "/etc/php/$version/fpm/php.ini" "$BACKUP_DIR/php$version-fpm.ini.bak"
    cp "/etc/php/$version/fpm/pool.d/www.conf" "$BACKUP_DIR/php$version-fpm-www.conf.bak"
    
    # Cấu hình php.ini
    cat > "/etc/php/$version/fpm/conf.d/99-custom.ini" << EOF
; Custom PHP Configuration
; Performance
memory_limit = 256M
max_execution_time = 300
max_input_time = 300
max_input_vars = 3000

; File uploads
upload_max_filesize = 128M
post_max_size = 128M
file_uploads = On

; Error reporting
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php$version-fpm-errors.log

; Session
session.gc_maxlifetime = 3600
session.cookie_httponly = 1
session.cookie_secure = 0
session.use_strict_mode = 1

; Security
expose_php = Off
allow_url_fopen = On
allow_url_include = Off
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,parse_ini_file,show_source

; Date
date.timezone = Asia/Ho_Chi_Minh

; OPcache
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
opcache.validate_timestamps = 1

; Realpath cache
realpath_cache_size = 4096K
realpath_cache_ttl = 600
EOF

    # Cấu hình pool www.conf
    sed -i "s/;listen.owner = www-data/listen.owner = www-data/" "/etc/php/$version/fpm/pool.d/www.conf"
    sed -i "s/;listen.group = www-data/listen.group = www-data/" "/etc/php/$version/fpm/pool.d/www.conf"
    sed -i "s/;listen.mode = 0660/listen.mode = 0660/" "/etc/php/$version/fpm/pool.d/www.conf"
    
    # Tối ưu hóa process manager
    cat >> "/etc/php/$version/fpm/pool.d/www.conf" << EOF

; Performance tuning
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 1000

; Slow log
slowlog = /var/log/php$version-fpm-slow.log
request_slowlog_timeout = 10s

; Status page
pm.status_path = /status
ping.path = /ping
EOF

    # Enable và start PHP-FPM
    systemctl enable "php$version-fpm"
    systemctl restart "php$version-fpm"
    
    # Kiểm tra trạng thái
    if systemctl is-active --quiet "php$version-fpm"; then
        log_success "PHP $version-FPM đã được cấu hình và khởi động thành công!"
    else
        log_error "Lỗi khởi động PHP $version-FPM!"
        exit 1
    fi
done

# Đặt phiên bản PHP mặc định
log_info "Đặt PHP $DEFAULT_PHP_VERSION làm phiên bản mặc định..."
update-alternatives --set php "/usr/bin/php$DEFAULT_PHP_VERSION"

# Tạo info page cho từng phiên bản PHP
for version in "${PHP_VERSIONS[@]}"; do
    mkdir -p "/var/www/html/php$version"
    cat > "/var/www/html/php$version/info.php" << EOF
<?php
// PHP $version Info Page
// CHỈ dùng để test - hãy xóa sau khi kiểm tra

// Security check
if (!in_array(\$_SERVER['REMOTE_ADDR'], ['127.0.0.1', '::1'])) {
    die('Access denied');
}

echo "<h1>PHP $version Information</h1>";
phpinfo();
?>
EOF
done

# Tạo Nginx configuration cho từng phiên bản PHP
log_info "Tạo cấu hình Nginx cho các phiên bản PHP..."

for version in "${PHP_VERSIONS[@]}"; do
    cat > "/etc/nginx/sites-available/php$version" << EOF
server {
    listen 80;
    server_name php$version.local;
    root /var/www/html/php$version;
    index index.php index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$version-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
done

# Tạo script để chuyển đổi phiên bản PHP
log_info "Tạo script chuyển đổi phiên bản PHP..."

cat > /usr/local/bin/switch-php << 'EOF'
#!/bin/bash

# Script chuyển đổi phiên bản PHP mặc định
# Sử dụng: switch-php 8.3

if [[ $# -ne 1 ]]; then
    echo "Sử dụng: $0 <version>"
    echo "Ví dụ: $0 8.3"
    exit 1
fi

VERSION="$1"

if [[ ! -f "/usr/bin/php$VERSION" ]]; then
    echo "Lỗi: PHP $VERSION chưa được cài đặt!"
    exit 1
fi

# Chuyển đổi phiên bản mặc định
update-alternatives --set php "/usr/bin/php$VERSION"

echo "✅ Đã chuyển PHP mặc định sang phiên bản $VERSION"
php --version
EOF

chmod +x /usr/local/bin/switch-php

# Tạo script kiểm tra trạng thái PHP
cat > /usr/local/bin/php-status << 'EOF'
#!/bin/bash

# Script kiểm tra trạng thái các phiên bản PHP
echo "=== Trạng thái PHP Services ==="

for version in 7.4 8.3; do
    if systemctl is-active --quiet "php$version-fpm"; then
        status="🟢 Running"
    else
        status="🔴 Stopped"
    fi
    
    echo "PHP $version-FPM: $status"
done

echo ""
echo "=== PHP Default Version ==="
php --version | head -1

echo ""
echo "=== PHP-FPM Processes ==="
ps aux | grep php-fpm | grep -v grep
EOF

chmod +x /usr/local/bin/php-status

# Tạo logrotate cho PHP logs
cat > /etc/logrotate.d/php-fpm << 'EOF'
/var/log/php*-fpm*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 www-data adm
    sharedscripts
    postrotate
        systemctl reload php7.4-fpm php8.3-fpm
    endscript
}
EOF

# Set quyền cho log files
touch /var/log/php7.4-fpm-errors.log /var/log/php8.3-fpm-errors.log
touch /var/log/php7.4-fpm-slow.log /var/log/php8.3-fpm-slow.log
chown www-data:adm /var/log/php*-fpm*.log
chmod 640 /var/log/php*-fpm*.log

# Ghi thông tin vào credentials file
cat >> "$CREDENTIALS_FILE" << EOF

# PHP Configuration
PHP_VERSIONS_INSTALLED=(${PHP_VERSIONS[*]})
PHP_DEFAULT_VERSION=$DEFAULT_PHP_VERSION

# PHP-FPM Socket Paths
$(for version in "${PHP_VERSIONS[@]}"; do
    echo "PHP${version//.}_FPM_SOCKET=/var/run/php/php$version-fpm.sock"
done)

# PHP Tools
PHP_SWITCH_TOOL=/usr/local/bin/switch-php
PHP_STATUS_TOOL=/usr/local/bin/php-status

# PHP Configuration Paths
$(for version in "${PHP_VERSIONS[@]}"; do
    echo "PHP${version//.}_INI_PATH=/etc/php/$version/fpm/php.ini"
    echo "PHP${version//.}_POOL_PATH=/etc/php/$version/fpm/pool.d/www.conf"
done)

EOF

log_success "Module PHP hoàn tất!"
log_info "Phiên bản PHP mặc định: $DEFAULT_PHP_VERSION"
log_info "Các công cụ có sẵn:"
log_info "  - switch-php <version>  : Chuyển đổi phiên bản PHP"
log_info "  - php-status           : Kiểm tra trạng thái PHP"

# Hiển thị thông tin PHP đã cài đặt
echo ""
echo "=== Thông tin PHP đã cài đặt ==="
for version in "${PHP_VERSIONS[@]}"; do
    echo "PHP $version: $(/usr/bin/php$version --version | head -1)"
done
