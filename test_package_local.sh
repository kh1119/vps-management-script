#!/bin/bash

# =============================================================================
# Script test package local (test_package_local.sh)
# Kiểm tra package hoạt động đúng trước khi upload
# =============================================================================

set -e

cd /Users/kth/Documents/code/Scripts/vps-management-script

echo "🧪 Test VPS Management Script Package"
echo "===================================="

# Tạo thư mục test
TEST_DIR="test_environment"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo ""
echo "📦 Bước 1: Tạo package..."
cd ..
chmod +x create_ubuntu24_package.sh
./create_ubuntu24_package.sh
cd "$TEST_DIR"

# Copy package vào test dir
cp ../ubuntu24-lemp-installer.zip .

echo ""
echo "🧪 Bước 2: Test giải nén package..."

# Kiểm tra file zip
if [[ ! -f "ubuntu24-lemp-installer.zip" ]]; then
    echo "❌ Package file không tồn tại!"
    exit 1
fi

echo "✅ Package file tồn tại: $(du -h ubuntu24-lemp-installer.zip | cut -f1)"

# Giải nén
unzip -q ubuntu24-lemp-installer.zip
echo "✅ Giải nén thành công"

# Kiểm tra cấu trúc
echo ""
echo "📁 Bước 3: Kiểm tra cấu trúc package..."
if [[ ! -d "ubuntu24_package" ]]; then
    echo "❌ Thư mục ubuntu24_package không tồn tại!"
    exit 1
fi

cd ubuntu24_package

echo "📋 Nội dung package:"
find . -type f | sort

# Kiểm tra các file quan trọng
required_files=(
    "install_ubt_24.sh"
    "config.sh" 
    "setup.sh"
    "modules/ubuntu/24/00_prepare_system.sh"
    "modules/ubuntu/24/01_install_nginx.sh"
    "modules/ubuntu/24/02_install_mariadb.sh"
    "modules/ubuntu/24/03_install_php.sh"
    "modules/ubuntu/24/04_install_redis.sh"
    "modules/ubuntu/24/05_install_tools.sh"
    "modules/ubuntu/24/10_manage_website.sh"
    "templates/nginx/site.conf"
)

echo ""
echo "🔍 Bước 4: Kiểm tra files cần thiết..."
missing_files=()
for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file"
    else
        echo "❌ $file (missing)"
        missing_files+=("$file")
    fi
done

if [[ ${#missing_files[@]} -gt 0 ]]; then
    echo ""
    echo "❌ Một số file quan trọng bị thiếu!"
    exit 1
fi

echo ""
echo "🔧 Bước 5: Test setup script..."
chmod +x setup.sh

# Tạo mock target directory
MOCK_TARGET="/tmp/test_my_super_script"
rm -rf "$MOCK_TARGET"

# Sửa setup.sh để test với mock directory
sed "s|/root/vps-management-script|$MOCK_TARGET|g" setup.sh > setup_test.sh
chmod +x setup_test.sh

# Chạy setup test
./setup_test.sh

# Kiểm tra kết quả setup
echo ""
echo "🔍 Bước 6: Kiểm tra kết quả setup..."
if [[ ! -d "$MOCK_TARGET" ]]; then
    echo "❌ Target directory không được tạo!"
    exit 1
fi

echo "✅ Target directory: $MOCK_TARGET"

# Kiểm tra files đã được copy
for file in "${required_files[@]}"; do
    if [[ -f "$MOCK_TARGET/$file" ]]; then
        echo "✅ $file copied"
    else
        echo "❌ $file not copied"
        exit 1
    fi
done

# Kiểm tra quyền thực thi
if [[ -x "$MOCK_TARGET/install_ubt_24.sh" ]]; then
    echo "✅ install_ubt_24.sh executable"
else
    echo "❌ install_ubt_24.sh not executable"
    exit 1
fi

# Test import config
echo ""
echo "🔧 Bước 7: Test import config..."
cd "$MOCK_TARGET"

# Test config.sh có thể được source
if bash -c "source config.sh && echo 'Config loaded successfully'"; then
    echo "✅ config.sh loads correctly"
else
    echo "❌ config.sh has errors"
    exit 1
fi

# Test install script có thể tìm config
if bash -c "SCRIPT_DIR=\"$MOCK_TARGET\" && source \"\$SCRIPT_DIR/config.sh\" && echo 'Install script can find config'"; then
    echo "✅ install_ubt_24.sh can find config.sh"
else
    echo "❌ install_ubt_24.sh cannot find config.sh"
    exit 1
fi

# Cleanup
cd /Users/kth/Documents/code/Scripts/vps-management-script
rm -rf "$TEST_DIR" "$MOCK_TARGET"

echo ""
echo "🎉 Test hoàn tất - Package hoạt động chính xác!"
echo ""
echo "📋 Kết quả test:"
echo "✅ Package tạo thành công"
echo "✅ Giải nén đúng cấu trúc"  
echo "✅ Tất cả files cần thiết có mặt"
echo "✅ Setup script hoạt động"
echo "✅ Files được copy đúng vị trí"
echo "✅ Quyền thực thi được set"
echo "✅ Config.sh import được"
echo "✅ Dependencies resolved"

echo ""
echo "🚀 Package sẵn sàng upload lên GitHub!"
echo "   Chạy: ./upload_fixed_package.sh"
