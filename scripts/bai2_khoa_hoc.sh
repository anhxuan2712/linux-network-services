#!/bin/bash
# Script: bai2_khoa_hoc.sh
# Mục đích: Nhập khóa học (D14, D15, D16, D17) và in ra năm học tương ứng

echo "=== TRA CUU THONG TIN KHOA HOC - DHDL ==="
read -p "Ban dang hoc khoa nao o truong Dien luc (D14, D15, D16, D17)? " khoa

khoa_upper=$(echo "$khoa" | tr '[:lower:]' '[:upper:]')

case "$khoa_upper" in
    "D17")
        echo "Ban dang hoc nam thu 1."
        ;;
    "D16")
        echo "Ban dang hoc nam thu 2."
        ;;
    "D15")
        echo "Ban dang hoc nam thu 3."
        ;;
    "D14")
        echo "Ban dang hoc nam thu 4."
        ;;
    *)
        echo "Khoa ban nhap ($khoa) khong hop le hoac nam ngoai danh sach D14 - D17."
        ;;
esac
