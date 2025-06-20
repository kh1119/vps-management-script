#!/bin/bash

# =============================================================================
# VPS Management Script - All-in-One Installer
# Chứa tất cả code cần thiết trong một file duy nhất
# Version: 1.0
# =============================================================================

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Biến cấu hình
SCRIPT_NAME="VPS Management Script"
SCRIPT_VERSION="1.0"
WORK_DIR="/root/vps-management-script"
LOG_DIR="$WORK_DIR/logs"
BACKUP_DIR="$WORK_DIR/backups"
CREDENTIALS_FILE="/root/.my_script_credentials"
LOG_FILE="$LOG_DIR/script.log"

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

# Hàm log với timestamp
log_with_timestamp() {
    mkdir -p "$LOG_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE" >/dev/null
}

# Hàm tạo mật khẩu ngẫu nhiên
generate_password() {
    local length=${1:-16}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Hàm kiểm tra quyền root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script cần được chạy với quyền root!"
        exit 1
    fi
}

# Hàm kiểm tra hệ điều hành
check_os() {
    if ! grep -q "Ubuntu 24.04" /etc/os-release; then
        log_error "Script chỉ hỗ trợ Ubuntu 24.04"
        exit 1
    fi
    log_success "Ubuntu 24.04 được hỗ trợ"
}

# Hàm thiết lập logging
setup_logging() {
    mkdir -p "$LOG_DIR" "$BACKUP_DIR"
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
    log_info "Logging được thiết lập: $LOG_FILE"
}

# Hàm cài đặt packages cơ bản
install_basic_packages() {
    log_step "Cài đặt packages cơ bản..."
    
    apt update
    apt upgrade -y
    
    local packages=(
        "curl" "wget" "unzip" "git" "htop" "nano" "vim" "tree"
        "software-properties-common" "apt-transport-https" 
        "ca-certificates" "gnupg" "lsb-release" "ufw" "fail2ban"
    )
    
    apt install -y "${packages[@]}"
    
    # Thêm PPAs
    add-apt-repository -y ppa:ondrej/php
    add-apt-repository -y ppa:ondrej/nginx-mainline
    apt update
    
    log_success "Packages cơ bản đã được cài đặt"
}

# Hàm cấu hình firewall
setup_firewall() {
    log_step "Cấu hình UFW Firewall..."
    
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    local rules=("22/tcp" "80/tcp" "443/tcp")
    for rule in "${rules[@]}"; do
        ufw allow "$rule"
    done
    
    ufw --force enable
    
    # Cấu hình Fail2Ban
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban
    
    log_success "Firewall đã được cấu hình"
}

# Hàm cài đặt Nginx
install_nginx() {
    log_step "Cài đặt Nginx..."
    
    apt install -y nginx
    
    # Backup cấu hình gốc
    cp /etc/nginx/nginx.conf "$BACKUP_DIR/nginx.conf.bak"
    
    # Cấu hình Nginx tối ưu
    cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=general:10m rate=5r/s;
    
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    # Tạo trang welcome
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VPS Management Script - Welcome</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #333; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 15px 35px rgba(0,0,0,0.1); max-width: 600px; }
        h1 { color: #2c3e50; margin-bottom: 20px; }
        .success { color: #27ae60; font-size: 18px; margin: 20px 0; }
        .info { background: #ecf0f1; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .services { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin: 20px 0; }
        .service { background: #3498db; color: white; padding: 15px; border-radius: 5px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Chào mừng bạn!</h1>
        <div class="success">✅ LEMP Stack đã được cài đặt thành công!</div>
        <div class="info">
            <h3>Các dịch vụ đã được cài đặt:</h3>
            <div class="services">
                <div class="service">🌐 Nginx</div>
                <div class="service">🗄️ MariaDB</div>
                <div class="service">🐘 PHP</div>
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
        </div>
    </div>
</body>
</html>
EOF

    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    systemctl enable nginx
    systemctl restart nginx
    
    log_success "Nginx đã được cài đặt và cấu hình"
}

# Hàm cài đặt MariaDB
install_mariadb() {
    log_step "Cài đặt MariaDB..."
    
    apt install -y mariadb-server mariadb-client
    
    # Tạo mật khẩu root
    local mysql_root_password=$(generate_password 32)
    
    # Cấu hình MariaDB
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$mysql_root_password';" 2>/dev/null || \
    mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$mysql_root_password');"
    
    # Tạo file .my.cnf cho root
    cat > /root/.my.cnf << EOF
[client]
user=root
password=$mysql_root_password
EOF
    chmod 600 /root/.my.cnf
    
    # Bảo mật MariaDB
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -e "FLUSH PRIVILEGES;"
    
    systemctl enable mariadb
    
    # Ghi password vào credentials
    echo "MYSQL_ROOT_PASSWORD=$mysql_root_password" >> "$CREDENTIALS_FILE"
    
    log_success "MariaDB đã được cài đặt và bảo mật"
}

# Hàm cài đặt PHP
install_php() {
    log_step "Cài đặt PHP..."
    
    local php_versions=("7.4" "8.3")
    local php_extensions=("cli" "fpm" "mysql" "curl" "gd" "mbstring" "xml" "zip" "bcmath" "soap" "intl")
    
    for version in "${php_versions[@]}"; do
        log_info "Cài đặt PHP $version..."
        
        local packages=()
        for ext in "${php_extensions[@]}"; do
            packages+=("php$version-$ext")
        done
        
        apt install -y "${packages[@]}"
        
        # Cấu hình PHP
        cat > "/etc/php/$version/fpm/conf.d/99-custom.ini" << 'EOF'
memory_limit = 256M
max_execution_time = 300
upload_max_filesize = 128M
post_max_size = 128M
display_errors = Off
log_errors = On
date.timezone = Asia/Ho_Chi_Minh
opcache.enable = 1
opcache.memory_consumption = 128
EOF

        systemctl enable "php$version-fpm"
        systemctl restart "php$version-fpm"
    done
    
    # Đặt PHP 8.3 làm mặc định
    update-alternatives --set php /usr/bin/php8.3
    
    log_success "PHP đã được cài đặt và cấu hình"
}

# Hàm cài đặt Redis
install_redis() {
    log_step "Cài đặt Redis..."
    
    apt install -y redis-server
    
    local redis_password=$(generate_password 32)
    
    # Cấu hình Redis
    sed -i "s/# requirepass foobared/requirepass $redis_password/" /etc/redis/redis.conf
    sed -i "s/# maxmemory <bytes>/maxmemory 256mb/" /etc/redis/redis.conf
    sed -i "s/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/" /etc/redis/redis.conf
    
    systemctl enable redis-server
    systemctl restart redis-server
    
    # Cài đặt PHP Redis extension
    for version in 7.4 8.3; do
        apt install -y "php$version-redis"
        systemctl restart "php$version-fpm"
    done
    
    # Ghi password vào credentials
    echo "REDIS_PASSWORD=$redis_password" >> "$CREDENTIALS_FILE"
    
    log_success "Redis đã được cài đặt và cấu hình"
}

# Hàm cài đặt Certbot
install_certbot() {
    log_step "Cài đặt Certbot..."
    
    apt install -y certbot python3-certbot-nginx
    
    # Tạo script tự động gia hạn SSL
    cat > /root/ssl_renewal.sh << 'EOF'
#!/bin/bash
certbot renew --quiet --nginx
systemctl reload nginx
EOF
    chmod +x /root/ssl_renewal.sh
    
    # Thêm cron job
    (crontab -l 2>/dev/null; echo "0 4 * * * /root/ssl_renewal.sh") | crontab -
    
    log_success "Certbot đã được cài đặt"
}

# Hàm cài đặt các tools
install_tools() {
    log_step "Cài đặt các tools bổ sung..."
    
    # Composer
    cd /tmp
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    
    # WP-CLI
    curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    
    # Node.js
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt install -y nodejs
    
    log_success "Tools đã được cài đặt"
}

# Hàm hiển thị tóm tắt
show_summary() {
    local mysql_password=$(grep "MYSQL_ROOT_PASSWORD" "$CREDENTIALS_FILE" | cut -d'=' -f2)
    local redis_password=$(grep "REDIS_PASSWORD" "$CREDENTIALS_FILE" | cut -d'=' -f2)
    local server_ip=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    
    cat << EOF

============================================
        📋 THÔNG TIN CÀI ĐẶT
============================================

🌐 Web Server: http://$server_ip
🗄️  Database: MariaDB với mật khẩu root đã được tạo
🐘 PHP: Phiên bản 7.4 và 8.3 đã sẵn sàng
⚡ Redis: Server caching đã được cấu hình
🔒 SSL: Certbot đã sẵn sàng cho HTTPS
🛡️  Firewall: UFW đã được kích hoạt

📁 Thông tin đăng nhập:
  • File credentials: $CREDENTIALS_FILE
  • MariaDB root password: $mysql_password
  • Redis password: $redis_password

📂 Đường dẫn quan trọng:
  • Web root: /var/www/html
  • Nginx config: /etc/nginx/sites-available/
  • Logs: $LOG_DIR

⚠️  Lưu ý bảo mật:
  • Hãy backup file credentials: $CREDENTIALS_FILE
  • Cấu hình SSL cho domain của bạn
  • Thường xuyên cập nhật hệ thống

============================================

EOF

    # Set quyền cho credentials file
    chmod 600 "$CREDENTIALS_FILE"
}

# Hàm chính
main() {
    echo "=============================================="
    echo "    VPS Management Script - All-in-One      "
    echo "=============================================="
    echo ""
    
    # Kiểm tra điều kiện
    check_root
    check_os
    setup_logging
    
    log_info "Bắt đầu cài đặt LEMP stack..."
    
    # Cài đặt từng thành phần
    install_basic_packages
    setup_firewall
    install_nginx
    install_mariadb
    install_php
    install_redis
    install_certbot
    install_tools
    
    # Tạo marker file
    touch "$WORK_DIR/.installed"
    
    show_summary
    
    log_success "🎉 Cài đặt hoàn tất! LEMP stack đã sẵn sàng sử dụng."
    
    echo ""
    echo "🚀 Bạn có thể:"
    echo "  • Truy cập: http://$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
    echo "  • Tạo SSL: certbot --nginx -d your-domain.com"
    echo "  • Xem logs: tail -f $LOG_FILE"
    echo "  • Kiểm tra services: systemctl status nginx mariadb php8.3-fpm redis-server"
}

# Xử lý tín hiệu ngắt
trap 'log_error "Script bị ngắt bởi người dùng"; exit 1' INT TERM

# Chạy hàm chính
main "$@"
