# Contributing to VPS Management Script

Cảm ơn bạn quan tâm đến việc đóng góp cho VPS Management Script! 🎉

## 🤝 Cách đóng góp

### Báo cáo lỗi (Bug Reports)

Trước khi báo cáo lỗi, vui lòng:

1. **Kiểm tra Issues hiện tại** để đảm bảo lỗi chưa được báo cáo
2. **Chạy health check** để thu thập thông tin hệ thống:
   ```bash
   sudo ./health_check.sh
   ```
3. **Tạo Issue mới** với thông tin chi tiết

#### Template báo cáo lỗi:
```markdown
## 🐛 Mô tả lỗi
[Mô tả ngắn gọn về lỗi]

## 🔄 Các bước tái tạo
1. Chạy lệnh...
2. Thấy lỗi...
3. Kết quả không mong muốn...

## 💻 Môi trường
- OS: Ubuntu 24.04
- Script version: v1.0
- Health check output: [Paste output here]

## 📋 Log files
[Paste relevant log content from /root/my-super-script/logs/]

## 🎯 Kết quả mong đợi
[Mô tả những gì bạn mong đợi xảy ra]

## 📷 Screenshots (nếu có)
[Attach screenshots if applicable]
```

### Đề xuất tính năng (Feature Requests)

1. **Kiểm tra roadmap** trong Issues để xem tính năng đã được lên kế hoạch chưa
2. **Tạo Feature Request** với template:

```markdown
## ✨ Mô tả tính năng
[Mô tả chi tiết tính năng bạn muốn]

## 🎯 Mục đích
[Tại sao tính năng này hữu ích?]

## 💡 Giải pháp đề xuất
[Bạn có ý tưởng về cách implement không?]

## 🔄 Giải pháp thay thế
[Có cách nào khác để giải quyết vấn đề không?]

## 📝 Chi tiết bổ sung
[Bất kỳ thông tin nào khác]
```

## 🛠️ Development

### Thiết lập môi trường development

1. **Fork repository**
2. **Clone fork của bạn**:
   ```bash
   git clone https://github.com/your-username/vps-management-script.git
   cd vps-management-script
   ```

3. **Thiết lập development environment**:
   ```bash
   # Cấp quyền thực thi
   chmod +x setup_git.sh
   ./setup_git.sh
   
   # Test script (chỉ trên test server)
   sudo ./install_ubt_24.sh --silent
   ```

### Code Guidelines

#### 🎨 Code Style

- **Bash scripting**: Tuân thủ [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Indentation**: 4 spaces, không dùng tabs
- **Line endings**: Unix (LF)
- **Encoding**: UTF-8

#### 📋 Naming Conventions

- **Functions**: snake_case (`install_nginx`, `check_system`)
- **Variables**: UPPER_CASE cho constants (`NGINX_VERSION`), snake_case cho locals (`config_file`)
- **Files**: snake_case với extension `.sh`
- **Modules**: số thứ tự + tên (`01_install_nginx.sh`)

#### 🔧 Code Structure

```bash
#!/bin/bash

# =============================================================================
# Module Description
# Purpose: Brief description
# =============================================================================

set -e

# Import configuration
source "$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")/config.sh"

# Functions
function_name() {
    local param1="$1"
    local param2="$2"
    
    # Function logic
    log_info "Starting function_name..."
    
    # Error handling
    if ! command; then
        log_error "Error message"
        return 1
    fi
    
    log_success "Function completed successfully"
}

# Main execution
main() {
    log_info "=== MODULE DESCRIPTION ==="
    function_name "param1" "param2"
}

# Run main function
main "$@"
```

#### 🧪 Testing

- **Luôn test trên Ubuntu 24.04** clean installation
- **Chạy health check** sau mỗi thay đổi:
  ```bash
  sudo ./health_check.sh
  ```
- **Test cả interactive và silent mode**:
  ```bash
  sudo ./install_ubt_24.sh          # Interactive
  sudo ./install_ubt_24.sh --silent # Silent
  ```

#### 📝 Documentation

- **Inline comments**: Giải thích logic phức tạp
- **Function headers**: Mô tả purpose, parameters, return values
- **README updates**: Cập nhật nếu thêm tính năng mới
- **CHANGELOG**: Ghi lại tất cả thay đổi

### Pull Request Process

1. **Tạo feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Commit theo conventional commits**:
   ```bash
   git commit -m "feat: add nginx rate limiting configuration"
   git commit -m "fix: resolve PHP-FPM socket permission issue"
   git commit -m "docs: update installation instructions"
   ```

3. **Test thoroughly**:
   - Clean Ubuntu 24.04 VM
   - Both interactive and silent modes
   - Health check passes
   - No regression issues

4. **Update documentation** nếu cần thiết

5. **Tạo Pull Request** với:
   - **Clear title**: Mô tả ngắn gọn thay đổi
   - **Detailed description**: Giải thích changes, testing, impact
   - **Link issues**: Reference related issues
   - **Screenshots**: Nếu có UI changes

#### PR Template:
```markdown
## 📝 Mô tả
[Mô tả chi tiết về changes]

## 🔗 Related Issues
Fixes #123
Closes #456

## 🧪 Testing
- [ ] Tested on clean Ubuntu 24.04
- [ ] Interactive mode works
- [ ] Silent mode works  
- [ ] Health check passes
- [ ] No regression issues

## 📷 Screenshots (nếu có)
[Add screenshots if applicable]

## ✅ Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests pass
- [ ] CHANGELOG updated
```

## 🏗️ Architecture

### Module System

```
modules/ubuntu/24/
├── 00_prepare_system.sh    # System prep, firewall, security
├── 01_install_nginx.sh     # Web server installation
├── 02_install_mariadb.sh   # Database installation  
├── 03_install_php.sh       # PHP multi-version setup
├── 04_install_redis.sh     # Cache server setup
├── 05_install_tools.sh     # Additional tools
└── 10_manage_website.sh    # Website management
```

### Configuration System

- **config.sh**: Central configuration
- **Templates**: Nginx, PHP, etc. configurations
- **Credentials**: Secure password storage

### Logging System

- **Structured logging**: Timestamp, level, message
- **Multiple outputs**: Console + file
- **Log rotation**: Automatic cleanup

## 🎯 Priorities

### High Priority
- 🐛 Bug fixes
- 🔒 Security improvements
- 📚 Documentation improvements

### Medium Priority
- ✨ New features
- 🚀 Performance optimizations
- 🧪 Testing improvements

### Low Priority
- 🎨 Code refactoring
- 📦 Package updates
- 🔄 Workflow improvements

## 📞 Community

- **Discussions**: GitHub Discussions for questions
- **Issues**: Bug reports and feature requests
- **Pull Requests**: Code contributions
- **Wiki**: Community documentation

## 🙏 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Recognized in README

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing! 🎉**

Mọi đóng góp, dù lớn hay nhỏ, đều được đánh giá cao!
