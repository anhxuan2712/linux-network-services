# HƯỚNG DẪN CẤU HÌNH TƯỜNG LỬA UFW & AN TOÀN HỆ THỐNG

> **Người phụ trách:** Nguyễn Thành Đạt (TV4)  
> **Mục tiêu:** Áp dụng nguyên tắc đặc quyền tối thiểu (Least Privilege), chỉ mở các cổng dịch vụ cần thiết (22, 53, 67, 80) và chặn toàn bộ truy cập lạ.

---

## 1. Nguyên tắc Bảo mật

* **Default Incoming Policy:** Chặn toàn bộ luồng vào (`DEFAULT DENY`).
* **Default Outgoing Policy:** Cho phép các luồng đi ra (`DEFAULT ALLOW`).

## 2. Các cổng dịch vụ được phép mở

| Cổng | Giao thức | Dịch vụ | Lệnh cấu hình |
|---|---|---|---|
| **22** | TCP | SSH | `sudo ufw allow 22/tcp` |
| **53** | UDP & TCP | DNS BIND9 | `sudo ufw allow 53` |
| **67** | UDP | DHCP Server | `sudo ufw allow 67/udp` |
| **80** | TCP | HTTP Web Nginx | `sudo ufw allow 80/tcp` |

## 3. Các bước triển khai

```bash
# 1. Đặt chính sách mặc định
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 2. Mở cổng dịch vụ
sudo ufw allow 22/tcp comment 'Allow OpenSSH'
sudo ufw allow 53 comment 'Allow DNS'
sudo ufw allow 67/udp comment 'Allow DHCP'
sudo ufw allow 80/tcp comment 'Allow HTTP Nginx'

# 3. Kích hoạt tường lửa
sudo ufw --force enable

# 4. Kiểm tra trạng thái chi tiết
sudo ufw status verbose
```
