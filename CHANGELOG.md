# Changelog

Tất cả các thay đổi quan trọng của dự án sẽ được ghi lại trong file này.

Định dạng dựa trên [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
và dự án tuân thủ [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- 🔧 **PHP CURL Error**: Fixed `curl_exec()` function disabled in PHP configuration
  - Removed `curl_exec` and `curl_multi_exec` from disable_functions
  - Enabled `allow_url_fopen` for HTTP operations  
  - Created `fix_php_curl.sh` script for existing installations
  - Balanced security vs functionality in PHP config

### Planned
- Hỗ trợ Ubuntu 22.04
- Cài đặt PostgreSQL option
- Docker container support
- Automatic backup to cloud storage
- Web interface cho quản lý
- Multi-server management

## [1.0.0] - 2025-06-21

### Added
- ✨ **Script mồi (main.sh)**: Kiểm tra môi trường và tải script cài đặt
- ✨ **Cài đặt tự động LEMP stack** cho Ubuntu 24.04:
  - Nginx với cấu hình tối ưu và security headers
  - MariaDB với bảo mật cao và tối ưu hóa performance
  - PHP 7.4 & 8.3 với PHP-FPM
  - Redis server với cấu hình caching
  - phpMyAdmin với bảo mật nâng cao
- ✨ **Hệ thống quản lý website**:
  - Tạo website mới với templates
  - Hỗ trợ static HTML, PHP, WordPress, Laravel
  - Quản lý SSL certificates với Certbot
  - Kích hoạt/tắt website
  - Xóa website với backup tự động
- ✨ **Bảo mật toàn diện**:
  - UFW Firewall với rules tối ưu
  - Fail2Ban chống brute force
  - SSL/TLS tự động với Let's Encrypt
  - Security headers cho Nginx
  - Rate limiting
  - Strong password generation
- ✨ **Công cụ quản lý**:
  - switch-php: Chuyển đổi phiên bản PHP
  - php-status: Kiểm tra trạng thái PHP
  - ssl-cert: Tạo SSL certificate
  - site-manager: Quản lý website
  - server-info: Thông tin server
  - redis-monitor: Giám sát Redis
  - redis-cli-auth: Redis CLI với authentication
- ✨ **Backup tự động**:
  - Database backup hàng ngày
  - Redis backup hàng ngày
  - Website backup khi xóa
  - Log rotation tự động
- ✨ **Logging & Monitoring**:
  - Chi tiết log cho tất cả hoạt động
  - Structured logging với timestamp
  - Error tracking
  - Performance monitoring
- ✨ **Developer tools**:
  - Composer
  - WP-CLI
  - Node.js & npm
  - Git configuration

### Security
- 🔒 **Mật khẩu mạnh**: Tất cả passwords được tạo ngẫu nhiên 16-32 chars
- 🔒 **File permissions**: Credentials file có quyền 600
- 🔒 **Service hardening**: SystemD security directives
- 🔒 **Network security**: Firewall rules và fail2ban
- 🔒 **SSL/TLS**: Automatic HTTPS với strong ciphers
- 🔒 **Application security**: Security headers, rate limiting
- 🔒 **Database security**: Secure installation, restricted access

### Performance
- ⚡ **Nginx optimization**: Worker processes, caching, compression
- ⚡ **PHP-FPM tuning**: Process management, opcache
- ⚡ **MariaDB optimization**: InnoDB tuning, query cache
- ⚡ **Redis caching**: Memory optimization, persistence
- ⚡ **System tuning**: Kernel parameters, limits

### Documentation
- 📚 **README.md**: Hướng dẫn chi tiết cài đặt và sử dụng
- 📚 **Inline comments**: Code được comment đầy đủ
- 📚 **Error messages**: Thông báo lỗi rõ ràng
- 📚 **Help system**: Built-in help cho tất cả tools

### Configuration
- ⚙️ **Modular design**: Modules riêng biệt cho từng service
- ⚙️ **Configurable**: Central config file
- ⚙️ **Silent mode**: Cài đặt không cần tương tác
- ⚙️ **Templates**: Nginx templates có thể tùy chỉnh

## [0.9.0] - 2025-06-20 (Beta)

### Added
- 🧪 **Beta testing**: Initial beta release
- 🧪 **Core modules**: Basic module structure
- 🧪 **Testing**: Local testing on Ubuntu 24.04

### Fixed
- 🐛 **Module dependencies**: Fixed execution order
- 🐛 **Permission issues**: Corrected file permissions
- 🐛 **Path issues**: Fixed relative paths

## [0.1.0] - 2025-06-15 (Alpha)

### Added
- 🚀 **Initial release**: Project structure
- 🚀 **Basic scripts**: Core installation scripts
- 🚀 **Configuration**: Initial configuration system

---

## Versioning Strategy

- **Major** (X.0.0): Breaking changes, new Ubuntu versions
- **Minor** (0.X.0): New features, new services
- **Patch** (0.0.X): Bug fixes, minor improvements

## Release Notes

### v1.0.0 Highlights

Đây là phiên bản stable đầu tiên của VPS Management Script. Script đã được test kỹ lưỡng trên Ubuntu 24.04 và sẵn sàng cho production use.

**Key Features:**
- 🎯 **One-command installation**: Cài đặt toàn bộ LEMP stack với 1 lệnh
- 🛡️ **Security first**: Bảo mật được ưu tiên từ đầu
- 🚀 **Performance optimized**: Cấu hình được tối ưu cho performance
- 🔧 **Easy management**: Tools quản lý dễ sử dụng
- 📊 **Monitoring ready**: Built-in monitoring và logging

**Perfect for:**
- Developers cần setup môi trường development nhanh
- System admins quản lý multiple websites
- Small businesses cần VPS hosting solution
- DevOps engineers cần automated deployment

**Next Steps:**
- Ubuntu 22.04 support
- Web interface
- Cloud integration
- Multi-server support

---

Cảm ơn tất cả những người đã đóng góp và test script! 🙏
