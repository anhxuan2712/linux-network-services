#!/bin/bash
# Script áp dụng cấu hình Netplan IP tĩnh cho Server
set -e

CONFIG_FILE="/etc/netplan/01-netcfg.yaml"
SOURCE_CONFIG="$(dirname "$0")/../configs/network/01-netplan.yaml"

echo "[*] Sao lưu file Netplan hiện tại..."
sudo cp /etc/netplan/*.yaml /etc/netplan/backup_netplan.yaml.bak 2>/dev/null || true

echo "[*] Áp dụng file cấu hình mới..."
sudo cp "$SOURCE_CONFIG" "$CONFIG_FILE"
sudo chmod 600 "$CONFIG_FILE"

echo "[*] Chạy netplan apply..."
sudo netplan apply

echo "[+] Cấu hình IP thành công:"
ip -4 a show
