#!/bin/bash
# Script: bai1_xin_chao.sh
# Mục đích: Nhập tên và in lời chào

read -p "Ban ten gi? " ten_nhap

if [ -z "$ten_nhap" ]; then
    echo "Ban chua nhap ten!"
    exit 1
fi

echo "Xin chao ${ten_nhap}."
