#!/bin/bash
# ========================================================
# Script: setup_firewall.sh
# Tac gia: Nguyen Thanh Dat (TV4)
# Muc dich: Thiet lap tu dong Tuong lua UFW chuan doanh nghiep
# ========================================================

echo "===================================================="
echo "   KHOI TAO CHINH SACH TUONG LUA UFW (TV4 - DAT)    "
echo "===================================================="

# 1. Reset UFW ve trang thai trang de tranh xung dot rule cu
echo "[1/5] Reset toan bo quy tac UFW cu..."
sudo ufw --force reset

# 2. Thiet lap chinh sach mac dinh (Nguyen tac Dac quyen toi thieu)
echo "[2/5] Thiet lap chinh sach Default Deny Incoming..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 3. Mo cac cong cho 4 dich vu cot loi
echo "[3/5] Mo 4 cong dich vu theo thiet ke de tai..."
sudo ufw allow 22/tcp comment 'Quan tri tu xa OpenSSH'
sudo ufw allow 53 comment 'Phan giai ten mien DNS BIND9'
sudo ufw allow 67/udp comment 'Cap phat IP DHCP Server'
sudo ufw allow 80/tcp comment 'Truy cap Web Nginx'

# 4. Kich hoat Tuong lua
echo "[4/5] Kich hoat tuong lua UFW..."
sudo ufw --force enable

# 5. Kiem tra trang thai sau khi cau hinh
echo "[5/5] Hoan tat! Danh sach rules dang hoat dong:"
echo "----------------------------------------------------"
sudo ufw status verbose
echo "===================================================="
