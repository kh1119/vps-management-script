#!/bin/bash

# =============================================================================
# VPS Health Check Script (health_check.sh)
# Mục tiêu: Kiểm tra toàn bộ hệ thống và báo cáo trạng thái
# =============================================================================

set -e

# Import cấu hình nếu có
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    source "$SCRIPT_DIR/config.sh"
fi

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Biến global
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Hàm log
log_check() {
    local status="$1"
    local message="$2"
    local details="${3:-}"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case "$status" in
        "PASS")
            echo -e "✅ ${GREEN}PASS${NC} - $message"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            ;;
        "FAIL")
            echo -e "❌ ${RED}FAIL${NC} - $message"
            if [[ -n "$details" ]]; then
                echo -e "   ${RED}Details: $details${NC}"
            fi
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            ;;
        "WARN")
            echo -e "⚠️  ${YELLOW}WARN${NC} - $message"
            if [[ -n "$details" ]]; then
                echo -e "   ${YELLOW}Details: $details${NC}"
            fi
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            ;;
        "INFO")
            echo -e "ℹ️  ${BLUE}INFO${NC} - $message"
            ;;
    esac
}

# Kiểm tra hệ điều hành
check_os() {
    echo -e "\n${CYAN}=== KIỂM TRA HỆ ĐIỀU HÀNH ===${NC}"
    
    if [[ -f /etc/os-release ]]; then
        local os_name=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
        local os_version=$(grep '^VERSION=' /etc/os-release | cut -d'"' -f2)
        log_check "INFO" "OS: $os_name $os_version"
        
        if grep -q "Ubuntu 24.04" /etc/os-release; then
            log_check "PASS" "Hệ điều hành được hỗ trợ"
        else
            log_check "WARN" "Hệ điều hành chưa được test đầy đủ"
        fi
    else
        log_check "FAIL" "Không thể xác định hệ điều hành"
    fi
    
    # Kiểm tra uptime
    local uptime_info=$(uptime -p)
    log_check "INFO" "Uptime: $uptime_info"
    
    # Kiểm tra load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    log_check "INFO" "Load average:$load_avg"
}

# Kiểm tra tài nguyên hệ thống
check_resources() {
    echo -e "\n${CYAN}=== KIỂM TRA TÀI NGUYÊN ===${NC}"
    
    # RAM
    local ram_total=$(free -m | awk '/^Mem:/{print $2}')
    local ram_used=$(free -m | awk '/^Mem:/{print $3}')
    local ram_percent=$((ram_used * 100 / ram_total))
    
    log_check "INFO" "RAM: ${ram_used}MB / ${ram_total}MB (${ram_percent}%)"
    
    if [[ $ram_percent -lt 80 ]]; then
        log_check "PASS" "RAM usage trong mức bình thường"
    elif [[ $ram_percent -lt 90 ]]; then
        log_check "WARN" "RAM usage cao" "Consider optimizing services"
    else
        log_check "FAIL" "RAM usage rất cao" "Urgent action required"
    fi
    
    # Disk space
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
    local disk_total=$(df -h / | awk 'NR==2{print $2}')
    local disk_used=$(df -h / | awk 'NR==2{print $3}')
    
    log_check "INFO" "Disk: ${disk_used} / ${disk_total} (${disk_usage}%)"
    
    if [[ $disk_usage -lt 80 ]]; then
        log_check "PASS" "Disk space đủ"
    elif [[ $disk_usage -lt 90 ]]; then
        log_check "WARN" "Disk space thấp"
    else
        log_check "FAIL" "Disk space rất thấp" "Clean up required"
    fi
    
    # CPU
    local cpu_cores=$(nproc)
    log_check "INFO" "CPU Cores: $cpu_cores"
}

# Kiểm tra services
check_services() {
    echo -e "\n${CYAN}=== KIỂM TRA SERVICES ===${NC}"
    
    local services=("nginx" "mariadb" "redis-server" "php7.4-fpm" "php8.3-fpm" "ufw" "fail2ban")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_check "PASS" "$service đang chạy"
        else
            if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                log_check "FAIL" "$service đã enable nhưng không chạy"
            else
                log_check "WARN" "$service không được enable hoặc chưa cài đặt"
            fi
        fi
    done
}

# Kiểm tra network
check_network() {
    echo -e "\n${CYAN}=== KIỂM TRA NETWORK ===${NC}"
    
    # Internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_check "PASS" "Kết nối Internet"
    else
        log_check "FAIL" "Không có kết nối Internet"
    fi
    
    # DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        log_check "PASS" "DNS resolution"
    else
        log_check "FAIL" "DNS resolution không hoạt động"
    fi
    
    # UFW status
    if ufw status | grep -q "Status: active"; then
        log_check "PASS" "UFW Firewall đang hoạt động"
    else
        log_check "FAIL" "UFW Firewall không hoạt động"
    fi
    
    # Open ports
    local open_ports=$(ss -tlnp | grep LISTEN | wc -l)
    log_check "INFO" "Ports đang listen: $open_ports"
}

# Kiểm tra web server
check_webserver() {
    echo -e "\n${CYAN}=== KIỂM TRA WEB SERVER ===${NC}"
    
    # Nginx config test
    if nginx -t >/dev/null 2>&1; then
        log_check "PASS" "Nginx configuration syntax"
    else
        log_check "FAIL" "Nginx configuration có lỗi"
    fi
    
    # HTTP response
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301\|302"; then
        log_check "PASS" "HTTP response từ localhost"
    else
        log_check "FAIL" "Không thể kết nối HTTP localhost"
    fi
    
    # Nginx sites
    local enabled_sites=$(ls /etc/nginx/sites-enabled/ 2>/dev/null | grep -v default | wc -l)
    log_check "INFO" "Nginx sites enabled: $enabled_sites"
}

# Kiểm tra database
check_database() {
    echo -e "\n${CYAN}=== KIỂM TRA DATABASE ===${NC}"
    
    # MariaDB connection
    if mysql -e "SELECT 1;" >/dev/null 2>&1; then
        log_check "PASS" "MariaDB connection"
        
        # Database version
        local db_version=$(mysql -e "SELECT VERSION();" -s -N)
        log_check "INFO" "MariaDB version: $db_version"
        
        # Database count
        local db_count=$(mysql -e "SHOW DATABASES;" -s -N | grep -v -E '^(information_schema|performance_schema|mysql|sys)$' | wc -l)
        log_check "INFO" "User databases: $db_count"
        
    else
        log_check "FAIL" "Không thể kết nối MariaDB"
    fi
}

# Kiểm tra PHP
check_php() {
    echo -e "\n${CYAN}=== KIỂM TRA PHP ===${NC}"
    
    local php_versions=("7.4" "8.3")
    
    for version in "${php_versions[@]}"; do
        if command -v "php$version" >/dev/null 2>&1; then
            log_check "PASS" "PHP $version installed"
            
            if systemctl is-active --quiet "php$version-fpm"; then
                log_check "PASS" "PHP $version-FPM running"
            else
                log_check "FAIL" "PHP $version-FPM not running"
            fi
        else
            log_check "WARN" "PHP $version not installed"
        fi
    done
    
    # Default PHP
    if command -v php >/dev/null 2>&1; then
        local default_php=$(php --version | head -1)
        log_check "INFO" "Default PHP: $default_php"
    fi
}

# Kiểm tra Redis
check_redis() {
    echo -e "\n${CYAN}=== KIỂM TRA REDIS ===${NC}"
    
    if command -v redis-cli >/dev/null 2>&1; then
        if redis-cli ping >/dev/null 2>&1; then
            log_check "PASS" "Redis connection (no auth)"
        else
            # Try with auth from credentials file
            if [[ -f "/root/.my_script_credentials" ]]; then
                local redis_pass=$(grep "REDIS_PASSWORD" /root/.my_script_credentials 2>/dev/null | cut -d'=' -f2)
                if [[ -n "$redis_pass" ]] && redis-cli -a "$redis_pass" ping >/dev/null 2>&1; then
                    log_check "PASS" "Redis connection (with auth)"
                else
                    log_check "FAIL" "Redis connection failed"
                fi
            else
                log_check "FAIL" "Redis connection failed"
            fi
        fi
        
        # Redis memory usage
        local redis_memory=$(redis-cli info memory 2>/dev/null | grep used_memory_human: | cut -d: -f2 | tr -d '\r' || echo "N/A")
        log_check "INFO" "Redis memory usage: $redis_memory"
    else
        log_check "WARN" "Redis không được cài đặt"
    fi
}

# Kiểm tra SSL certificates
check_ssl() {
    echo -e "\n${CYAN}=== KIỂM TRA SSL CERTIFICATES ===${NC}"
    
    if command -v certbot >/dev/null 2>&1; then
        log_check "PASS" "Certbot installed"
        
        local cert_count=$(certbot certificates 2>/dev/null | grep "Certificate Name:" | wc -l)
        log_check "INFO" "SSL certificates: $cert_count"
        
        # Check expiring certificates (within 30 days)
        if [[ $cert_count -gt 0 ]]; then
            local expiring=$(certbot certificates 2>/dev/null | grep -A2 "Certificate Name:" | grep "VALID:" | awk '{print $4}' | while read date; do
                if [[ $(date -d "$date" +%s) -lt $(date -d "+30 days" +%s) ]]; then
                    echo "expiring"
                fi
            done | wc -l)
            
            if [[ $expiring -eq 0 ]]; then
                log_check "PASS" "Tất cả SSL certificates còn hạn > 30 ngày"
            else
                log_check "WARN" "$expiring SSL certificates sắp hết hạn (< 30 ngày)"
            fi
        fi
    else
        log_check "WARN" "Certbot chưa được cài đặt"
    fi
}

# Kiểm tra backup
check_backup() {
    echo -e "\n${CYAN}=== KIỂM TRA BACKUP ===${NC}"
    
    # Database backup script
    if [[ -f "/root/backup_databases.sh" ]]; then
        log_check "PASS" "Database backup script exists"
        
        if [[ -x "/root/backup_databases.sh" ]]; then
            log_check "PASS" "Database backup script executable"
        else
            log_check "FAIL" "Database backup script not executable"
        fi
    else
        log_check "WARN" "Database backup script missing"
    fi
    
    # Redis backup script
    if [[ -f "/root/backup_redis.sh" ]]; then
        log_check "PASS" "Redis backup script exists"
    else
        log_check "WARN" "Redis backup script missing"
    fi
    
    # Backup directory
    if [[ -d "/root/vps-management-script/backups" ]]; then
        local backup_size=$(du -sh /root/vps-management-script/backups 2>/dev/null | cut -f1)
        log_check "INFO" "Backup directory size: $backup_size"
    else
        log_check "WARN" "Backup directory missing"
    fi
    
    # Cron jobs
    local cron_count=$(crontab -l 2>/dev/null | grep -v "^#" | wc -l)
    log_check "INFO" "Cron jobs configured: $cron_count"
}

# Kiểm tra security
check_security() {
    echo -e "\n${CYAN}=== KIỂM TRA BẢO MẬT ===${NC}"
    
    # Credentials file permissions
    if [[ -f "/root/.my_script_credentials" ]]; then
        local perms=$(stat -c "%a" /root/.my_script_credentials)
        if [[ "$perms" == "600" ]]; then
            log_check "PASS" "Credentials file permissions secure (600)"
        else
            log_check "FAIL" "Credentials file permissions insecure ($perms)"
        fi
    else
        log_check "WARN" "Credentials file not found"
    fi
    
    # SSH configuration
    if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config; then
        log_check "WARN" "SSH root login enabled" "Consider disabling for security"
    else
        log_check "PASS" "SSH root login properly configured"
    fi
    
    # Failed login attempts
    local failed_attempts=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l || echo "0")
    if [[ $failed_attempts -gt 10 ]]; then
        log_check "WARN" "Multiple failed login attempts: $failed_attempts"
    else
        log_check "PASS" "Failed login attempts in normal range: $failed_attempts"
    fi
}

# Kiểm tra logs
check_logs() {
    echo -e "\n${CYAN}=== KIỂM TRA LOGS ===${NC}"
    
    local log_files=(
        "/var/log/nginx/error.log"
        "/var/log/mysql/error.log"
        "/var/log/php7.4-fpm-errors.log"
        "/var/log/php8.3-fpm-errors.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            local error_count=$(grep -i error "$log_file" 2>/dev/null | tail -100 | wc -l)
            if [[ $error_count -eq 0 ]]; then
                log_check "PASS" "$(basename "$log_file"): No recent errors"
            elif [[ $error_count -lt 10 ]]; then
                log_check "WARN" "$(basename "$log_file"): $error_count recent errors"
            else
                log_check "FAIL" "$(basename "$log_file"): $error_count recent errors"
            fi
        else
            log_check "WARN" "$(basename "$log_file"): Log file not found"
        fi
    done
}

# Tóm tắt kết quả
show_summary() {
    echo -e "\n${PURPLE}=== TÓM TẮT KẾT QUẢ ===${NC}"
    
    local total_score=0
    if [[ $TOTAL_CHECKS -gt 0 ]]; then
        total_score=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    fi
    
    echo "📊 Tổng số kiểm tra: $TOTAL_CHECKS"
    echo -e "✅ Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "⚠️  Warnings: ${YELLOW}$WARNING_CHECKS${NC}"
    echo -e "❌ Failed: ${RED}$FAILED_CHECKS${NC}"
    echo ""
    
    if [[ $total_score -ge 90 ]]; then
        echo -e "🎉 ${GREEN}EXCELLENT${NC} - Hệ thống hoạt động tốt ($total_score%)"
    elif [[ $total_score -ge 75 ]]; then
        echo -e "👍 ${YELLOW}GOOD${NC} - Hệ thống hoạt động ổn định ($total_score%)"
    elif [[ $total_score -ge 50 ]]; then
        echo -e "⚠️  ${YELLOW}FAIR${NC} - Cần chú ý một số vấn đề ($total_score%)"
    else
        echo -e "🚨 ${RED}POOR${NC} - Cần khắc phục nhiều vấn đề ($total_score%)"
    fi
    
    echo ""
    echo "🕒 Thời gian kiểm tra: $(date)"
    echo "💾 Log chi tiết: /root/vps-management-script/logs/health_check.log"
}

# Hàm chính
main() {
    echo -e "${BLUE}=============================================="
    echo -e "         VPS HEALTH CHECK REPORT"
    echo -e "==============================================${NC}"
    
    check_os
    check_resources
    check_services
    check_network
    check_webserver
    check_database
    check_php
    check_redis
    check_ssl
    check_backup
    check_security
    check_logs
    
    show_summary
}

# Chạy health check
main "$@" | tee -a "/root/vps-management-script/logs/health_check.log" 2>/dev/null || main "$@"
