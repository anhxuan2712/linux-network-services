#!/bin/bash
# Script tự động kiểm tra trạng thái toàn bộ dịch vụ trên Server
echo "=========================================================="
echo "    BẢNG KIỂM TRA TRẠNG THÁI HỆ THỐNG MẠNG UBUNTU SERVER    "
echo "=========================================================="

check_service() {
    local svc=$1
    local name=$2
    if systemctl is-active --quiet "$svc"; then
        echo -e "[ PASS ] $name ($svc) đang chạy bình thường."
    else
        echo -e "[ FAIL ] $name ($svc) chưa khởi động hoặc gặp lỗi!"
    fi
}

check_service ssh "OpenSSH Server"
check_service isc-dhcp-server "DHCP Server"
check_service bind9 "DNS Server BIND9"
check_service nginx "Web Server Nginx"

echo ""
echo "=== KIỂM TRA CỔNG DỊCH VỤ ĐANG LẮNG NGHE ==="
sudo ss -tuln | grep -E ':(22|53|67|80)'

echo ""
echo "=== KIỂM TRA TRẠNG THÁI TƯỜNG LỬA UFW ==="
sudo ufw status verbose
