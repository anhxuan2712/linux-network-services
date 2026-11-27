#!/bin/bash
# Script áp dụng cấu hình Netplan IP tĩnh cho Ubuntu Server (Giai đoạn 2 - TV1)
set -e

CONFIG_FILE="/etc/netplan/01-netcfg.yaml"
SOURCE_CONFIG="$(dirname "$0")/../configs/network/01-netplan.yaml"

echo "[1/4] Sao lưu các file Netplan cũ vào /etc/netplan/backup/..."
sudo mkdir -p /etc/netplan/backup
sudo mv /etc/netplan/*.yaml /etc/netplan/backup/ 2>/dev/null || true

echo "[2/4] Nạp cấu hình Netplan mới (NAT enp2s0 + IP tĩnh enp10s0 192.168.10.10/24)..."
sudo cp "$SOURCE_CONFIG" "$CONFIG_FILE"
sudo chmod 600 "$CONFIG_FILE"

echo "[3/4] Áp dụng cấu hình Netplan..."
sudo netplan apply

echo "[4/4] Hoàn tất! Kiểm tra IP trên card nội bộ enp10s0:"
ip -4 a show enp10s0
