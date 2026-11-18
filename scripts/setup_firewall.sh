#!/bin/bash
# Script thiết lập nhanh chính sách tường lửa UFW
set -e

echo "[*] Thiết lập chính sách mặc định..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "[*] Mở các cổng dịch vụ doanh nghiệp..."
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 53 comment 'DNS'
sudo ufw allow 67/udp comment 'DHCP'
sudo ufw allow 80/tcp comment 'HTTP'

echo "[*] Kích hoạt tường lửa UFW..."
sudo ufw --force enable

echo "[+] Trạng thái tường lửa UFW hiện tại:"
sudo ufw status verbose
