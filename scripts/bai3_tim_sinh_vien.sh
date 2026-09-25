#!/bin/bash
# Script: bai3_tim_sinh_vien.sh
# Mục đích: Tìm kiếm sinh viên trong danh sách mảng

danh_sach_sv=(
    "Nguyen Van An"
    "Tran Thi Bich"
    "Le Hoang Cuong"
    "Pham Duc Duy"
    "Hoang Minh Em"
    "Dang Ngoc Giang"
)

echo "=== DANH SACH SINH VIEN HIEN CO ==="
for sv in "${danh_sach_sv[@]}"; do
    echo " - $sv"
done
echo "==================================="

read -p "Nhap ten sinh vien can tim: " ten_can_tim

tim_thay=0

for sv in "${danh_sach_sv[@]}"; do
    if [[ "${sv,,}" == *"${ten_can_tim,,}"* ]]; then
        tim_thay=1
        break
    fi
done

if [ $tim_thay -eq 1 ]; then
    echo "Ket qua: Co sinh vien \"$ten_can_tim\" trong danh sach."
else
    echo "Ket qua: Khong co sinh vien \"$ten_can_tim\" trong danh sach."
fi
