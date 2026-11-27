# GIAI ĐOẠN 4: TRIỂN KHAI DNS SERVER BIND9 & MÁY CHỦ WEB NGINX

> **Giai đoạn:** Giai đoạn 4 (Ngày 8–9)  
> **Người phụ trách:** Nguyễn Minh Trí (TV3) — *Tích hợp & nghiệm thu thực tế trên hệ thống bởi TV1*  
> **Test Cases nghiệm thu:** **TC-06** (DNS thuận), **TC-07** (DNS nghịch), **TC-08** (Web qua IP), **TC-09** (Web qua Domain)  
> **File cấu hình liên quan:** `configs/dns/*`, `configs/nginx/web.lab.local.conf`, `configs/nginx/html/index.html`, `scripts/test_dns.sh`

---

## PHẦN A: TRIỂN KHAI DỊCH VỤ PHÂN GIẢI TÊN MIỀN DNS BIND9 (TC-06, TC-07)

### Bước 1: Cài đặt BIND9 trên Ubuntu Server
```bash
sudo apt update
sudo apt install -y bind9 bind9utils dnsutils
```

### Bước 2: Cấu hình chuyển tiếp & khai báo Zone (`/etc/bind/`)
1. **Cấu hình `named.conf.options`** (chỉ cho phép `localhost` và mạng LAN `192.168.10.0/24` truy vấn, chuyển tiếp tên miền ngoài qua `8.8.8.8`):
   ```bash
   sudo tee /etc/bind/named.conf.options << 'EOF'
   options {
       directory "/var/cache/bind";
       allow-query { localhost; 192.168.10.0/24; };
       forwarders {
           8.8.8.8;
           8.8.4.4;
       };
       dnssec-validation auto;
       listen-on-v6 { any; };
   };
   EOF
   ```

2. **Khai báo Forward Zone và Reverse Zone trong `named.conf.local`:**
   ```bash
   sudo tee /etc/bind/named.conf.local << 'EOF'
   zone "lab.local" {
       type master;
       file "/etc/bind/zones/db.lab.local";
   };

   zone "10.168.192.in-addr.arpa" {
       type master;
       file "/etc/bind/zones/db.10.168.192";
   };
   EOF
   ```

### Bước 3: Tạo 2 file Zone (Thuận & Nghịch) tại `/etc/bind/zones/`
```bash
sudo mkdir -p /etc/bind/zones

# Forward Zone: db.lab.local (bao gồm cả monitor.lab.local cho Giai đoạn 6)
sudo tee /etc/bind/zones/db.lab.local << 'EOF'
$TTL    604800
@       IN      SOA     ns.lab.local. admin.lab.local. (
                              4         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.lab.local.
ns      IN      A       192.168.10.10
server  IN      A       192.168.10.10
web     IN      A       192.168.10.10
monitor IN      A       192.168.10.10
EOF

# Reverse Zone: db.10.168.192
sudo tee /etc/bind/zones/db.10.168.192 << 'EOF'
$TTL    604800
@       IN      SOA     ns.lab.local. admin.lab.local. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.lab.local.
10      IN      PTR     ns.lab.local.
10      IN      PTR     server.lab.local.
10      IN      PTR     web.lab.local.
EOF
```

### Bước 4: Kiểm tra cú pháp, khởi động và kiểm thử DNS (TC-06, TC-07)
* **Trên Ubuntu Server:**
  ```bash
  sudo named-checkconf
  sudo named-checkzone lab.local /etc/bind/zones/db.lab.local
  sudo named-checkzone 10.168.192.in-addr.arpa /etc/bind/zones/db.10.168.192
  sudo systemctl enable --now bind9 && sudo systemctl restart bind9
  ```
* **Trên Ubuntu Client:**
  ```bash
  dig web.lab.local +short                  # TC-06 -> 192.168.10.10
  dig @192.168.10.10 -x 192.168.10.10 +short # TC-07 -> ns.lab.local., web.lab.local., server.lab.local.
  ```

---

## PHẦN B: TRIỂN KHAI MÁY CHỦ WEB NGINX (TC-08, TC-09)

### Bước 1: Cài đặt Nginx và nạp mã nguồn Website nội bộ
```bash
sudo apt update && sudo apt install -y nginx
sudo mkdir -p /var/www/lab.local/html
sudo cp configs/nginx/html/index.html /var/www/lab.local/html/index.html
sudo chown -R www-data:www-data /var/www/lab.local/html
```

### Bước 2: Cấu hình Virtual Host (`web.lab.local.conf`) và tắt site mặc định
> **Lưu ý kỹ thuật:** Gắn `default_server` và xóa `/etc/nginx/sites-enabled/default` để dù truy cập bằng IP (`http://192.168.10.10` — TC-08) hay bằng tên miền (`http://web.lab.local` — TC-09) đều hiển thị trang web của nhóm thay vì trang *"Welcome to nginx!"*.

```bash
sudo cp configs/nginx/web.lab.local.conf /etc/nginx/sites-available/web.lab.local.conf
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/web.lab.local.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl enable --now nginx && sudo systemctl restart nginx
```

### Bước 3: Kiểm thử truy cập Web từ Ubuntu Client (TC-08, TC-09)
1. **Kiểm tra qua dòng lệnh bằng `wget` (có sẵn trên Ubuntu Desktop):**
   ```bash
   wget -S --spider http://192.168.10.10   # TC-08 -> HTTP/1.1 200 OK
   wget -S --spider http://web.lab.local   # TC-09 -> Resolving -> 192.168.10.10 -> HTTP/1.1 200 OK
   ```
2. **Kiểm tra trực quan trên trình duyệt Firefox của Ubuntu Client:**
   * Truy cập `http://web.lab.local` $\rightarrow$ hiển thị đầy đủ giao diện giới thiệu đề tài, các dịch vụ và danh sách 4 thành viên.

---

## Minh chứng nghiệm thu đã lưu
* **TC-06 & TC-07:** `evidence/dns/tc06-tc07-dns-resolution.jpg`
* **TC-08 & TC-09:** `evidence/web/tc08-tc09-nginx-wget.jpg`, `evidence/web/tc09-firefox-web-lab-local.jpg`
