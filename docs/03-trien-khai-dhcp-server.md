# GIAI ĐOẠN 3: TRIỂN KHAI DỊCH VỤ CẤP PHÁT IP TỰ ĐỘNG DHCP SERVER

> **Giai đoạn:** Giai đoạn 3 (Ngày 5–7)  
> **Người phụ trách:** Nguyễn Phúc Vượng (TV2) — *Tích hợp & nghiệm thu thực tế trên hệ thống bởi TV1*  
> **Test Cases nghiệm thu:** **TC-04** (Client nhận IP động), **TC-05** (Bảng cấp phát Lease)  
> **File cấu hình liên quan:** `configs/dhcp/dhcpd.conf`, `scripts/check_dhcp_leases.sh`

---

## Bước 1: Cài đặt gói `isc-dhcp-server` trên Ubuntu Server

```bash
sudo apt update
sudo apt install -y isc-dhcp-server
```

---

## Bước 2: Chỉ định card mạng lắng nghe cố định (`enp10s0`)

Chỉ cho DHCP Server lắng nghe trên card mạng nội bộ `enp10s0` (tuyệt đối không phát DHCP ra card NAT `enp2s0`):

```bash
sudo sed -i 's/^INTERFACESv4=.*/INTERFACESv4="enp10s0"/' /etc/default/isc-dhcp-server
grep INTERFACESv4 /etc/default/isc-dhcp-server
# Kết quả bắt buộc: INTERFACESv4="enp10s0"
```

---

## Bước 3: Nạp cấu hình dải IP cấp phát (`/etc/dhcp/dhcpd.conf`)

Sao lưu file gốc và áp dụng cấu hình chuẩn (tham chiếu `configs/dhcp/dhcpd.conf`):

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

Kiểm tra cú pháp cấu hình và khởi động dịch vụ:

```bash
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
sudo systemctl enable --now isc-dhcp-server
sudo systemctl restart isc-dhcp-server
sudo systemctl status isc-dhcp-server
```
* *Kiểm tra log:* Phải thấy `Listening on LPF/enp10s0/...` và trạng thái `active (running)`.

---

## Bước 4: Xử lý xung đột với DHCP tích hợp sẵn của VMware Fusion

> **Sự cố thực tế cần xử lý:** Mạng *Private to my Mac* (`vmnet1`) mặc định của VMware Fusion có bật sẵn DHCP Server nội bộ (cấp dải `172.16.109.x`). Nếu giữ nguyên, Ubuntu Client sẽ nhận nhầm IP của VMware thay vì của Ubuntu Server.

**Quy trình xử lý triệt để:**
1. Trên thanh menu máy Mac: **VMware Fusion $\rightarrow$ Settings (`Cmd + ,`) $\rightarrow$ tab Network**.
2. Bấm biểu tượng **ổ khóa** nhập mật khẩu Mac $\rightarrow$ bấm dấu **`+`** tạo mạng Custom **`vmnet2`**.
3. Chọn `vmnet2`, **BỎ TÍCH** cả 2 ô:
   * `Allow virtual machines on this network to connect to external networks (using NAT)`
   * `Provide addresses on this network via DHCP`
4. Bấm **Apply**.
5. Chuyển card mạng nội bộ của cả **Ubuntu Server** (đối chiếu đúng địa chỉ MAC của `enp10s0` qua `ip -br link`) và **Ubuntu Client** (`enp2s0`) sang **`vmnet2`**.
6. Khởi động lại dịch vụ DHCP trên Server:
   ```bash
   sudo systemctl restart isc-dhcp-server
   ```

---

## Bước 5: Kiểm thử nghiệm thu từ Client & Server (TC-04 & TC-05)

1. **Trên Ubuntu Client (TC-04) — Ngắt/kết nối lại mạng để chạy tiến trình DORA:**
   ```bash
   nmcli dev disconnect enp2s0 && nmcli dev connect enp2s0
   ip -4 a show enp2s0
   ```
   * **Kết quả đạt (TC-04):** Nhận đúng `inet 192.168.10.100/24` (thuộc dải `100–150`), thời gian thuê động (`valid_lft ~600sec`).

2. **Trên Ubuntu Server (TC-05) — Kiểm tra sổ nhật ký cấp phát Lease:**
   ```bash
   cat /var/lib/dhcp/dhcpd.leases
   # Hoặc chạy script lọc đẹp: ./scripts/check_dhcp_leases.sh
   ```
   * **Kết quả đạt (TC-05):** Ghi nhận `lease 192.168.10.100`, `binding state active`, địa chỉ MAC `00:0c:29:3a:fb:01` và `client-hostname "ubuntu-client"`.

---

## Minh chứng nghiệm thu đã lưu
* **TC-04:** `evidence/dhcp/tc04-client-dhcp-ip.jpg`
* **TC-05:** `evidence/dhcp/tc05-server-dhcp-leases.jpg`
