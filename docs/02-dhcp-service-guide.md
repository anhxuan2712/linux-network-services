# HƯỚNG DẪN TRIỂN KHAI DỊCH VỤ DHCP SERVER (GIAI ĐOẠN 3)

> **Người phụ trách:** Nguyễn Phúc Vượng (TV2) — *Tích hợp thực tế bởi TV1*  
> **Mục tiêu:** Cấp phát địa chỉ IP tự động cho các máy trạm (Client) trong dải `192.168.10.100 - 150`.

---

## 1. Cài đặt Dịch vụ DHCP Server

```bash
sudo apt update
sudo apt install -y isc-dhcp-server
```

## 2. Chỉ định Interface lắng nghe (`enp10s0`)

```bash
sudo sed -i 's/^INTERFACESv4=.*/INTERFACESv4="enp10s0"/' /etc/default/isc-dhcp-server
grep INTERFACESv4 /etc/default/isc-dhcp-server
```

## 3. Cấu hình Tham số Cấp phát DHCP (`/etc/dhcp/dhcpd.conf`)

Sao lưu file gốc và nạp cấu hình (tham chiếu `configs/dhcp/dhcpd.conf`):
```bash
sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
sudo tee /etc/dhcp/dhcpd.conf << 'EOF'
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.10.0 netmask 255.255.255.0 {
    range 192.168.10.100 192.168.10.150;
    option routers 192.168.10.1;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 192.168.10.10, 8.8.8.8;
    option domain-name "lab.local";
}
EOF
```

Kiểm tra cú pháp và khởi động:
```bash
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
sudo systemctl enable --now isc-dhcp-server
sudo systemctl restart isc-dhcp-server
```

## 4. Xử lý xung đột DHCP của VMware Fusion

* Mạng *Private to my Mac* mặc định của VMware có DHCP tích hợp sẵn (`172.16.109.x`).
* **Cách xử lý chuẩn:** Vào **VMware Fusion $\rightarrow$ Settings (`Cmd + ,`) $\rightarrow$ Network**, tạo mạng Custom **`vmnet2`** (bỏ tích *Provide addresses on this network via DHCP* và NAT), sau đó chuyển card `enp10s0` của Server và `enp2s0` của Client sang **`vmnet2`**, rồi `sudo systemctl restart isc-dhcp-server`.

## 5. Kiểm thử Nghiệm thu (TC-04 & TC-05)

* **Trên Ubuntu Client (TC-04):**
  ```bash
  nmcli dev disconnect enp2s0 && nmcli dev connect enp2s0
  ip -4 a show enp2s0
  ```
  *Kết quả:* Nhận đúng `inet 192.168.10.100/24` (`valid_lft 600sec`).

* **Trên Ubuntu Server (TC-05):**
  ```bash
  cat /var/lib/dhcp/dhcpd.leases
  ```
  *Kết quả:* Ghi nhận `lease 192.168.10.100`, `binding state active`, MAC `00:0c:29:3a:fb:01`, `client-hostname "ubuntu-client"`.
