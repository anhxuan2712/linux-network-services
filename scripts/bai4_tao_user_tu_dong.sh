#!/bin/bash
# Script: bai4_tao_user_tu_dong.sh
# Mục đích: Đọc danh sách username/password từ file và tự động tạo tài khoản trên Ubuntu

if [ "$EUID" -ne 0 ]; then
    echo "Loi: Vui long chay script voi quyen root (sudo ./bai4_tao_user_tu_dong.sh)"
    exit 1
fi

FILE_INPUT="danh_sach_user.txt"

if [ ! -f "$FILE_INPUT" ]; then
    echo "Loi: Khong tim thay file $FILE_INPUT!"
    exit 1
fi

echo "================================================="
echo "BAT DAU TIEN HANH TAO TAI KHOAN TU DONG TU FILE"
echo "================================================="

count=0

while IFS=':' read -r username password || [ -n "$username" ]; do
    [[ -z "$username" || "$username" =~ ^# ]] && continue

    username=$(echo "$username" | xargs)
    password=$(echo "$password" | xargs)

    if id "$username" &>/dev/null; then
        echo "[!] User '$username' da ton tai tren he thong. Bo qua..."
    else
        useradd -m -s /bin/bash "$username"
        echo "$username:$password" | chpasswd
        
        if [ $? -eq 0 ]; then
            echo "[+] Da tao thanh cong User: $username"
            ((count++))
        else
            echo "[-] Tao User $username that bai!"
        fi
    fi
done < "$FILE_INPUT"

echo "================================================="
echo "HOAN TAT! Tong so User da tao moi: $count"
echo "================================================="

echo "Danh sach 10 user vua tao trong /etc/passwd:"
tail -n 10 /etc/passwd
