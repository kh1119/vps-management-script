#!/bin/bash

# =============================================================================
# Script tạo package Ubuntu 24.04 (create_ubuntu24_package.sh)
# Mục tiêu: Đóng gói tất cả files cần thiết cho Ubuntu 24.04
# =============================================================================

set -e

PROJECT_DIR="/Users/kth/Documents/code/Scripts/vps-management-script"
PACKAGE_NAME="ubuntu24-package"
PACKAGE_DIR="$PROJECT_DIR/$PACKAGE_NAME"

echo "📦 Tạo Ubuntu 24.04 Package..."

# Tạo thư mục package
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy các files cần thiết
echo "📁 Copy files cần thiết..."

# Script chính
cp "$PROJECT_DIR/install_ubt_24.sh" "$PACKAGE_DIR/"
cp "$PROJECT_DIR/config.sh" "$PACKAGE_DIR/"
cp "$PROJECT_DIR/health_check.sh" "$PACKAGE_DIR/"

# Modules
mkdir -p "$PACKAGE_DIR/modules/ubuntu/24"
cp "$PROJECT_DIR"/modules/ubuntu/24/*.sh "$PACKAGE_DIR/modules/ubuntu/24/"

# Templates
mkdir -p "$PACKAGE_DIR/templates/nginx"
cp "$PROJECT_DIR"/templates/nginx/*.conf "$PACKAGE_DIR/templates/nginx/"

# Thư mục logs và backups (tạo trống)
mkdir -p "$PACKAGE_DIR/logs"
mkdir -p "$PACKAGE_DIR/backups"

# Copy README cho package
cat > "$PACKAGE_DIR/README.txt" << 'EOF'
VPS Management Script - Ubuntu 24.04 Package
=============================================

Files included:
- install_ubt_24.sh     : Main installation script  
- config.sh            : Central configuration
- health_check.sh      : System health checker
- modules/ubuntu/24/   : Installation modules
- templates/nginx/     : Nginx configuration templates

Usage:
1. Extract this package
2. Run: sudo ./install_ubt_24.sh
3. For health check: sudo ./health_check.sh

Support:
https://github.com/kh1119/vps-management-script
EOF

# Cấp quyền thực thi
echo "⚡ Cấp quyền thực thi..."
find "$PACKAGE_DIR" -name "*.sh" -exec chmod +x {} \;

# Tạo file zip
echo "🗜️ Tạo file ZIP..."
cd "$PROJECT_DIR"
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME/"

# Tạo file tar.gz backup
echo "📦 Tạo file TAR.GZ..."
tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME/"

# Thống kê
echo ""
echo "✅ Package được tạo thành công!"
echo "📊 Thống kê:"
echo "  • Files: $(find "$PACKAGE_DIR" -type f | wc -l)"
echo "  • Scripts: $(find "$PACKAGE_DIR" -name "*.sh" | wc -l)"
echo "  • Size: $(du -sh "$PACKAGE_DIR" | cut -f1)"
echo "  • ZIP size: $(du -sh "${PACKAGE_NAME}.zip" | cut -f1)"
echo ""
echo "📁 Files tạo ra:"
echo "  • $PACKAGE_DIR/ (thư mục)"
echo "  • ${PACKAGE_NAME}.zip"
echo "  • ${PACKAGE_NAME}.tar.gz"
echo ""
echo "🚀 Upload files ZIP lên GitHub:"
echo "  1. Truy cập GitHub repository"
echo "  2. Upload file ${PACKAGE_NAME}.zip"
echo "  3. Commit changes"

# Tạo script test local
cat > "$PACKAGE_DIR/test_local.sh" << 'EOF'
#!/bin/bash

echo "🧪 Test Ubuntu 24.04 Package Local"
echo "=================================="

# Kiểm tra tất cả files cần thiết
required_files=(
    "install_ubt_24.sh"
    "config.sh"
    "health_check.sh"
    "modules/ubuntu/24/00_prepare_system.sh"
    "modules/ubuntu/24/01_install_nginx.sh"
    "modules/ubuntu/24/02_install_mariadb.sh"
    "modules/ubuntu/24/03_install_php.sh"
    "modules/ubuntu/24/04_install_redis.sh"
    "modules/ubuntu/24/05_install_tools.sh"
    "modules/ubuntu/24/10_manage_website.sh"
    "templates/nginx/site.conf"
)

echo "🔍 Kiểm tra files..."
missing_files=0
for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file"
    else
        echo "❌ $file (missing)"
        ((missing_files++))
    fi
done

if [[ $missing_files -eq 0 ]]; then
    echo ""
    echo "🎉 Tất cả files đã sẵn sàng!"
    echo "🚀 Có thể chạy: sudo ./install_ubt_24.sh"
else
    echo ""
    echo "⚠️ Thiếu $missing_files files!"
fi
EOF

chmod +x "$PACKAGE_DIR/test_local.sh"

echo "🧪 Test package local:"
echo "  cd $PACKAGE_NAME"
echo "  ./test_local.sh"
