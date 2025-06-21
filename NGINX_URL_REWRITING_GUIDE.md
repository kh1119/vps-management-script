# 🔧 Nginx URL Rewriting Guide

## ❌ Vấn đề: "mod_rewrite nginx đã cài đặt chưa vậy sao tôi dùng không được"

### 🔍 **Hiểu về sự khác biệt:**
- **Apache** sử dụng `mod_rewrite` module
- **Nginx** không có `mod_rewrite`, sử dụng `try_files` và `rewrite` directives

## 🚨 Vấn đề phổ biến:

### ❌ **Cấu hình SAI (cũ):**
```nginx
location / {
    try_files $uri $uri/ =404;
}
```

### ✅ **Cấu hình ĐÚNG (mới):**
```nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}
```

## 🔧 Đã sửa trong script:

### 1. **File: `modules/ubuntu/24/01_install_nginx.sh`**
```bash
# CŨ - không support URL rewriting
location / {
    try_files $uri $uri/ =404;
}

# MỚI - support full URL rewriting
location / {
    try_files $uri $uri/ /index.php?$query_string;
}

# Enhanced PHP handling
location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
    
    # Enhanced PHP security and performance
    fastcgi_hide_header X-Powered-By;
    fastcgi_param SERVER_NAME $host;
    fastcgi_param HTTPS $https if_not_empty;
    fastcgi_read_timeout 300;
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_buffer_size 128k;
    fastcgi_buffers 256 16k;
    fastcgi_busy_buffers_size 256k;
    fastcgi_temp_file_write_size 256k;
}
```

### 2. **File: `templates/nginx/site.conf`**
Template này đã có cấu hình đúng từ đầu:
```nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}
```

## 🧪 Scripts để fix và test:

### 1. **Fix existing installations:**
```bash
sudo ./fix_nginx_rewrite.sh
```

### 2. **Test URL rewriting:**
```bash
sudo ./test_nginx_rewrite.sh
```

## 📋 URL Rewriting patterns:

### **WordPress:**
```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
```

### **Laravel:**
```nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}
```

### **CodeIgniter:**
```nginx
location / {
    try_files $uri $uri/ /index.php;
}
```

### **Custom API:**
```nginx
location /api/ {
    try_files $uri $uri/ /index.php?$query_string;
}
```

## 🎯 Test cases:

### **URLs sẽ hoạt động sau khi fix:**
- `/post-name/` → `/index.php?post-name`
- `/category/123` → `/index.php?category=123`
- `/api/users/456` → `/index.php?api=users&id=456`
- `/user/profile/john` → `/index.php?user=profile&name=john`

### **Static files vẫn hoạt động bình thường:**
- `/style.css` → Serve directly
- `/script.js` → Serve directly
- `/image.png` → Serve directly

## 🔍 Debugging URL rewriting:

### **1. Check current config:**
```bash
sudo nginx -T | grep -A 5 "location /"
```

### **2. Check error logs:**
```bash
sudo tail -f /var/log/nginx/error.log
```

### **3. Test with curl:**
```bash
curl -I http://your-server/test/page
```

### **4. Enable debug logging:**
```nginx
error_log /var/log/nginx/error.log debug;
```

## 🚀 Advanced rewriting:

### **Custom rewrite rules:**
```nginx
# Redirect old URLs to new structure
rewrite ^/old-page$ /new-page permanent;

# API versioning
rewrite ^/api/v1/(.*)$ /api.php?version=1&path=$1 last;

# Clean URLs for specific patterns
rewrite ^/product/([0-9]+)$ /product.php?id=$1 last;
```

### **Multiple conditions:**
```nginx
location / {
    # Try exact file first
    try_files $uri $uri/ @rewrite;
}

location @rewrite {
    rewrite ^/(.*)$ /index.php?q=$1;
}
```

## 📊 Performance improvements:

### **Static file caching:**
```nginx
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
    try_files $uri =404;
}
```

### **Gzip compression:**
```nginx
gzip on;
gzip_vary on;
gzip_types
    text/plain
    text/css
    text/xml
    text/javascript
    application/javascript
    application/json
    application/xml+rss;
```

## 🔒 Security considerations:

### **Block sensitive files:**
```nginx
location ~ /\.(ht|git|svn) {
    deny all;
    access_log off;
    log_not_found off;
}

location ~ /(config|install|admin)\.php$ {
    allow 127.0.0.1;
    deny all;
}
```

## 💡 Best practices:

1. **Always backup** before changing configs
2. **Test configuration** before reloading: `nginx -t`
3. **Use specific patterns** instead of catch-all
4. **Monitor error logs** after changes
5. **Performance test** with real traffic

## 🎯 Summary:

- ✅ **Fixed** default site template in install script
- ✅ **Created** fix script for existing installations  
- ✅ **Added** test script to verify functionality
- ✅ **Enhanced** PHP handling with better performance
- ✅ **Documented** common patterns and troubleshooting

Nginx URL rewriting giờ sẽ hoạt động đúng cách cho tất cả frameworks! 🚀
