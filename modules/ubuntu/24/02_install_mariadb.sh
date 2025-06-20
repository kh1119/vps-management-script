#!/bin/bash

# =============================================================================
# Module 02: Cài đặt MariaDB (02_install_mariadb.sh)
# Mục tiêu: Cài đặt và cấu hình MariaDB với bảo mật cao
# =============================================================================

set -e

# Import cấu hình
source "$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")/config.sh"

log_info "=== BƯỚC 3: CÀI ĐẶT MARIADB ==="

# Cài đặt MariaDB
log_info "Cài đặt MariaDB Server..."
apt install -y mariadb-server mariadb-client

# Tạo mật khẩu root mạnh
MYSQL_ROOT_PASSWORD=$(generate_password 32)
log_info "Tạo mật khẩu root MariaDB..."

# Backup cấu hình gốc
cp /etc/mysql/mariadb.conf.d/50-server.cnf "$BACKUP_DIR/50-server.cnf.bak"

# Cấu hình MariaDB
log_info "Cấu hình MariaDB..."

cat > /etc/mysql/mariadb.conf.d/99-custom.cnf << EOF
[mysqld]
# Basic settings
bind-address = $MYSQL_BIND_ADDRESS
port = $MYSQL_PORT

# Performance tuning
innodb_buffer_pool_size = $(( $(free -m | awk '/^Mem:/{print $2}') * 70 / 100 ))M
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Query cache
query_cache_type = 1
query_cache_size = 32M
query_cache_limit = 1M

# Connections
max_connections = 200
max_user_connections = 150
thread_cache_size = 16

# MyISAM
key_buffer_size = 32M
myisam_sort_buffer_size = 8M

# Logging
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
log_queries_not_using_indexes = 1

# Security
local_infile = 0
skip_show_database

# Character set
character_set_server = utf8mb4
collation_server = utf8mb4_unicode_ci

[mysql]
default_character_set = utf8mb4

[client]
default_character_set = utf8mb4
EOF

# Khởi động lại MariaDB để áp dụng cấu hình
log_info "Khởi động lại MariaDB..."
systemctl restart mariadb

# Đặt mật khẩu root và bảo mật MariaDB
log_info "Thiết lập bảo mật MariaDB..."

# Thiết lập mật khẩu root
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" 2>/dev/null || \
mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWORD');"

# Tạo file .my.cnf cho root để tự động đăng nhập
cat > /root/.my.cnf << EOF
[client]
user=root
password=$MYSQL_ROOT_PASSWORD
EOF

chmod 600 /root/.my.cnf

# Thực hiện mysql_secure_installation tự động
log_info "Thực hiện bảo mật cơ sở dữ liệu..."

mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Tạo database và user cho phpMyAdmin
log_info "Tạo database và user cho phpMyAdmin..."

PMA_PASSWORD=$(generate_password 24)

mysql << EOF
CREATE DATABASE IF NOT EXISTS phpmyadmin DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY '$PMA_PASSWORD';
GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'phpmyadmin'@'localhost';
FLUSH PRIVILEGES;
EOF

# Tạo user backup
log_info "Tạo user backup..."

BACKUP_PASSWORD=$(generate_password 24)

mysql << EOF
CREATE USER IF NOT EXISTS 'backup'@'localhost' IDENTIFIED BY '$BACKUP_PASSWORD';
GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES ON *.* TO 'backup'@'localhost';
FLUSH PRIVILEGES;
EOF

# Enable và start MariaDB
systemctl enable mariadb

# Kiểm tra trạng thái
if systemctl is-active --quiet mariadb; then
    log_success "MariaDB đã được cài đặt và cấu hình thành công!"
    
    # Hiển thị thông tin kết nối
    mysql -e "SELECT VERSION() as 'MariaDB Version';"
    mysql -e "SHOW VARIABLES LIKE 'character_set_server';"
    
else
    log_error "Lỗi khởi động MariaDB!"
    exit 1
fi

# Tạo script backup database
log_info "Tạo script backup database..."

cat > /root/backup_databases.sh << 'EOF'
#!/bin/bash

# Script backup tất cả databases
# Sử dụng: ./backup_databases.sh

BACKUP_DIR="/root/my-super-script/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Tạo thư mục backup
mkdir -p "$BACKUP_DIR"

# Backup tất cả databases
mysqldump --all-databases --single-transaction --routines --triggers > "$BACKUP_DIR/all_databases_$DATE.sql"

# Nén file backup
gzip "$BACKUP_DIR/all_databases_$DATE.sql"

# Xóa backup cũ
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup hoàn tất: $BACKUP_DIR/all_databases_$DATE.sql.gz"
EOF

chmod +x /root/backup_databases.sh

# Thêm cron job backup hàng ngày (2:00 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /root/backup_databases.sh >> /var/log/mysql_backup.log 2>&1") | crontab -

# Ghi thông tin vào credentials file
cat >> "$CREDENTIALS_FILE" << EOF

# MariaDB Configuration
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_HOST=$MYSQL_BIND_ADDRESS
MYSQL_PORT=$MYSQL_PORT
MYSQL_VERSION=$(mysql --version | awk '{print $5}' | cut -d',' -f1)

# phpMyAdmin Database User
PMA_DB_USER=phpmyadmin
PMA_DB_PASSWORD=$PMA_PASSWORD
PMA_DB_NAME=phpmyadmin

# Backup User
BACKUP_DB_USER=backup
BACKUP_DB_PASSWORD=$BACKUP_PASSWORD

# Important Files
MYSQL_CONFIG=/etc/mysql/mariadb.conf.d/99-custom.cnf
MYSQL_ROOT_CNF=/root/.my.cnf
BACKUP_SCRIPT=/root/backup_databases.sh

EOF

log_success "Module MariaDB hoàn tất!"
log_info "Mật khẩu root MariaDB: $MYSQL_ROOT_PASSWORD"
log_info "File cấu hình đăng nhập: /root/.my.cnf"
