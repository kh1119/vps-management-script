# 🚀 Quick Start: Upload to GitHub

Hướng dẫn nhanh để upload VPS Management Script lên GitHub của bạn.

## ⚡ Quick Commands

```bash
# 1. Chuẩn bị project
cd /Users/kth/Documents/code/Scripts/vps-management-script
chmod +x prepare_release.sh
./prepare_release.sh

# 2. Cập nhật GitHub username trong upload script
sed -i '' 's/GITHUB_USERNAME="kth"/GITHUB_USERNAME="YOUR_ACTUAL_USERNAME"/' upload_to_github.sh

# 3. Upload lên GitHub
./upload_to_github.sh
```

## 📋 Chi tiết từng bước

### Bước 1: Tạo GitHub Repository

1. Truy cập https://github.com/new
2. Điền thông tin:
   - **Repository name**: `vps-management-script`
   - **Description**: `🚀 Automated VPS Management Script for Ubuntu 24.04 - Complete LEMP Stack Installation & Website Management Tool`
   - **Visibility**: Public
   - **Initialize**: ✅ Add a README file
   - **License**: MIT License
3. Click **"Create repository"**

### Bước 2: Chuẩn bị Local Repository

```bash
cd /Users/kth/Documents/code/Scripts/vps-management-script

# Chuẩn bị tất cả files
./prepare_release.sh

# Cập nhật GitHub username (thay YOUR_USERNAME)
sed -i '' 's/GITHUB_USERNAME="kth"/GITHUB_USERNAME="YOUR_USERNAME"/' upload_to_github.sh
```

### Bước 3: Upload lên GitHub

```bash
# Upload tất cả files
./upload_to_github.sh
```

### Bước 4: Tạo Release (Tùy chọn)

1. Truy cập repository trên GitHub
2. Click **"Releases"** → **"Create a new release"**
3. Điền thông tin:
   - **Tag**: `v1.0.0`
   - **Title**: `🎉 VPS Management Script v1.0.0`
   - **Description**: Copy từ CHANGELOG.md
4. Click **"Publish release"**

## 🧪 Test Script

Sau khi upload, test script:

```bash
# Test trên VPS Ubuntu 24.04
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/vps-management-script/main/main.sh | sudo bash
```

## 🔧 Troubleshooting

### Git không nhận diện email/name:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Permission denied khi push:
```bash
# Sử dụng personal access token thay vì password
# Tạo token tại: https://github.com/settings/tokens
```

### Script không executable:
```bash
chmod +x *.sh modules/ubuntu/24/*.sh
```

## ✅ Checklist

- [ ] Repository đã tạo trên GitHub
- [ ] GitHub username đã cập nhật
- [ ] Tất cả scripts có quyền executable
- [ ] Upload thành công
- [ ] README hiển thị đúng
- [ ] Script test OK trên Ubuntu 24.04

---

**🎉 Chúc mừng! Script của bạn đã sẵn sàng!**
