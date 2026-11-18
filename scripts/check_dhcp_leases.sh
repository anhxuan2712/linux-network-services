#!/bin/bash
# Script kiểm tra danh sách máy Client đang thuê IP từ DHCP Server
LEASE_FILE="/var/lib/dhcp/dhcpd.leases"

echo "=== DANH SÁCH CLIENT ĐANG THUÊ IP (DHCP LEASES) ==="
if [ ! -f "$LEASE_FILE" ]; then
    echo "[-] Chưa tìm thấy file lease tại $LEASE_FILE (Dịch vụ chưa chạy hoặc chưa có client xin IP)."
    exit 1
fi

grep -E "lease|hardware ethernet|client-hostname|ends" "$LEASE_FILE" | awk '
/lease/ { ip=$2 }
/hardware ethernet/ { mac=$3; gsub(";", "", mac) }
/client-hostname/ { host=$2; gsub(";", "", host); gsub("\"", "", host) }
/ends/ { end=$3 " " $4; gsub(";", "", end); if (ip != "") { printf "%-16s | %-18s | %-20s\n", ip, mac, host; ip=""; mac=""; host="" } }
' | sort -u
