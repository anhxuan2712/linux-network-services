#!/bin/bash
# Script tự động kiểm tra phân giải tên miền DNS BIND9
DNS_SERVER="192.168.10.10"
DOMAIN="web.lab.local"

echo "=== KIỂM TRA PHÂN GIẢI THUẬN (FORWARD RESOLUTION) ==="
echo "[*] Truy vấn dig @$DNS_SERVER $DOMAIN..."
dig @"$DNS_SERVER" "$DOMAIN" +noall +answer

echo ""
echo "=== KIỂM TRA PHÂN GIẢI NGHỊCH (REVERSE RESOLUTION) ==="
echo "[*] Truy vấn dig -x @$DNS_SERVER $DNS_SERVER..."
dig @"$DNS_SERVER" -x "$DNS_SERVER" +noall +answer
