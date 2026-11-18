# HƯỚNG DẪN CẤU HÌNH DỊCH VỤ PHÂN GIẢI TÊN MIỀN DNS BIND9

> **Người phụ trách:** Nguyễn Minh Trí (TV3)  
> **Mục tiêu:** Thiết lập hệ thống phân giải tên miền nội bộ `lab.local` và phân giải ngược `10.168.192.in-addr.arpa`.

---

## 1. Cài đặt BIND9

```bash
sudo apt update
sudo apt install -y bind9 bind9utils dnsutils
```

## 2. Cấu hình Zone Files

1. **Khai báo zone trong `/etc/bind/named.conf.local`:**
   * Forward Zone: `lab.local`
   * Reverse Zone: `10.168.192.in-addr.arpa`
   *(Tham chiếu `configs/dns/named.conf.local`)*

2. **Tạo File cơ sở dữ liệu thuận (`configs/dns/db.lab.local`):**
   * Định tuyến `ns.lab.local`, `server.lab.local`, `web.lab.local` về IP `192.168.10.10`.

3. **Tạo File cơ sở dữ liệu nghịch (`configs/dns/db.10.168.192`):**
   * PTR Record phân giải từ `.10` về `ns.lab.local`.

## 3. Kiểm tra Cú pháp & Khởi động

```bash
sudo named-checkconf
sudo named-checkzone lab.local /etc/bind/zones/db.lab.local
sudo named-checkzone 10.168.192.in-addr.arpa /etc/bind/zones/db.10.168.192
sudo systemctl restart bind9
sudo systemctl status bind9
```

## 4. Kiểm thử từ Client

```bash
dig @192.168.10.10 web.lab.local +short
dig -x 192.168.10.10 +short
```
