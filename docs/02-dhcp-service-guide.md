# HƯỚNG DẪN TRIỂN KHAI DỊCH VỤ DHCP SERVER

> **Người phụ trách:** Nguyễn Phúc Vượng (TV2)  
> **Mục tiêu:** Cấp phát địa chỉ IP tự động cho các máy trạm (Client) trong dải `192.168.10.100 - 150`.

---

## 1. Cài đặt Dịch vụ DHCP Server

```bash
sudo apt update
sudo apt install -y isc-dhcp-server
```

## 2. Chỉ định Interface lắng nghe

Chỉnh sửa file `/etc/default/isc-dhcp-server`:
```bash
INTERFACESv4="ens33"   # Thay thế bằng tên interface của bạn
```

## 3. Cấu hình Tham số Cấp phát DHCP

Chỉnh sửa file `/etc/dhcp/dhcpd.conf` (tham chiếu `configs/dhcp/dhcpd.conf`):
* Subnet: `192.168.10.0`
* Netmask: `255.255.255.0`
* Range: `192.168.10.100` đến `192.168.10.150`
* Routers (Gateway): `192.168.10.1`
* Domain-name-servers: `192.168.10.10`
* Domain-name: `"lab.local"`

## 4. Khởi động và Kiểm tra Dịch vụ

```bash
sudo systemctl restart isc-dhcp-server
sudo systemctl status isc-dhcp-server
```

* **Kiểm tra danh sách IP đang cho thuê:**
  ```bash
  cat /var/lib/dhcp/dhcpd.leases
  ```
