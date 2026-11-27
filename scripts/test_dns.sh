#!/bin/bash
# Script tự động kiểm tra phân giải tên miền DNS BIND9 (Giai đoạn 4 - TV3)
DNS_SERVER="192.168.10.10"

echo "=== 1. KIỂM TRA PHÂN GIẢI THUẬN (FORWARD RESOLUTION) ==="
for DOMAIN in web.lab.local monitor.lab.local ns.lab.local server.lab.local; do
    RESULT=$(dig @"$DNS_SERVER" "$DOMAIN" +short)
    echo "[*] $DOMAIN -> $RESULT"
done

echo ""
echo "=== 2. KIỂM TRA PHÂN GIẢI NGHỊCH (REVERSE RESOLUTION) ==="
echo "[*] $DNS_SERVER ->"
dig @"$DNS_SERVER" -x "$DNS_SERVER" +short
