# 🚨 Fix PHP CURL Error: Call to undefined function curl_exec()

## ❌ Lỗi gặp phải:
```
Fatal error: Uncaught Error: Call to undefined function curl_exec() in /home/__all/public_html/inc/api.php:31
Stack trace:
#0 /home/__all/public_html/inc/api.php(42): __api->sending()
#1 /home/__all/public_html/inc/setting.php(3): __api->call()
#2 /home/__all/public_html/index.php(10): require_once('...')
#3 {main} thrown in /home/__all/public_html/inc/api.php on line 31
```

## 🔍 Nguyên nhân:
1. **Extension CURL đã được cài đặt** ✅
2. **Nhưng function curl_exec() bị disable** ❌ trong PHP configuration
3. **Cấu hình bảo mật quá nghiêm ngặt** trong file `/etc/php/*/fpm/php.ini`

## 🎯 Vấn đề trong code:

### File: `modules/ubuntu/24/03_install_php.sh`
```bash
# CẤU HÌNH SAI - QUÁ NGHIÊM NGẶT
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_exec,curl_multi_exec,parse_ini_file,show_source
allow_url_fopen = Off
```

**Vấn đề:**
- `curl_exec` và `curl_multi_exec` bị disable
- `allow_url_fopen = Off` cũng ảnh hưởng đến một số HTTP operations

## ✅ Giải pháp đã áp dụng:

### 1. **Sửa PHP configuration trong script**
```bash
# CẤU HÌNH MỚI - CÂN BẰNG BẢO MẬT VÀ CHỨC NĂNG
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,parse_ini_file,show_source
allow_url_fopen = On
```

**Thay đổi:**
- ✅ **Loại bỏ** `curl_exec` và `curl_multi_exec` khỏi disable_functions
- ✅ **Enable** `allow_url_fopen = On`
- ✅ **Giữ lại** các function nguy hiểm khác bị disable

### 2. **Tạo script fix cho server đã cài đặt**
```bash
# Chạy script fix
sudo ./fix_php_curl.sh
```

Script này sẽ:
- ✅ Backup files php.ini gốc
- ✅ Sửa disable_functions trong tất cả PHP versions
- ✅ Enable allow_url_fopen
- ✅ Restart PHP-FPM và Nginx
- ✅ Kiểm tra và báo cáo kết quả

## 📋 Functions được enable:
- ✅ `curl_exec()` - Execute CURL requests
- ✅ `curl_multi_exec()` - Execute multiple CURL requests
- ✅ `allow_url_fopen` - Allow URL file operations

## 🔒 Functions vẫn được disable (bảo mật):
- ❌ `exec()`, `passthru()`, `shell_exec()`, `system()`
- ❌ `proc_open()`, `popen()`
- ❌ `parse_ini_file()`, `show_source()`

## 🧪 Test CURL functionality:

### Kiểm tra extension:
```bash
php -r "echo extension_loaded('curl') ? 'CURL extension: OK' : 'CURL extension: MISSING'; echo PHP_EOL;"
```

### Kiểm tra function:
```bash
php -r "echo function_exists('curl_exec') ? 'curl_exec(): OK' : 'curl_exec(): DISABLED'; echo PHP_EOL;"
```

### Test simple CURL:
```php
<?php
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'https://httpbin.org/ip');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$result = curl_exec($ch);
curl_close($ch);
echo $result ? "CURL working: $result" : "CURL failed";
?>
```

## 🚀 Kết quả:
- ✅ **APIs và HTTP requests hoạt động bình thường**
- ✅ **Vẫn maintain security** bằng cách disable các function nguy hiểm khác
- ✅ **Backward compatible** với applications cần CURL
- ✅ **Easy fix** cho servers đã được deploy

## 🔧 Files đã được cập nhật:
1. ✅ `modules/ubuntu/24/03_install_php.sh` - Fixed PHP config template
2. ✅ `fix_php_curl.sh` - Script fix cho servers đã cài đặt
3. ✅ `FIX_PHP_CURL_ERROR.md` - Documentation

## 💡 Best Practice:
- **Balance security vs functionality**
- **Keep dangerous functions disabled**: exec, system, shell_exec
- **Enable necessary functions**: curl_exec, allow_url_fopen
- **Always backup** before making changes
- **Test thoroughly** after fixes
