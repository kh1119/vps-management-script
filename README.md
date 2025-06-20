# VPS Management Script

Script tự động hóa quản lý VPS với LEMP Stack (Linux, Nginx, MariaDB, PHP) cho Ubuntu 24.04.

## 🚀 Tính năng chính

### Cài đặt tự động
- ✅ **Nginx** - Web server với cấu hình tối ưu
- ✅ **MariaDB** - Database server với bảo mật cao
- ✅ **PHP 7.4 & 8.3** - Đa phiên bản PHP với PHP-FPM
- ✅ **Redis** - Cache server hiệu suất cao
- ✅ **SSL/TLS** - Certbot cho HTTPS tự động
- ✅ **phpMyAdmin** - Quản lý database qua web
- ✅ **Firewall** - UFW + Fail2Ban bảo mật

### Quản lý website
- 🌐 Tạo/xóa website dễ dàng
- 🔒 Cài đặt SSL tự động
- 📊 Thống kê và giám sát
- 🔄 Chuyển đổi phiên bản PHP
- 💾 Backup tự động

### Bảo mật
- 🛡️ Security headers
- 🚫 Rate limiting
- 🔐 Strong passwords
- 📝 Access logging
- 🔄 Auto SSL renewal

## 📋 Yêu cầu hệ thống

- **OS**: Ubuntu 24.04 LTS
- **RAM**: Tối thiểu 1GB (khuyến nghị 2GB+)
- **Storage**: Tối thiểu 10GB trống
- **Network**: Kết nối Internet ổn định
- **Access**: Quyền root

## 🛠️ Cài đặt nhanh

### ⚡ Nếu gặp lỗi 404

**Nếu lệnh curl trả về lỗi 404, có nghĩa là repository chưa được setup đúng cách.**

**Giải pháp nhanh:**
```bash
# 1. Clone repository về local
git clone https://github.com/YOUR_USERNAME/vps-management-script.git
cd vps-management-script
chmod +x *.sh modules/ubuntu/24/*.sh
sudo ./install_ubt_24.sh

# 2. Hoặc chạy script debug
./debug_github.sh
```

### Phương pháp 1: Script mồi (Khuyến nghị)
```bash
# Tải và chạy script mồi
curl -sSL https://raw.githubusercontent.com/kh1119/vps-management-script/main/main.sh | sudo bash
```

### Phương pháp 2: Clone repository
```bash
# Clone project
git clone https://github.com/kh1119/vps-management-script.git
cd vps-management-script

# Cấp quyền thực thi
chmod +x install_ubt_24.sh

# Chạy cài đặt
sudo ./install_ubt_24.sh
```

### Phương pháp 3: Chế độ im lặng
```bash
# Cài đặt không cần tương tác
sudo ./install_ubt_24.sh --silent
```

## 📖 Hướng dẫn sử dụng

### Sau khi cài đặt

1. **Truy cập thông tin**:
   ```bash
   sudo cat /root/.my_script_credentials
   ```

2. **Quản lý website**:
   ```bash
   sudo ./install_ubt_24.sh  # Chọn menu quản lý website
   ```

3. **Tạo website mới**:
   - Chọn "Quản lý Website" → "Tạo website mới"
   - Nhập domain và cấu hình
   - Tự động tạo cấu hình Nginx + SSL

### Các công cụ command line

```bash
# Chuyển đổi phiên bản PHP
switch-php 8.3

# Kiểm tra trạng thái PHP
php-status

# Tạo SSL certificate
ssl-cert example.com

# Quản lý website
site-manager list

# Thông tin server
server-info

# Giám sát Redis
redis-monitor

# Redis CLI với authentication
redis-cli-auth
```

### Quản lý phpMyAdmin

- **URL**: `http://your-ip/phpmyadmin`
- **User**: root
- **Password**: Xem trong file credentials

## 🗂️ Cấu trúc thư mục

```
/root/vps-management-script/
├── main.sh                     # Script mồi
├── install_ubt_24.sh           # Script cài đặt chính
├── config.sh                   # File cấu hình
├── modules/ubuntu/24/          # Modules cài đặt
│   ├── 00_prepare_system.sh
│   ├── 01_install_nginx.sh
│   ├── 02_install_mariadb.sh
│   ├── 03_install_php.sh
│   ├── 04_install_redis.sh
│   ├── 05_install_tools.sh
│   └── 10_manage_website.sh
├── templates/nginx/            # Templates cấu hình
├── logs/                       # Log files
├── backups/                    # Backup files
└── .installed                  # Marker file

/root/.my_script_credentials    # Thông tin đăng nhập (private)
```

## 🔧 Cấu hình nâng cao

### Tùy chỉnh cấu hình

1. **Chỉnh sửa config.sh** trước khi cài đặt
2. **Thay đổi PHP versions**:
   ```bash
   PHP_VERSIONS=("7.4" "8.1" "8.3")
   ```

3. **Tùy chỉnh Redis**:
   ```bash
   REDIS_MAXMEMORY="512mb"
   REDIS_MAXMEMORY_POLICY="allkeys-lru"
   ```

### Backup và Restore

```bash
# Backup databases (tự động hàng ngày)
/root/backup_databases.sh

# Backup Redis
/root/backup_redis.sh

# Backup website
tar -czf backup.tar.gz /var/www/domain.com
```

## 🚨 Xử lý sự cố

### Kiểm tra logs
```bash
# Script logs
tail -f /root/vps-management-script/logs/script.log

# Nginx logs
tail -f /var/log/nginx/error.log

# PHP logs
tail -f /var/log/php8.3-fpm-errors.log

# MariaDB logs
tail -f /var/log/mysql/error.log
```

### Khởi động lại services
```bash
sudo systemctl restart nginx
sudo systemctl restart mariadb
sudo systemctl restart php8.3-fpm
sudo systemctl restart redis-server
```

### Kiểm tra trạng thái
```bash
sudo systemctl status nginx mariadb php8.3-fpm redis-server
```

## 🔒 Bảo mật

### Thông tin quan trọng
- ✅ Tất cả passwords được tạo ngẫu nhiên
- ✅ File credentials có quyền 600 (chỉ root đọc được)
- ✅ UFW firewall đã được kích hoạt
- ✅ Fail2Ban chống brute force
- ✅ SSL certificates tự động gia hạn

### Khuyến nghị bảo mật
1. **Đổi password SSH**: `passwd root`
2. **Cấu hình SSH key**: Tắt password authentication
3. **Update thường xuyên**: `apt update && apt upgrade`
4. **Giám sát logs**: Kiểm tra logs định kỳ
5. **Backup**: Thiết lập backup tự động

## 📞 Hỗ trợ

### Báo lỗi
- **GitHub Issues**: [Tạo issue mới](https://github.com/kh1119/vps-management-script/issues)
- **Email**: support@yourdomain.com

### FAQ

**Q: Script có hỗ trợ Ubuntu phiên bản khác không?**
A: Hiện tại chỉ hỗ trợ Ubuntu 24.04. Các phiên bản khác đang được phát triển.

**Q: Có thể cài thêm phiên bản PHP khác không?**
A: Có, chỉnh sửa `PHP_VERSIONS` trong `config.sh` trước khi cài đặt.

**Q: Làm sao để gỡ bỏ script?**
A: Chưa có script gỡ bỏ tự động. Cần gỡ bỏ từng service thủ công.

## 📝 Changelog

### v1.0 (2025-06-21)
- 🎉 Phiên bản đầu tiên
- ✨ Hỗ trợ Ubuntu 24.04
- 🚀 LEMP stack hoàn chỉnh
- 🔧 Quản lý website cơ bản
- 🔒 Bảo mật cơ bản

## 📄 License

MIT License - Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

## 🙏 Đóng góp

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

**⭐ Nếu project hữu ích, hãy star để ủng hộ!**
# vps-management-script
