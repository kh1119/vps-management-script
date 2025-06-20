# 🚨 Fix Lỗi 404 - GitHub Repository Not Found

## 🔍 Nguyên nhân lỗi 404

```bash
curl -sSL https://raw.githubusercontent.com/kh1119/vps-management-script/main/main.sh | sudo bash
bash: line 1: 404:: command not found
```

**Lỗi này có nghĩa là:**
- Repository `kh1119/vps-management-script` không tồn tại
- Repository chưa public
- File `main.sh` chưa được upload
- Username `kh1119` không đúng

## ⚡ Giải pháp nhanh

### Cách 1: Xác định GitHub username thực

1. **Kiểm tra GitHub username của bạn:**
   ```bash
   # Truy cập GitHub và xem URL profile
   # Ví dụ: https://github.com/YOUR_REAL_USERNAME
   ```

2. **Thay thế trong lệnh:**
   ```bash
   curl -sSL https://raw.githubusercontent.com/YOUR_REAL_USERNAME/vps-management-script/main/main.sh | sudo bash
   ```

### Cách 2: Upload script bằng tool mới

```bash
cd /Users/kth/Documents/code/Scripts/vps-management-script

# Chạy script upload mới (sẽ hỏi username thực)
chmod +x github_upload_fixed.sh
./github_upload_fixed.sh
```

### Cách 3: Upload thủ công qua GitHub Web

1. **Tạo repository:**
   - Truy cập: https://github.com/new
   - Repository name: `vps-management-script`
   - Description: `🚀 Automated VPS Management Script for Ubuntu 24.04`
   - ✅ Public
   - ✅ Add README file
   - Create repository

2. **Upload files:**
   - Click "uploading an existing file" 
   - Drag & drop tất cả files từ `/Users/kth/Documents/code/Scripts/vps-management-script/`
   - Commit changes

### Cách 4: Clone và chạy offline

```bash
# Thay YOUR_USERNAME bằng username thực
git clone https://github.com/YOUR_USERNAME/vps-management-script.git
cd vps-management-script
chmod +x *.sh modules/ubuntu/24/*.sh
sudo ./install_ubt_24.sh
```

### Cách 5: Download và chạy local

```bash
# Download ZIP từ GitHub
wget https://github.com/YOUR_USERNAME/vps-management-script/archive/refs/heads/main.zip
unzip main.zip
cd vps-management-script-main
chmod +x *.sh modules/ubuntu/24/*.sh
sudo ./install_ubt_24.sh
```

## 🔧 Debug tools

### Kiểm tra repository tồn tại:
```bash
# Chạy debug script
chmod +x debug_github.sh
./debug_github.sh
```

### Test repository URL:
```bash
# Thay YOUR_USERNAME
curl -I https://api.github.com/repos/YOUR_USERNAME/vps-management-script
```

### Kiểm tra file main.sh:
```bash
# Thay YOUR_USERNAME  
curl -I https://raw.githubusercontent.com/YOUR_USERNAME/vps-management-script/main/main.sh
```

## 📞 Cần hỗ trợ thêm?

**Vui lòng cung cấp:**
1. GitHub username thực của bạn
2. Link repository thực tế
3. Screenshot trang repository trên GitHub

**Hoặc chạy offline:**
```bash
cd /Users/kth/Documents/code/Scripts/vps-management-script
chmod +x main_offline.sh
sudo ./main_offline.sh
```

## ✅ Sau khi fix xong

Test lại với username đúng:
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_REAL_USERNAME/vps-management-script/main/main.sh | sudo bash
```

---

**💡 Tip:** Nếu vẫn gặp lỗi, hãy dùng script offline để chạy local trước, sau đó upload lên GitHub từ từ.
