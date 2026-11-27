#!/bin/bash
# Script tự động kiểm tra trạng thái toàn bộ dịch vụ trên Ubuntu Server (TV1)
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

echo "--- 1. Các dịch vụ mạng cốt lõi ---"
check_service ssh "OpenSSH Server (Port 22)"
check_service isc-dhcp-server "DHCP Server (Port 67/UDP)"
check_service bind9 "DNS Server BIND9 (Port 53)"
check_service nginx "Web Server & Reverse Proxy Nginx (Port 80)"

echo ""
echo "--- 2. Hệ thống giám sát tài nguyên (Monitoring) ---"
check_service prometheus "Prometheus Time-Series DB (localhost:9090)"
check_service prometheus-node-exporter "Node Exporter Metrics (localhost:9100)"
check_service grafana-server "Grafana Dashboard (localhost:3000 -> monitor.lab.local)"

echo ""
echo "=== 3. KIỂM TRA CỔNG DỊCH VỤ ĐANG LẮNG NGHE ==="
sudo ss -tuln | grep -E ':(22|53|67|80|3000|9090|9100)\b'

echo ""
echo "=== 4. KIỂM TRA TRẠNG THÁI TƯỜNG LỬA UFW ==="
sudo ufw status verbose
