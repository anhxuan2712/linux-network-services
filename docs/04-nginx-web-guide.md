# HƯỚNG DẪN CẤU HÌNH MÁY CHỦ WEB NGINX

> **Người phụ trách:** Nguyễn Minh Trí (TV3)  
> **Mục tiêu:** Cung cấp cổng thông tin nội bộ doanh nghiệp qua tên miền `http://web.lab.local`.

---

## 1. Cài đặt Nginx

```bash
sudo apt update
sudo apt install -y nginx
```

## 2. Thiết lập Virtual Host (Server Block)

* Tạo file cấu hình `/etc/nginx/sites-available/web.lab.local.conf` (tham chiếu `configs/nginx/web.lab.local.conf`):
  ```nginx
  server {
      listen 80;
      server_name web.lab.local;

      root /var/www/lab.local/html;
      index index.html;

      location / {
          try_files $uri $uri/ =404;
      }
  }
  ```

* Tạo thư mục web và copy mã nguồn HTML (`configs/nginx/html/index.html`):
  ```bash
  sudo mkdir -p /var/www/lab.local/html
  sudo cp configs/nginx/html/index.html /var/www/lab.local/html/
  sudo chown -R www-data:www-data /var/www/lab.local/html
  ```

* Kích hoạt site:
  ```bash
  sudo ln -s /etc/nginx/sites-available/web.lab.local.conf /etc/nginx/sites-enabled/
  ```

## 3. Kiểm tra Cú pháp & Khởi động

```bash
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl status nginx
```

## 4. Kiểm thử từ Client

```bash
curl -I http://web.lab.local
# Hoặc mở trình duyệt truy cập: http://web.lab.local
```
