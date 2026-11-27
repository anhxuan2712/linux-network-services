# GIAI ĐOẠN 5: THIẾT LẬP TƯỜNG LỬA UFW & KIỂM THỬ AN TOÀN MẠNG

> **Giai đoạn:** Giai đoạn 5 (Ngày 10–11)  
> **Người phụ trách:** Nguyễn Thành Đạt (TV4) — *Đã merge nhánh `nguyen_thanh_dat` & nghiệm thu trực tiếp trên Server bởi TV1*  
> **Test Case nghiệm thu:** **TC-10** (Chính sách Firewall UFW & chặn cổng trái phép)  
> **File cấu hình liên quan:** `configs/firewall/ufw-rules.txt`, `scripts/setup_firewall.sh`

---

## 1. Ma trận cổng bảo mật (Least Privilege Policy)

* **Default Incoming:** `DENY` (Chặn toàn bộ kết nối đi vào chưa được cấp phép).
* **Default Outgoing:** `ALLOW` (Cho phép máy chủ chủ động gửi gói tin ra ngoài).

| Cổng | Giao thức | Dịch vụ | Quyền | Ghi chú |
|---|---|---|---|---|
| **22** | TCP | OpenSSH Server | `ALLOW IN` | Quản trị dòng lệnh từ xa |
| **53** | TCP & UDP | DNS Server BIND9 | `ALLOW IN` | Phân giải tên miền `lab.local` |
| **67** | UDP | DHCP Server | `ALLOW IN` | Tiếp nhận yêu cầu cấp phát IP |
| **80** | TCP | Nginx Web & Reverse Proxy | `ALLOW IN` | Phục vụ `web.lab.local` và `monitor.lab.local` |
| **Các cổng khác** | Tất cả | Telnet (23), 8080, Grafana (3000), Prometheus (9090), Node Exporter (9100)... | **`DENY / DROP`** | Chặn âm thầm từ mạng ngoài |

> **Điểm sáng bảo mật:** Hệ thống giám sát Prometheus (`9090`), Node Exporter (`9100`) và Grafana (`3000`) được phục vụ qua **Nginx Reverse Proxy trên Port 80**, nên hoàn toàn **không cần mở thêm bất kỳ cổng lạ nào trên UFW**.

---

## 2. Quy trình triển khai thực tế trên Ubuntu Server

1. **Clone kho mã nguồn về Ubuntu Server và cấp quyền thực thi script:**
   ```bash
   git clone https://github.com/anhxuan2712/linux-network-services.git
   cd linux-network-services
   chmod +x scripts/*.sh
   ```

2. **Chạy script tự động `scripts/setup_firewall.sh` của TV4:**
   ```bash
   ./scripts/setup_firewall.sh
   ```
   Script thực hiện tuần tự 5 bước:
   1. `sudo ufw --force reset` — Xóa luật cũ tránh xung đột.
   2. `sudo ufw default deny incoming` & `sudo ufw default allow outgoing` — Đặt chính sách mặc định.
   3. Mở 4 cổng dịch vụ: `22/tcp`, `53`, `67/udp`, `80/tcp` kèm comment tiếng Việt rõ ràng.
   4. `sudo ufw --force enable` — Kích hoạt tường lửa và tự khởi chạy cùng hệ thống.
   5. `sudo ufw status verbose` — Hiển thị bảng luật đang hoạt động.

---

## 3. Kiểm thử nghiệm thu từ Ubuntu Client (TC-10)

1. **Chứng minh các cổng hợp lệ (22, 80) thông suốt và cổng lạ (23, 8080) bị chặn đứng:**
   ```bash
   nc -zv -w 2 192.168.10.10 22 80 23 8080
   ```
   * **Kết quả đạt (TC-10):**
     * `192.168.10.10 22 port [tcp/ssh] succeeded!`
     * `192.168.10.10 80 port [tcp/http] succeeded!`
     * `port 23 (tcp) timed out` (Bị UFW drop âm thầm)
     * `port 8080 (tcp) timed out` (Bị UFW drop âm thầm)

2. **Kiểm tra lại DNS và Web vẫn hoạt động bình thường sau khi bật tường lửa:**
   ```bash
   dig web.lab.local +short
   wget -S --spider http://web.lab.local
   ```

---

## Minh chứng nghiệm thu đã lưu
* **Ảnh test thực tế trên Server & Client tích hợp:** `evidence/firewall/tc10-real-ufw-status.jpg`, `evidence/firewall/tc10-real-nc-port-block.jpg`
* **Ảnh test độc lập của TV4:** `evidence/firewall/tc10-ufw-status.png`, `evidence/firewall/port-scan-blocked.png`
