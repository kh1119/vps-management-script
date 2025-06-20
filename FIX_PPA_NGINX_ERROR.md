# 🔧 Fix PPA Nginx Mainline Error

## ❌ Vấn đề:
```
[INFO] Thêm ppa:ondrej/nginx-mainline...
ERROR: ppa 'ondrej/nginx-mainline' not found (use --login if private)
```

## 🔍 Nguyên nhân:
- PPA `ppa:ondrej/nginx-mainline` **KHÔNG TỒN TẠI**
- Chỉ có `ppa:ondrej/nginx` (stable version)
- Ubuntu 24.04 đã có Nginx version mới trong repo chính thức

## ✅ Giải pháp đã áp dụng:

### 1. **Cập nhật config.sh**
```bash
# PPAs cần thêm (có thể để trống nếu không cần)
PPAS=(
    "ppa:ondrej/php"
    # "ppa:ondrej/nginx"  # Ubuntu 24.04 đã có nginx mới, comment out để dùng repo mặc định
)
```

### 2. **Thêm error handling trong 00_prepare_system.sh**
```bash
# Thêm các PPA cần thiết
log_info "Thêm PPAs..."
for ppa in "${PPAS[@]}"; do
    # Skip empty PPAs or commented ones
    if [[ -z "$ppa" || "$ppa" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    log_info "Thêm $ppa..."
    if ! add-apt-repository -y "$ppa"; then
        log_warning "Không thể thêm PPA: $ppa - tiếp tục với repo mặc định"
    fi
done
```

### 3. **Sửa all_in_one_installer.sh**
```bash
# Thêm PPAs
log_info "Thêm PPA Ondřej Surý cho PHP..."
if ! add-apt-repository -y ppa:ondrej/php; then
    log_warning "Không thể thêm PPA ondrej/php - sử dụng repo mặc định"
fi

# Ubuntu 24.04 đã có nginx mới, không cần PPA nginx
log_info "Sử dụng Nginx từ repo Ubuntu chính thức"

apt update
```

## 📋 PPAs có sẵn từ Ondřej Surý:
- ✅ `ppa:ondrej/php` - PHP versions (5.6, 7.x, 8.x)
- ✅ `ppa:ondrej/nginx` - Nginx Stable
- ✅ `ppa:ondrej/nginx-qa` - Nginx QA builds (experimental)
- ❌ `ppa:ondrej/nginx-mainline` - **KHÔNG TỒN TẠI**

## 🎯 Kết quả:
- ✅ Script không còn bị lỗi khi thêm PPA
- ✅ Sử dụng Nginx từ repo Ubuntu 24.04 (đủ mới)
- ✅ Vẫn có PPA PHP để đa phiên bản
- ✅ Có error handling cho trường hợp PPA không available

## 💡 Lưu ý:
- Ubuntu 24.04 Noble có Nginx 1.24+, đủ mới cho production
- Chỉ cần PPA PHP để cài đa phiên bản (7.4, 8.3)
- Error handling giúp script chạy tiếp dù có PPA lỗi

## 🧪 Test:
```bash
# Test PPA check
curl -s "https://launchpad.net/~ondrej" | grep -i nginx

# Test script với error handling
bash modules/ubuntu/24/00_prepare_system.sh
```
