#!/bin/bash

# =============================================================================
# Module 01: Cài đặt Nginx (01_install_nginx.sh)
# Mục tiêu: Cài đặt và cấu hình Nginx với các tối ưu hóa bảo mật
# =============================================================================

set -e

# Import cấu hình
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
source "$SCRIPT_ROOT/config.sh"

log_info "=== BƯỚC 2: CÀI ĐẶT NGINX ==="
# Tạo thư mục 
mkdir -p "/home/__all/public_html" "/home/__all/logs" "/home/__all/private_html"

# Cài đặt Nginx
log_info "Cài đặt Nginx..."
apt install -y nginx

# Backup cấu hình gốc
log_info "Backup cấu hình Nginx gốc..."
cp /etc/nginx/nginx.conf "$BACKUP_DIR/nginx.conf.bak"

# Tạo cấu hình Nginx tối ưu
log_info "Cấu hình Nginx..."

cat > /etc/nginx/nginx.conf << EOF
user $NGINX_USER;
worker_processes $NGINX_WORKER_PROCESSES;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections $NGINX_WORKER_CONNECTIONS;
    use epoll;
    multi_accept on;
}

http {
    ##
    # Basic Settings
    ##
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # Buffer sizes
    client_body_buffer_size 128k;
    client_max_body_size 128m;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;
    output_buffers 1 32k;
    postpone_output 1460;
    
    # Timeouts
    client_header_timeout 3m;
    client_body_timeout 3m;
    send_timeout 3m;
    
    # Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # MIME types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ##
    # SSL Settings
    ##
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    ##
    # Logging Settings
    ##
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    ##
    # Rate Limiting
    ##
    limit_req_zone \$binary_remote_addr zone=login:10m rate=10r/m;
    limit_req_zone \$binary_remote_addr zone=api:10m rate=1r/s;
    limit_req_zone \$binary_remote_addr zone=general:10m rate=5r/s;

    ##
    # Virtual Host Configs
    ##
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

# Tạo site mặc định với security headers
log_info "Tạo site mặc định..."

cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /home/__all/public_html;
    index index.php index.html index.htm index.nginx-debian.html;
    
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Hide Nginx version
    server_tokens off;
    
    # Rate limiting
    limit_req zone=general burst=20 nodelay;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # PHP handling
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    # Deny access to .htaccess files
    location ~ /\.ht {
        deny all;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Security
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
}
EOF

# Tạo trang welcome
log_info "Tạo trang welcome..."

cat > /home/__all/public_html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VPS Management Script - Welcome</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 600px;
        }
        h1 {
            color: #2c3e50;
            margin-bottom: 20px;
        }
        .success {
            color: #27ae60;
            font-size: 18px;
            margin: 20px 0;
        }
        .info {
            background: #ecf0f1;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .services {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .service {
            background: #3498db;
            color: white;
            padding: 15px;
            border-radius: 5px;
            font-weight: bold;
        }
        .footer {
            margin-top: 30px;
            font-size: 14px;
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Chào mừng bạn!</h1>
        <div class="success">
            ✅ LEMP Stack đã được cài đặt thành công!
        </div>
        
        <div class="info">
            <h3>Các dịch vụ đã được cài đặt:</h3>
            <div class="services">
                <div class="service">🌐 Nginx</div>
                <div class="service">🗄️ MariaDB</div>
                <div class="service">🐘 PHP 7.4 & 8.3</div>
                <div class="service">⚡ Redis</div>
                <div class="service">🔒 SSL Ready</div>
                <div class="service">🛡️ Security</div>
            </div>
        </div>
        
        <div class="info">
            <h3>📋 Bước tiếp theo:</h3>
            <p>• Tạo website với script quản lý</p>
            <p>• Cấu hình SSL cho domain</p>
            <p>• Upload source code của bạn</p>
            <p>• Quản lý database qua phpMyAdmin</p>
        </div>
        
        <div class="footer">
            Được tạo bởi VPS Management Script<br>
            <?php echo date('d/m/Y H:i:s'); ?>
        </div>
    </div>
</body>
</html>
EOF

# Tạo file PHP info
cat > /home/__all/public_html/info.php << 'EOF'
<?php
// Trang thông tin PHP - CHỈ dùng để test
// Hãy xóa file này sau khi kiểm tra xong

// Security check
if (!in_array($_SERVER['REMOTE_ADDR'], ['127.0.0.1', '::1'])) {
    die('Access denied');
}

phpinfo();
?>
EOF

# Set quyền cho web directory
chown -R www-data:www-data /home/__all/public_html
chmod -R 755 /home/__all/public_html

# Test cấu hình Nginx
log_info "Kiểm tra cấu hình Nginx..."
nginx -t

# Khởi động và enable Nginx
log_info "Khởi động Nginx..."
systemctl enable nginx
systemctl restart nginx

# Kiểm tra trạng thái
if systemctl is-active --quiet nginx; then
    log_success "Nginx đã được cài đặt và khởi động thành công!"
    log_info "Truy cập: http://$(hostname -I | awk '{print $1}')"
else
    log_error "Lỗi khởi động Nginx!"
    exit 1
fi

# Ghi thông tin vào credentials
cat >> "$CREDENTIALS_FILE" << EOF

# Nginx Configuration
NGINX_VERSION=$(nginx -v 2>&1 | cut -d' ' -f3)
NGINX_CONFIG_PATH=/etc/nginx/nginx.conf
NGINX_SITES_PATH=/etc/nginx/sites-available
NGINX_LOG_PATH=/var/log/nginx
WEB_ROOT=/home/__all/public_html

EOF

log_success "Module Nginx hoàn tất!"
