#!/bin/bash

# =============================================================================
# Module 00: Chuẩn bị hệ thống (00_prepare_system.sh)
# Mục tiêu: Cập nhật hệ thống, cài đặt các gói cơ bản và thiết lập bảo mật
# =============================================================================

set -e

# Import cấu hình
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
source "$SCRIPT_ROOT/config.sh"

log_info "=== BƯỚC 1: CHUẨN BỊ HỆ THỐNG ==="

# Cập nhật hệ thống
log_info "Cập nhật danh sách packages..."
apt update

log_info "Nâng cấp hệ thống..."
apt upgrade -y

# Cài đặt các gói cơ bản
log_info "Cài đặt các gói cơ bản..."
apt install -y "${SYSTEM_PACKAGES[@]}"

# Thêm các PPA cần thiết
log_info "Thêm PPAs..."
for ppa in "${PPAS[@]}"; do
    log_info "Thêm $ppa..."
    add-apt-repository -y "$ppa"
done

# Cập nhật lại sau khi thêm PPA
apt update

# Thiết lập UFW Firewall
log_info "Cấu hình UFW Firewall..."

# Reset UFW về mặc định
ufw --force reset

# Cấu hình chính sách mặc định
ufw default deny incoming
ufw default allow outgoing

# Cho phép SSH trước khi enable
ufw allow 22/tcp

# Cho phép các port khác
for rule in "${UFW_RULES[@]}"; do
    log_info "Cho phép port: $rule"
    ufw allow "$rule"
done

# Kích hoạt UFW
ufw --force enable

log_success "UFW Firewall đã được kích hoạt"

# Thiết lập Fail2Ban
log_info "Cấu hình Fail2Ban..."

# Tạo file cấu hình Fail2Ban cho SSH
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

# Khởi động Fail2Ban
systemctl enable fail2ban
systemctl start fail2ban

log_success "Fail2Ban đã được cấu hình và khởi động"

# Tối ưu hóa kernel parameters
log_info "Tối ưu hóa kernel parameters..."

cat > /etc/sysctl.d/99-custom.conf << 'EOF'
# Network optimizations
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_slow_start_after_idle = 0

# Security
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# File system
fs.file-max = 65535
fs.inotify.max_user_watches = 524288
EOF

# Áp dụng cấu hình
sysctl -p /etc/sysctl.d/99-custom.conf

# Tối ưu hóa limits
log_info "Tối ưu hóa system limits..."

cat > /etc/security/limits.d/99-custom.conf << 'EOF'
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
root soft nofile 65535
root hard nofile 65535
root soft nproc 65535
root hard nproc 65535
www-data soft nofile 65535
www-data hard nofile 65535
EOF

# Tạo thư mục backup nếu chưa có
mkdir -p "$BACKUP_DIR"

# Backup các file cấu hình quan trọng
log_info "Backup các file cấu hình gốc..."
cp /etc/hosts "$BACKUP_DIR/hosts.bak" 2>/dev/null || true
cp /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak" 2>/dev/null || true

# Cấu hình timezone (mặc định Asia/Ho_Chi_Minh)
log_info "Cấu hình timezone..."
timedatectl set-timezone Asia/Ho_Chi_Minh

# Cleanup packages không cần thiết
log_info "Dọn dẹp packages không cần thiết..."
apt autoremove -y
apt autoclean

log_success "Chuẩn bị hệ thống hoàn tất!"

# Ghi log vào credentials file
echo "# VPS Management Script Credentials" > "$CREDENTIALS_FILE"
echo "# Generated on $(date)" >> "$CREDENTIALS_FILE"
echo "" >> "$CREDENTIALS_FILE"

# Set quyền cho file credentials
chmod 600 "$CREDENTIALS_FILE"

log_info "File credentials đã được tạo: $CREDENTIALS_FILE"
