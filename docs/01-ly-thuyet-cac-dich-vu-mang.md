# GIAI ĐOẠN 1: NGHIÊN CỨU CƠ SỞ LÝ THUYẾT CÁC DỊCH VỤ MẠNG & GIÁM SÁT

> **Giai đoạn:** Giai đoạn 1 (Ngày 1–2 — Nghiên cứu tiền triển khai)  
> **Người phụ trách:** Cả 4 thành viên (TV1: Nguyễn Anh Xuân điều phối)  
> **Mục đích:** Tổng hợp đầy đủ cơ sở lý thuyết, nguyên lý hoạt động, cơ chế xử lý gói tin và chuẩn giao thức của toàn bộ hệ thống trước khi triển khai thực tế. Dùng trực tiếp cho **Chương 2 (Cơ sở lý thuyết)** của Báo cáo tổng kết.

---

## TÓM TẮT TRỰC QUAN: HỆ THỐNG MẠNG NHÌN TỪ "ĐỜI THỰC" (ĐỌC 2 PHÚT LÀ HIỂU)

Hãy hình dung toàn bộ hệ thống mạng của đề tài giống như việc vận hành một **Tòa nhà Văn phòng Doanh nghiệp**:

| Thành phần kỹ thuật | Hình tượng đời thực | Vai trò trong hệ thống | Thành viên |
|---|---|---|---|
| **Ubuntu Server & IP tĩnh** | **Mặt bằng tòa nhà & Số nhà cố định** | Số nhà cố định (`192.168.10.10`) để mọi Client biết đường tìm đến, không bị thay đổi. | **TV1 (Xuân)** |
| **OpenSSH (Port 22)** | **Chìa khóa thông minh điều khiển từ xa** | Đường hầm mã hóa giúp quản trị viên ngồi bất kỳ đâu cũng điều khiển Server bằng dòng lệnh. | **TV1 (Xuân)** |
| **DHCP Server (Port 67)** | **Bác lễ tân phát thẻ phòng tự động** | Client cắm mạng vào được cấp ngay IP (`192.168.10.100–150`), Gateway và DNS qua 4 bước DORA. | **TV2 (Vượng)** |
| **DNS BIND9 (Port 53)** | **Cuốn danh bạ điện thoại nội bộ** | Dịch tên miền dễ nhớ (`web.lab.local`, `monitor.lab.local`) thành số IP (`192.168.10.10`). | **TV3 (Trí)** |
| **Nginx Web Server (Port 80)** | **Nhân viên tiếp tân & điều hướng khách** | Phục vụ trang web nội bộ (`web.lab.local`) và làm Reverse Proxy chuyển tiếp tới Grafana (`monitor.lab.local`). | **TV3 (Trí) & TV1** |
| **Tường lửa UFW** | **Bác bảo vệ gác cổng nghiêm ngặt** | Mặc định khóa hết 65.535 cổng (`Default Deny`), chỉ mở đúng 4 cổng hợp lệ (`22, 53, 67, 80`). | **TV4 (Đạt)** |
| **Prometheus & Grafana** | **Phòng Camera & Đồng hồ đo sức khỏe tòa nhà** | Đo nhịp tim CPU, RAM, Disk, Network của Server mỗi 15 giây và vẽ biểu đồ trực quan theo thời gian thực. | **TV1 (Xuân)** |

```text
                               LUỒNG HOẠT ĐỘNG TỔNG THỂ KHI DEMO:
[Client cắm mạng] ──► DHCP cấp IP 192.168.10.100 & DNS 192.168.10.10
       │
       ├──► Mở http://web.lab.local     ──► DNS giải ra .10 ──► UFW mở Port 80 ──► Nginx trả trang web nhóm
       ├──► Mở http://monitor.lab.local ──► DNS giải ra .10 ──► UFW mở Port 80 ──► Nginx Proxy ──► Grafana (3000) ◄── Prometheus (9090) ◄── Node Exporter (9100)
       └──► Gõ lệnh ssh (Port 22)       ──► UFW mở Port 22  ──► OpenSSH xác thực ──► Toàn quyền quản trị Server
```

---

## 1. Module 1: Hệ điều hành Ubuntu Server, Netplan, OpenSSH & Giám sát Prometheus/Grafana (TV1: Nguyễn Anh Xuân)

### 1.1. Kiến trúc Ubuntu Server & Cấu hình mạng Netplan
* **Linux Kernel & `systemd`:** Nhân Linux quản lý CPU, RAM, ngăn xếp mạng TCP/IP; `systemd` quản lý vòng đời các dịch vụ (`*.service`, `*.socket`).
* **Netplan:** Công cụ trừu tượng hóa cấu hình mạng bằng định dạng YAML tại `/etc/netplan/*.yaml`, biên dịch xuống backend `systemd-networkd`.
* **Vì sao Server bắt buộc dùng IP tĩnh:** Server là điểm cung cấp dịch vụ cố định (DHCP, DNS, Web, SSH). Nếu IP thay đổi, toàn bộ mạng LAN sẽ mất kết nối ngay lập tức.

### 1.2. Giao thức OpenSSH (Port 22/TCP)
* **Bản chất:** Giao thức điều khiển từ xa có mã hóa đầu cuối (thay thế Telnet truyền văn bản rõ).
* **Tiến trình bắt tay (SSH Handshake):** Kết nối TCP Port 22 $\rightarrow$ Thỏa thuận thuật toán & trao đổi khóa phiên bí mật (**ECDH**) $\rightarrow$ Xác minh danh tính máy chủ qua Host Key (`~/.ssh/known_hosts`) chống tấn công **Man-in-the-Middle** $\rightarrow$ Mã hóa kênh truyền đối xứng (AES-256) $\rightarrow$ Xác thực người dùng.
* **Cơ chế Hardening áp dụng:** Cấm đăng nhập trực tiếp `root` (`PermitRootLogin no`) và giới hạn số lần nhập sai (`MaxAuthTries 5`) thông qua file drop-in `/etc/ssh/sshd_config.d/01-lab-security.conf`.

### 1.3. Kiến trúc Giám sát Tài nguyên Prometheus + Node Exporter + Grafana + Nginx Reverse Proxy
* **Node Exporter (Port 9100 nội bộ):** Agent gọn nhẹ chạy trên Linux, đọc trực tiếp số liệu từ `/proc` và `/sys` (CPU, RAM, Swap, Disk I/O, Network Traffic) rồi xuất ra chuẩn HTTP metrics tại `/metrics`.
* **Prometheus (Port 9090 nội bộ):** Cơ sở dữ liệu chuỗi thời gian (Time-Series Database - TSDB) hoạt động theo cơ chế **Pull (Scrape)**: định kỳ mỗi 15 giây chủ động kéo dữ liệu từ `localhost:9100` để lưu trữ và truy vấn bằng ngôn ngữ **PromQL**.
* **Grafana (Port 3000 nội bộ):** Nền tảng trực quan hóa dữ liệu, kết nối Prometheus Data Source và hiển thị biểu đồ thời gian thực (Dashboard **Node Exporter Full — ID `1860`**).
* **Bảo mật bằng Nginx Reverse Proxy:** Thay vì mở thêm 3 cổng `3000, 9090, 9100` trên tường lửa UFW (làm tăng bề mặt tấn công), nhóm giữ nguyên toàn bộ 3 cổng này trong nội bộ máy chủ và dùng **Nginx** làm Reverse Proxy chuyển tiếp tên miền `http://monitor.lab.local` (Port 80) vào `http://127.0.0.1:3000`.

---

## 2. Module 2: Giao thức Cấp phát IP Động DHCP & Tiến trình DORA (TV2: Nguyễn Phúc Vượng)

* **Chuẩn RFC 2131:** Hoạt động ở tầng Ứng dụng trên giao thức UDP (Server: **Port 67**, Client: **Port 68**).
* **Tiến trình 4 bước DORA:**
  1. **Discover (Broadcast):** Client mới cắm mạng (chưa có IP `0.0.0.0`) phát quảng bá `255.255.255.255` tìm DHCP Server kèm địa chỉ MAC.
  2. **Offer:** Server kiểm tra dải IP trống (`192.168.10.100–150`) và gửi đề xuất IP + Subnet Mask + Gateway (`192.168.10.1`) + DNS (`192.168.10.10`).
  3. **Request (Broadcast):** Client thông báo đồng ý nhận IP từ Server đã chọn (đồng thời báo cho các DHCP Server khác nếu có biết để thu hồi đề xuất).
  4. **Acknowledge (ACK):** Server xác nhận thành công và ghi bản ghi thuê vào `/var/lib/dhcp/dhcpd.leases`.
* **Cơ chế Lease Time & Gia hạn:** Thời gian thuê mặc định `600s` (10 phút), tối đa `7200s` (2 giờ). Client tự gia hạn tại mốc **T1 = 50%** (Unicast) và **T2 = 87.5%** (Broadcast).

---

## 3. Module 3: Hệ thống Phân giải Tên miền DNS BIND9 & Web Server Nginx (TV3: Nguyễn Minh Trí)

### 3.1. DNS BIND9 (Port 53 TCP/UDP)
* **Chuẩn RFC 1034/1035:** Chuyển đổi tên miền dễ nhớ (`web.lab.local`, `monitor.lab.local`) thành địa chỉ IP (`192.168.10.10`) và ngược lại.
* **Các bản ghi tài nguyên (Resource Records) chính:**
  * `SOA` (Start of Authority): Khai báo máy chủ quản trị chính của Zone, Serial đồng bộ và chu kỳ làm mới.
  * `NS` (Name Server): Chỉ định máy chủ tên miền (`ns.lab.local`).
  * `A` (Address): Ánh xạ Tên miền $\rightarrow$ IPv4 (`web`, `monitor`, `ns`, `server` $\rightarrow$ `192.168.10.10`).
  * `PTR` (Pointer): Ánh xạ ngược IPv4 $\rightarrow$ Tên miền trong Reverse Zone (`10.168.192.in-addr.arpa`).
* **Forwarding & ACL:** Chỉ cho phép mạng nội bộ `192.168.10.0/24` và `localhost` truy vấn (`allow-query`); các tên miền Internet ngoài vùng quản lý được chuyển tiếp tới `8.8.8.8 / 8.8.4.4`.

### 3.2. Máy chủ Web Nginx (Port 80/TCP)
* **Kiến trúc Event-Driven bất đồng bộ:** Mô hình **Master – Worker** kết hợp `epoll` cho phép xử lý đồng thời hàng nghìn kết nối với mức tiêu thụ RAM cực thấp.
* **Virtual Host (Server Block):** Nginx đọc trường HTTP Header `Host:` để phục vụ nhiều dịch vụ khác nhau trên cùng 1 IP và 1 cổng 80:
  * `Host: web.lab.local` (hoặc IP `192.168.10.10` nhờ `default_server`) $\rightarrow$ phục vụ file tĩnh `/var/www/lab.local/html/index.html`.
  * `Host: monitor.lab.local` $\rightarrow$ làm Reverse Proxy chuyển tiếp lưu lượng sang Grafana (`127.0.0.1:3000`).

---

## 4. Module 4: Tường lửa UFW & Nguyên tắc Đặc quyền Tối thiểu (TV4: Nguyễn Thành Đạt)

* **Kiến trúc Netfilter $\rightarrow$ iptables/nftables $\rightarrow$ UFW:** Netfilter nằm trong nhân Linux thực hiện kiểm soát mọi gói tin vào (`INPUT`), ra (`OUTPUT`), chuyển tiếp (`FORWARD`). UFW là lớp giao diện quản trị chuẩn của Ubuntu giúp cấu hình luật an toàn, rõ ràng.
* **Chính sách Least Privilege (Đặc quyền tối thiểu):**
  * Mặc định **chặn toàn bộ kết nối vào** (`default deny incoming`), cho phép đi ra (`default allow outgoing`).
  * Chỉ mở tường minh (`Explicit Allow`) đúng 4 cổng dịch vụ: **`22/tcp` (SSH)**, **`53` (DNS TCP/UDP)**, **`67/udp` (DHCP)**, **`80/tcp` (Nginx HTTP & Reverse Proxy)**.
  * Mọi cổng khác (`23`, `3306`, `8080`, `3000`, `9090`, `9100`...) từ mạng ngoài đều bị hủy gói tin âm thầm (**DROP / timed out**), chống dò quét cổng (Port Scanning).

---
> **Tài liệu tham khảo:** RFC 2131 (DHCP), RFC 1034/1035 (DNS), RFC 4253 (SSH-2), Ubuntu Server Official Docs, Prometheus & Grafana Official Documentation.
