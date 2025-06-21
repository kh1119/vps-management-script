#!/bin/bash

# =============================================================================
# Test Nginx URL Rewriting Configuration
# Kiểm tra xem Nginx có hỗ trợ URL rewriting đúng cách không
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔧 Test Nginx URL Rewriting"
echo "============================"

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   log_error "Script này cần quyền root!"
   log_info "Chạy: sudo $0"
   exit 1
fi

# Kiểm tra Nginx đang chạy
if ! systemctl is-active --quiet nginx; then
    log_error "Nginx không đang chạy!"
    log_info "Khởi động Nginx: sudo systemctl start nginx"
    exit 1
fi

log_success "Nginx đang chạy"

# Kiểm tra cấu hình Nginx
log_info "Kiểm tra cấu hình Nginx..."
if nginx -t > /dev/null 2>&1; then
    log_success "Nginx configuration: OK"
else
    log_error "Nginx configuration có lỗi!"
    nginx -t
    exit 1
fi

# Tạo test files
TEST_DIR="/home/__all/public_html"
if [[ ! -d "$TEST_DIR" ]]; then
    log_warning "Thư mục web không tồn tại: $TEST_DIR"
    log_info "Tạo thư mục test..."
    mkdir -p "$TEST_DIR"
fi

# Tạo test index.php
log_info "Tạo test files..."

cat > "$TEST_DIR/index.php" << 'EOF'
<?php
echo "<h1>🔧 Nginx URL Rewriting Test</h1>";
echo "<p><strong>Server:</strong> " . $_SERVER['SERVER_NAME'] . "</p>";
echo "<p><strong>Request URI:</strong> " . $_SERVER['REQUEST_URI'] . "</p>";
echo "<p><strong>Query String:</strong> " . $_SERVER['QUERY_STRING'] . "</p>";
echo "<p><strong>Script Name:</strong> " . $_SERVER['SCRIPT_NAME'] . "</p>";

if (isset($_GET) && !empty($_GET)) {
    echo "<h3>GET Parameters:</h3>";
    echo "<pre>" . print_r($_GET, true) . "</pre>";
}

echo "<hr>";
echo "<h3>🧪 URL Rewriting Tests:</h3>";
echo "<ul>";
echo "<li><a href='/test/page'>Pretty URL: /test/page</a></li>";
echo "<li><a href='/category/123'>Category: /category/123</a></li>";
echo "<li><a href='/user/profile/456'>User Profile: /user/profile/456</a></li>";
echo "<li><a href='/api/v1/data'>API: /api/v1/data</a></li>";
echo "</ul>";

echo "<hr>";
echo "<p>✅ If you can see this page, basic PHP is working!</p>";
echo "<p>📝 Click the links above to test URL rewriting.</p>";
EOF

# Tạo test info.php
cat > "$TEST_DIR/info.php" << 'EOF'
<?php
phpinfo();
EOF

# Tạo test .htaccess (để kiểm tra Nginx có xử lý đúng không)
cat > "$TEST_DIR/.htaccess" << 'EOF'
# This .htaccess file should be ignored by Nginx
RewriteEngine On
RewriteRule ^test/(.*)$ index.php?test=$1 [L,QSA]
EOF

# Set permissions
chown -R www-data:www-data "$TEST_DIR"
chmod -R 755 "$TEST_DIR"

log_success "Test files đã được tạo!"

# Lấy IP server
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "🧪 Testing URLs:"
echo "================"
echo ""
echo "1️⃣ **Basic test:**"
echo "   http://$SERVER_IP/"
echo ""
echo "2️⃣ **PHP Info:**"
echo "   http://$SERVER_IP/info.php"
echo ""
echo "3️⃣ **URL Rewriting tests:**"
echo "   http://$SERVER_IP/test/page"
echo "   http://$SERVER_IP/category/123"
echo "   http://$SERVER_IP/user/profile/456"
echo ""

# Test local requests
log_info "Testing local requests..."

echo ""
echo "📋 **Local Test Results:**"
echo "========================"

# Test 1: Basic index
echo -n "• Index page: "
if curl -s -o /dev/null -w "%{http_code}" "http://localhost/" | grep -q "200"; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
fi

# Test 2: PHP Info
echo -n "• PHP Info: "
if curl -s -o /dev/null -w "%{http_code}" "http://localhost/info.php" | grep -q "200"; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
fi

# Test 3: URL Rewriting
echo -n "• URL Rewrite (/test/page): "
if curl -s "http://localhost/test/page" | grep -q "REQUEST_URI"; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
fi

echo ""
echo "🔍 **Nginx Configuration Check:**"
echo "================================"

# Kiểm tra try_files
if grep -r "try_files.*index.php" /etc/nginx/sites-enabled/ > /dev/null 2>&1; then
    echo -e "• URL Rewriting: ${GREEN}✅ CONFIGURED${NC}"
else
    echo -e "• URL Rewriting: ${RED}❌ NOT CONFIGURED${NC}"
    echo "  Fix: Add 'try_files \$uri \$uri/ /index.php?\$query_string;' to your location / block"
fi

# Kiểm tra PHP handling
if grep -r "fastcgi_pass.*php.*fpm" /etc/nginx/sites-enabled/ > /dev/null 2>&1; then
    echo -e "• PHP-FPM: ${GREEN}✅ CONFIGURED${NC}"
else
    echo -e "• PHP-FPM: ${RED}❌ NOT CONFIGURED${NC}"
fi

echo ""
echo "🎯 **Summary:**"
echo "============="
echo "✅ Test files created in: $TEST_DIR"
echo "🌐 Access your server at: http://$SERVER_IP/"
echo "🔧 Test URL rewriting with the links on the page"
echo ""
echo "💡 **Troubleshooting:**"
echo "• If URL rewriting doesn't work, check /etc/nginx/sites-enabled/"
echo "• Make sure your site config has: try_files \$uri \$uri/ /index.php?\$query_string;"
echo "• Restart Nginx after config changes: sudo systemctl restart nginx"
echo ""
