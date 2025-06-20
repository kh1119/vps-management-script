#!/bin/bash

# =============================================================================
# Module 10: Quản lý Website (10_manage_website.sh)
# Mục tiêu: Tạo, xóa, liệt kê và quản lý website trên server
# =============================================================================

set -e

# Import cấu hình
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
source "$SCRIPT_ROOT/config.sh"

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Hàm hiển thị menu
show_website_menu() {
    while true; do
        cat << EOF

============================================
           🌐 QUẢN LÝ WEBSITE
============================================

1. 📝 Tạo website mới
2. 📋 Liệt kê tất cả website
3. ✏️  Chỉnh sửa cấu hình website
4. 🔄 Kích hoạt/Vô hiệu hóa website
5. 🔒 Cài đặt SSL cho website
6. 🗑️  Xóa website
7. 📊 Thống kê website
8. 🔙 Quay lại menu chính

EOF

        echo -n "Chọn tùy chọn (1-8): "
        read -r choice
        
        case $choice in
            1) create_website ;;
            2) list_websites ;;
            3) edit_website ;;
            4) toggle_website ;;
            5) install_ssl ;;
            6) delete_website ;;
            7) website_stats ;;
            8) return 0 ;;
            *)
                log_warning "Lựa chọn không hợp lệ!"
                ;;
        esac
    done
}

# Hàm tạo website mới
create_website() {
    log_info "=== TẠO WEBSITE MỚI ==="
    
    # Nhập thông tin website
    echo -n "Nhập tên domain (vd: example.com): "
    read -r domain
    
    # Validate domain
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        log_error "Tên domain không hợp lệ!"
        return 1
    fi
    
    # Kiểm tra domain đã tồn tại chưa
    if [[ -f "/etc/nginx/sites-available/$domain" ]]; then
        log_error "Website $domain đã tồn tại!"
        return 1
    fi
    
    # Chọn phiên bản PHP
    echo ""
    echo "Chọn phiên bản PHP:"
    select php_version in "${PHP_VERSIONS[@]}"; do
        if [[ -n "$php_version" ]]; then
            break
        fi
    done
    
    # Chọn loại website
    echo ""
    echo "Chọn loại website:"
    echo "1. Static HTML"
    echo "2. PHP"
    echo "3. WordPress"
    echo "4. Laravel"
    echo -n "Lựa chọn (1-4): "
    read -r site_type
    
    case $site_type in
        1) site_type_name="static" ;;
        2) site_type_name="php" ;;
        3) site_type_name="wordpress" ;;
        4) site_type_name="laravel" ;;
        *) site_type_name="php" ;;
    esac
    
    # Tạo thư mục website
    web_root="/var/www/$domain"
    mkdir -p "$web_root/public"
    mkdir -p "$web_root/logs"
    
    # Tạo file cấu hình Nginx
    create_nginx_config "$domain" "$php_version" "$site_type_name"
    
    # Tạo nội dung mặc định
    create_default_content "$domain" "$web_root" "$site_type_name"
    
    # Set quyền
    chown -R www-data:www-data "$web_root"
    chmod -R 755 "$web_root"
    
    # Kích hoạt site
    ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
    
    # Test cấu hình Nginx
    if nginx -t; then
        systemctl reload nginx
        log_success "Website $domain đã được tạo thành công!"
        log_info "Đường dẫn: $web_root"
        log_info "URL: http://$domain"
        log_info "PHP Version: $php_version"
        log_info "Loại: $site_type_name"
    else
        log_error "Lỗi cấu hình Nginx!"
        rm -f "/etc/nginx/sites-available/$domain"
        rm -f "/etc/nginx/sites-enabled/$domain"
        rm -rf "$web_root"
        return 1
    fi
    
    # Tạo database nếu cần
    if [[ "$site_type_name" == "wordpress" || "$site_type_name" == "laravel" ]]; then
        create_database "$domain"
    fi
    
    echo ""
    echo -n "Bạn có muốn cài đặt SSL ngay không? (y/N): "
    read -r install_ssl_now
    if [[ "$install_ssl_now" =~ ^[Yy]$ ]]; then
        install_ssl_for_domain "$domain"
    fi
}

# Hàm tạo cấu hình Nginx
create_nginx_config() {
    local domain="$1"
    local php_version="$2"
    local site_type="$3"
    
    local template_file="$TEMPLATES_DIR/nginx/site.conf"
    local config_file="/etc/nginx/sites-available/$domain"
    
    # Copy template và thay thế các biến
    cp "$template_file" "$config_file"
    
    sed -i "s/{{DOMAIN}}/$domain/g" "$config_file"
    sed -i "s/{{WEB_ROOT}}/\/var\/www\/$domain/g" "$config_file"
    sed -i "s/{{PHP_VERSION}}/$php_version/g" "$config_file"
    sed -i "s/{{LOG_PATH}}/\/var\/www\/$domain\/logs/g" "$config_file"
    
    # Thêm cấu hình đặc biệt theo loại site
    case "$site_type" in
        "wordpress")
            add_wordpress_config "$config_file"
            ;;
        "laravel")
            add_laravel_config "$config_file"
            ;;
    esac
}

# Hàm thêm cấu hình WordPress
add_wordpress_config() {
    local config_file="$1"
    
    cat >> "$config_file" << 'EOF'
    
    # WordPress specific configurations
    location = /wp-admin/admin-ajax.php {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php{{PHP_VERSION}}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    location ~* \.(pdf|css|html|js|swf)$ {
        expires 2d;
    }
EOF
}

# Hàm thêm cấu hình Laravel
add_laravel_config() {
    local config_file="$1"
    
    sed -i 's/root \/var\/www\/{{DOMAIN}};/root \/var\/www\/{{DOMAIN}}\/public;/' "$config_file"
    
    cat >> "$config_file" << 'EOF'
    
    # Laravel specific configurations
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    
    error_page 404 /index.php;
EOF
}

# Hàm tạo nội dung mặc định
create_default_content() {
    local domain="$1"
    local web_root="$2"
    local site_type="$3"
    
    case "$site_type" in
        "static")
            create_static_content "$domain" "$web_root"
            ;;
        "php")
            create_php_content "$domain" "$web_root"
            ;;
        "wordpress")
            create_wordpress_content "$domain" "$web_root"
            ;;
        "laravel")
            create_laravel_content "$domain" "$web_root"
            ;;
    esac
}

# Hàm tạo nội dung static
create_static_content() {
    local domain="$1"
    local web_root="$2"
    
    cat > "$web_root/index.html" << EOF
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$domain - Chào mừng</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #333; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Chào mừng đến với $domain!</h1>
        <div class="info">
            <p>Website của bạn đã được tạo thành công.</p>
            <p>Bạn có thể upload file của mình vào thư mục: <code>$web_root</code></p>
        </div>
        <p><small>Được tạo bởi VPS Management Script</small></p>
    </div>
</body>
</html>
EOF
}

# Hàm tạo nội dung PHP
create_php_content() {
    local domain="$1"
    local web_root="$2"
    
    cat > "$web_root/index.php" << EOF
<?php
// Welcome page for $domain
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo '$domain'; ?> - PHP Website</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #333; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .php-info { background: #e8f4fd; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐘 Chào mừng đến với <?php echo '$domain'; ?>!</h1>
        <div class="info">
            <p>Website PHP của bạn đã được tạo thành công.</p>
            <p>Thư mục web: <code>$web_root</code></p>
        </div>
        <div class="php-info">
            <h3>Thông tin PHP:</h3>
            <p>PHP Version: <?php echo PHP_VERSION; ?></p>
            <p>Server Time: <?php echo date('d/m/Y H:i:s'); ?></p>
            <p>Document Root: <?php echo \$_SERVER['DOCUMENT_ROOT']; ?></p>
        </div>
        <p><small>Được tạo bởi VPS Management Script</small></p>
    </div>
</body>
</html>
EOF
}

# Hàm tạo placeholder WordPress
create_wordpress_content() {
    local domain="$1"
    local web_root="$2"
    
    cat > "$web_root/index.php" << EOF
<?php
// WordPress placeholder for $domain
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo '$domain'; ?> - WordPress Ready</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #333; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .command { background: #333; color: #fff; padding: 10px; border-radius: 3px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📝 <?php echo '$domain'; ?> - Sẵn sàng cho WordPress</h1>
        <div class="info">
            <p>Website đã được chuẩn bị cho WordPress.</p>
            <p>Để cài đặt WordPress, chạy lệnh:</p>
            <div class="command">
                cd $web_root && wp core download --locale=vi
            </div>
        </div>
        <p><small>Được tạo bởi VPS Management Script</small></p>
    </div>
</body>
</html>
EOF
}

# Hàm tạo placeholder Laravel
create_laravel_content() {
    local domain="$1"
    local web_root="$2"
    
    mkdir -p "$web_root/public"
    
    cat > "$web_root/public/index.php" << EOF
<?php
// Laravel placeholder for $domain
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo '$domain'; ?> - Laravel Ready</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #333; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .command { background: #333; color: #fff; padding: 10px; border-radius: 3px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 <?php echo '$domain'; ?> - Sẵn sàng cho Laravel</h1>
        <div class="info">
            <p>Website đã được chuẩn bị cho Laravel.</p>
            <p>Để tạo project Laravel mới, chạy lệnh:</p>
            <div class="command">
                cd /var/www && composer create-project laravel/laravel $domain
            </div>
        </div>
        <p><small>Được tạo bởi VPS Management Script</small></p>
    </div>
</body>
</html>
EOF
}

# Hàm tạo database
create_database() {
    local domain="$1"
    local db_name
    local db_user
    local db_password
    
    # Tạo tên database và user từ domain
    db_name=$(echo "$domain" | sed 's/\./_/g' | sed 's/-/_/g')
    db_user="$db_name"
    db_password=$(generate_password 16)
    
    echo ""
    log_info "Tạo database cho website..."
    
    # Tạo database và user
    mysql << EOF
CREATE DATABASE IF NOT EXISTS $db_name DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF

    log_success "Database đã được tạo!"
    log_info "Database: $db_name"
    log_info "User: $db_user"
    log_info "Password: $db_password"
    
    # Lưu thông tin database
    cat >> "$CREDENTIALS_FILE" << EOF

# Database for $domain
${domain//./_}_DB_NAME=$db_name
${domain//./_}_DB_USER=$db_user
${domain//./_}_DB_PASSWORD=$db_password

EOF
}

# Hàm liệt kê website
list_websites() {
    log_info "=== DANH SÁCH WEBSITE ==="
    
    echo ""
    echo "🟢 Website đang hoạt động:"
    if ls /etc/nginx/sites-enabled/ >/dev/null 2>&1; then
        for site in /etc/nginx/sites-enabled/*; do
            if [[ -f "$site" && "$(basename "$site")" != "default" ]]; then
                local domain=$(basename "$site")
                local web_root="/var/www/$domain"
                local status="🟢"
                
                # Kiểm tra SSL
                if grep -q "ssl_certificate" "$site"; then
                    local ssl_status="🔒 SSL"
                else
                    local ssl_status="🔓 No SSL"
                fi
                
                echo "  $domain - $ssl_status - $web_root"
            fi
        done
    else
        echo "  Không có website nào đang hoạt động"
    fi
    
    echo ""
    echo "🔴 Website đã tắt:"
    for site in /etc/nginx/sites-available/*; do
        if [[ -f "$site" ]]; then
            local domain=$(basename "$site")
            if [[ "$domain" != "default" && "$domain" != "phpmyadmin" && ! -L "/etc/nginx/sites-enabled/$domain" ]]; then
                echo "  $domain (disabled)"
            fi
        fi
    done
}

# Hàm cài đặt SSL
install_ssl() {
    echo -n "Nhập domain cần cài SSL: "
    read -r domain
    
    if [[ ! -f "/etc/nginx/sites-available/$domain" ]]; then
        log_error "Website $domain không tồn tại!"
        return 1
    fi
    
    install_ssl_for_domain "$domain"
}

# Hàm cài đặt SSL cho domain
install_ssl_for_domain() {
    local domain="$1"
    
    log_info "Cài đặt SSL cho $domain..."
    
    # Kiểm tra domain có trỏ về server này không
    local server_ip=$(curl -s ifconfig.me)
    local domain_ip=$(dig +short "$domain" A | tail -n1)
    
    if [[ "$server_ip" != "$domain_ip" ]]; then
        log_warning "Domain $domain không trỏ về server này!"
        log_info "Server IP: $server_ip"
        log_info "Domain IP: $domain_ip"
        echo -n "Bạn có muốn tiếp tục? (y/N): "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # Cài đặt SSL certificate
    if certbot --nginx -d "$domain" --non-interactive --agree-tos --email "admin@$domain"; then
        log_success "SSL đã được cài đặt cho $domain!"
        log_info "URL: https://$domain"
    else
        log_error "Lỗi cài đặt SSL cho $domain!"
    fi
}

# Hàm xóa website
delete_website() {
    echo -n "Nhập domain cần xóa: "
    read -r domain
    
    if [[ ! -f "/etc/nginx/sites-available/$domain" ]]; then
        log_error "Website $domain không tồn tại!"
        return 1
    fi
    
    echo ""
    log_warning "⚠️  CẢNH BÁO: Hành động này sẽ xóa hoàn toàn website $domain!"
    echo "Bao gồm:"
    echo "  - File cấu hình Nginx"
    echo "  - Thư mục web (/var/www/$domain)"
    echo "  - Database (nếu có)"
    echo ""
    echo -n "Bạn có chắc chắn muốn xóa? Gõ 'YES' để xác nhận: "
    read -r confirm
    
    if [[ "$confirm" != "YES" ]]; then
        log_info "Hủy bỏ xóa website."
        return 0
    fi
    
    # Xóa SSL certificate nếu có
    if certbot certificates 2>/dev/null | grep -q "$domain"; then
        log_info "Xóa SSL certificate..."
        certbot delete --cert-name "$domain" --non-interactive
    fi
    
    # Tắt site
    rm -f "/etc/nginx/sites-enabled/$domain"
    
    # Xóa cấu hình Nginx
    rm -f "/etc/nginx/sites-available/$domain"
    
    # Backup và xóa thư mục web
    if [[ -d "/var/www/$domain" ]]; then
        log_info "Backup thư mục web..."
        tar -czf "$BACKUP_DIR/website_${domain}_$(date +%Y%m%d_%H%M%S).tar.gz" -C /var/www "$domain"
        rm -rf "/var/www/$domain"
    fi
    
    # Reload Nginx
    nginx -t && systemctl reload nginx
    
    log_success "Website $domain đã được xóa!"
    log_info "Backup được lưu tại: $BACKUP_DIR/"
}

# Hàm toggle website
toggle_website() {
    echo -n "Nhập domain: "
    read -r domain
    
    if [[ ! -f "/etc/nginx/sites-available/$domain" ]]; then
        log_error "Website $domain không tồn tại!"
        return 1
    fi
    
    if [[ -L "/etc/nginx/sites-enabled/$domain" ]]; then
        # Tắt website
        rm "/etc/nginx/sites-enabled/$domain"
        systemctl reload nginx
        log_success "Website $domain đã được tắt"
    else
        # Bật website
        ln -sf "/etc/nginx/sites-available/$domain" "/etc/nginx/sites-enabled/$domain"
        if nginx -t; then
            systemctl reload nginx
            log_success "Website $domain đã được kích hoạt"
        else
            rm "/etc/nginx/sites-enabled/$domain"
            log_error "Lỗi cấu hình Nginx!"
        fi
    fi
}

# Placeholder functions
edit_website() {
    log_info "Chức năng chỉnh sửa website đang được phát triển..."
}

website_stats() {
    log_info "=== THỐNG KÊ WEBSITE ==="
    
    local total_sites=$(ls /etc/nginx/sites-available/ | grep -v default | wc -l)
    local active_sites=$(ls /etc/nginx/sites-enabled/ | grep -v default | wc -l)
    local ssl_sites=$(grep -l "ssl_certificate" /etc/nginx/sites-available/* 2>/dev/null | wc -l)
    
    echo "📊 Tổng quan:"
    echo "  • Tổng số website: $total_sites"
    echo "  • Website đang hoạt động: $active_sites"
    echo "  • Website có SSL: $ssl_sites"
    
    echo ""
    echo "💾 Dung lượng sử dụng:"
    du -sh /var/www/* 2>/dev/null | head -10
}

# Chạy menu chính
show_website_menu
