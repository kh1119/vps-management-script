#!/bin/bash

# =============================================================================
# Quick Fix Script (quick_fix.sh)
# Tự động fix lỗi dependencies và tạo solution
# =============================================================================

echo "🚨 VPS Management Script - Quick Fix"
echo "==================================="
echo ""
echo "Đã phát hiện lỗi: install_ubt_24.sh thiếu config.sh và modules"
echo ""

# Make all scripts executable
chmod +x *.sh 2>/dev/null || true

echo "🔧 Các giải pháp có sẵn:"
echo ""

echo "1️⃣ Test package local (Khuyến nghị để dev):"
echo "   ./test_package_local.sh"
echo ""

echo "2️⃣ Tạo package và upload lên GitHub:"
echo "   ./upload_fixed_package.sh"
echo "   # Script sẽ hỏi GitHub username và tự động upload"
echo ""

echo "3️⃣ Tạo package standalone:"
echo "   ./create_ubuntu24_package.sh"
echo "   # Tạo file ubuntu24-lemp-installer.zip"
echo ""

echo "4️⃣ Chạy offline (nếu có đủ files local):"
echo "   ./main_offline.sh"
echo ""

echo "📋 Lý do lỗi:"
echo "• Script main.sh chỉ download install_ubt_24.sh"
echo "• Nhưng install_ubt_24.sh cần config.sh và modules/*"
echo "• Solution: Tạo package ZIP chứa tất cả dependencies"

echo ""
echo -n "Chọn giải pháp (1-4): "
read -r choice

case $choice in
    1)
        echo "🧪 Running package test..."
        ./test_package_local.sh
        ;;
    2)
        echo "⬆️ Creating and uploading package..."
        ./upload_fixed_package.sh
        ;;
    3)
        echo "📦 Creating package..."
        ./create_ubuntu24_package.sh
        echo ""
        echo "✅ Package created: ubuntu24-lemp-installer.zip"
        echo "📤 Manually upload this file to your GitHub repository"
        ;;
    4)
        echo "🔧 Running offline..."
        ./main_offline.sh
        ;;
    *)
        echo "❌ Invalid choice"
        echo ""
        echo "💡 Để fix nhanh nhất:"
        echo "   ./upload_fixed_package.sh"
        ;;
esac

echo ""
echo "📞 Nếu vẫn gặp vấn đề:"
echo "• Check GitHub repository đã public chưa"
echo "• Verify package file ubuntu24-lemp-installer.zip exists on GitHub"
echo "• Test với: git clone https://github.com/YOUR_USERNAME/vps-management-script.git"
