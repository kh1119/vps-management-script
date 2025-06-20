#!/bin/bash

#echo "1️⃣ Kiểm tra repository tồn tại:"
echo "   https://github.com/kh1119/vps-management-script"
echo ""

echo "2️⃣ Kiểm tra file main.sh trên GitHub:"
echo "   https://github.com/kh1119/vps-management-script/blob/main/main.sh"
echo ""

echo "3️⃣ Kiểm tra raw file:"
echo "   https://raw.githubusercontent.com/kh1119/vps-management-script/main/main.sh"
echo ""

# Test connection
echo "🌐 Test kết nối đến GitHub..."
if curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/kh1119/vps-management-script" | grep -q "200"; then===============================================================
# Script kiểm tra và sửa lỗi GitHub (debug_github.sh)
# =============================================================================

echo "🔍 VPS Management Script - GitHub Debug Tool"
echo "============================================="

# Kiểm tra các khả năng gây lỗi 404
echo ""
echo "📋 Kiểm tra các nguyên nhân có thể:"

echo ""
echo "1️⃣ Kiểm tra repository tồn tại:"
echo "   https://github.com/kh1119/vps-management-script"
echo ""

echo "2️⃣ Kiểm tra file main.sh trên GitHub:"
echo "   https://github.com/kh1119/vps-management-script/blob/main/main.sh"
echo ""

echo "3️⃣ Kiểm tra raw file:"
echo "   https://raw.githubusercontent.com/kh1119/vps-management-script/main/main.sh"
echo ""

# Test connection
echo "🌐 Test kết nối đến GitHub..."
if curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/kh1119/vps-management-script" | grep -q "200"; then
    echo "✅ Repository tồn tại và public"
else
    echo "❌ Repository không tồn tại hoặc không public"
    echo ""
    echo "🛠️ Các khả năng:"
    echo "   • Repository chưa được tạo"
    echo "   • Repository đang private"  
    echo "   • Username 'kth' không đúng"
    echo "   • Repository name không đúng"
fi

echo ""
echo "🔧 Các bước khắc phục:"
echo ""

echo "1️⃣ Xác định GitHub username thực:"
echo "   - Truy cập https://github.com"
echo "   - Xem username trong URL profile"
echo ""

echo "2️⃣ Tạo repository nếu chưa có:"
echo "   - Truy cập https://github.com/new"
echo "   - Repository name: vps-management-script"
echo "   - Chọn Public"
echo "   - Add README file"
echo ""

echo "3️⃣ Upload code bằng script mới:"
echo "   chmod +x github_upload_fixed.sh"
echo "   ./github_upload_fixed.sh"
echo ""

echo "4️⃣ Hoặc upload thủ công:"
echo "   - Drag & drop tất cả files vào GitHub web interface"
echo "   - Commit changes"
echo ""

echo "📞 Cần hỗ trợ thêm:"
echo "   - Cung cấp GitHub username thực của bạn"
echo "   - Screenshot repository trên GitHub"
echo "   - Paste link repository thực tế"

echo ""
echo "⚡ Quick fix command:"
echo 'curl -sSL https://raw.githubusercontent.com/YOUR_REAL_USERNAME/vps-management-script/main/main.sh | sudo bash'
