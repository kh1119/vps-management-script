# Config Import Standardization

## 🔧 Đã sửa lỗi import config.sh không đồng nhất

### ❌ Vấn đề trước khi sửa:

1. **Modules** sử dụng path phức tạp và dễ lỗi:
   ```bash
   source "$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")/config.sh"
   ```

2. **install_ubt_24.sh** sử dụng cách khác:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/config.sh"
   ```

3. **health_check.sh** có điều kiện riêng:
   ```bash
   if [[ -f "$(dirname "${BASH_SOURCE[0]}")/config.sh" ]]; then
       source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
   fi
   ```

4. **Các file khác** định nghĩa riêng log functions thay vì import từ config.sh

### ✅ Giải pháp đã áp dụng:

#### 1. **Thêm log functions vào config.sh**
```bash
# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1" >&2
    fi
}
```

#### 2. **Standardize import cho modules**
Tất cả files trong `modules/ubuntu/24/` giờ sử dụng:
```bash
# Import cấu hình
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
source "$SCRIPT_ROOT/config.sh"
```

#### 3. **Standardize import cho root scripts**
Files trong thư mục root sử dụng:
```bash
# Import cấu hình
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
```

#### 4. **health_check.sh với error handling**
```bash
# Import cấu hình nếu có
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    source "$SCRIPT_DIR/config.sh"
fi
```

#### 5. **install_ubt_24.sh extend log functions**
Giữ lại tính năng log_with_timestamp:
```bash
# Extend log functions to include timestamp logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_with_timestamp "[INFO] $1"
}
```

### 📋 Files đã được cập nhật:

1. ✅ **config.sh** - Thêm log functions và helper functions
2. ✅ **modules/ubuntu/24/00_prepare_system.sh** - Standardized import
3. ✅ **modules/ubuntu/24/01_install_nginx.sh** - Standardized import
4. ✅ **modules/ubuntu/24/02_install_mariadb.sh** - Standardized import
5. ✅ **modules/ubuntu/24/03_install_php.sh** - Standardized import
6. ✅ **modules/ubuntu/24/04_install_redis.sh** - Standardized import
7. ✅ **modules/ubuntu/24/05_install_tools.sh** - Standardized import
8. ✅ **modules/ubuntu/24/10_manage_website.sh** - Standardized import
9. ✅ **install_ubt_24.sh** - Enhanced log functions
10. ✅ **health_check.sh** - Standardized import with error handling

### 🎯 Kết quả:

- ✅ **Nhất quán**: Tất cả files giờ import config.sh theo cách chuẩn
- ✅ **Dễ bảo trì**: Không còn path phức tạp, dễ debug
- ✅ **An toàn**: Có error handling cho trường hợp không tìm thấy config.sh
- ✅ **Tương thích**: Giữ lại tính năng đặc biệt của install_ubt_24.sh
- ✅ **Centralized**: Tất cả log functions và config ở một nơi

### 🚀 Lợi ích:

1. **Dễ debug**: Khi có lỗi import, dễ dàng tìm nguyên nhân
2. **Consistency**: Tất cả files hoạt động giống nhau
3. **Maintainability**: Sửa config một lần, tất cả files đều được cập nhật
4. **Scalability**: Thêm modules mới dễ dàng với pattern chuẩn
5. **Reliability**: Giảm nguy cơ lỗi path resolution

### 🔍 Testing:

Để test xem import có hoạt động đúng không:
```bash
# Test module
bash -c "cd modules/ubuntu/24 && source 00_prepare_system.sh && echo 'Config loaded: $SCRIPT_NAME'"

# Test root script
bash -c "source install_ubt_24.sh --help"

# Test health check
bash -c "source health_check.sh && echo 'Health check can access config'"
```
