#!/bin/bash
# ==============================================================================
# Script: setup_monitoring.sh
# Tác giả: Nguyễn Anh Xuân (TV1 - Leader)
# Mục đích: Tự động cài đặt Prometheus, Node Exporter, Grafana & Nginx Reverse Proxy
# ==============================================================================
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=================================================================="
echo "   TRIỂN KHAI GIÁM SÁT PROMETHEUS + GRAFANA (GIAI ĐOẠN 6 - TV1)   "
echo "=================================================================="

echo "[1/5] Cài đặt Prometheus & Node Exporter..."
sudo apt update
sudo apt install -y prometheus prometheus-node-exporter apt-transport-https software-properties-common wget gpg
sudo systemctl enable --now prometheus prometheus-node-exporter

echo "[2/5] Cài đặt Grafana từ kho chính thức..."
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update && sudo apt install -y grafana
sudo systemctl enable --now grafana-server

echo "[3/5] Cập nhật bản ghi DNS monitor.lab.local..."
if ! grep -q "^monitor" /etc/bind/zones/db.lab.local; then
    echo "monitor IN      A       192.168.10.10" | sudo tee -a /etc/bind/zones/db.lab.local > /dev/null
fi
sudo named-checkzone lab.local /etc/bind/zones/db.lab.local
sudo systemctl restart bind9

echo "[4/5] Cấu hình Nginx Reverse Proxy cho http://monitor.lab.local..."
sudo cp "$REPO_DIR/configs/nginx/monitor.lab.local.conf" /etc/nginx/sites-available/monitor.lab.local.conf
sudo ln -sf /etc/nginx/sites-available/monitor.lab.local.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

echo "[5/5] Hoàn tất! Trạng thái 3 dịch vụ giám sát:"
systemctl is-active prometheus prometheus-node-exporter grafana-server
echo "Truy cập từ Client: http://monitor.lab.local (admin/admin, Dashboard ID: 1860)"
