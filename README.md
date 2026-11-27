# ĐỀ TÀI: NGHIÊN CỨU VÀ TRIỂN KHAI HỆ THỐNG DỊCH VỤ MẠNG & GIÁM SÁT TÀI NGUYÊN TRÊN UBUNTU SERVER LTS

> **Tên đề tài:** Nghiên cứu và triển khai hệ thống dịch vụ mạng doanh nghiệp kết hợp giám sát tài nguyên trên nền tảng Ubuntu Server LTS\
> **Môn học:** Hệ điều hành mạng (2 tín chỉ)\
> **Quy mô nhóm:** 04 thành viên\
> **Nền tảng triển khai:** Ubuntu Server LTS (Máy chủ) & Ubuntu Desktop (Client)\
> **Môi trường ảo hóa:** VMware Fusion / VMware Workstation (Mạng cô lập Custom `vmnet2` tắt DHCP ảo)\
> **Thời gian thực hiện:** 14 ngày (07 giai đoạn)\
> **Kho mã nguồn:** `https://github.com/anhxuan2712/linux-network-services`

---

## 1. Mục tiêu và Phạm vi đề tài

### 1.1. Mục tiêu nghiên cứu
Xây dựng một hệ thống mạng máy chủ – máy trạm hoàn chỉnh, mô phỏng hạ tầng mạng dịch vụ của một doanh nghiệp vừa và nhỏ trên nền tảng **Ubuntu Server LTS**. Hệ thống vận hành tự động, khép kín, an toàn và giám sát được theo thời gian thực, giải quyết trọn vẹn **6 bài toán cốt lõi**:
1. **Quản trị hệ thống từ xa (Remote Management):** Quản trị dòng lệnh an toàn qua giao thức OpenSSH kèm chính sách Hardening.
2. **Cấp phát địa chỉ tự động (Dynamic Addressing):** Triển khai DHCP Server cấp phát IP, Subnet mask, Gateway và DNS cho toàn bộ mạng nội bộ.
3. **Dịch vụ phân giải tên miền (Name Resolution):** Thiết lập DNS Server (BIND9) phân giải thuận/nghịch cho tên miền nội bộ `lab.local`.
4. **Dịch vụ máy chủ web & Reverse Proxy (Web Hosting):** Triển khai Nginx Web Server cung cấp cổng thông tin nội bộ `http://web.lab.local` và chuyển tiếp ngược cho hệ thống giám sát `http://monitor.lab.local`.
5. **An toàn & Kiểm soát truy cập (Network Security):** Thiết lập tường lửa UFW (Uncomplicated Firewall) theo nguyên tắc đặc quyền tối thiểu (Least Privilege).
6. **Giám sát tài nguyên tập trung (System Monitoring):** Triển khai bộ công cụ **Prometheus + Node Exporter + Grafana** theo dõi CPU, RAM, Disk, Network Traffic theo thời gian thực.

### 1.2. Phạm vi triển khai
* **Phần bắt buộc (Hoàn thành 10/10 Test Cases):** Cấu hình mạng tĩnh Netplan, OpenSSH Hardening, DHCP Server (`isc-dhcp-server`), DNS BIND9, Nginx Web Server, Tường lửa UFW.
* **Phần mở rộng đã triển khai (Hoàn thành TC-11):** Giám sát tài nguyên máy chủ tập trung bằng **Prometheus + Node Exporter + Grafana** (Dashboard ID `1860`), phân giải qua DNS `monitor.lab.local` và chạy qua **Nginx Reverse Proxy** trên Port 80 (giữ nguyên tường lửa UFW chỉ mở 4 cổng `22, 53, 67, 80`).

---

## 2. Thiết kế Kiến trúc Hệ thống & Kế hoạch Địa chỉ IP

### 2.1. Sơ đồ kiến trúc mạng logic

```text
                       MÔI TRƯỜNG MẠNG NỘI BỘ CÔ LẬP (CUSTOM VMNET2)
                                  Subnet: 192.168.10.0/24
                                             │
                      ┌──────────────────────┴──────────────────────┐
                      │                                             │
           ┌─────────────────────┐                       ┌─────────────────────┐
           │    UBUNTU SERVER    │                       │    UBUNTU CLIENT    │
           │  enp10s0: .10.10/24 │                       │  enp2s0: .10.100/24 │
           └──────────┬──────────┘                       └──────────┬──────────┘
                      │                                             │
       ┌──────────────┼──────────────┬───────────────────┐          │
       ▼              ▼              ▼                   ▼          │
    OpenSSH          DHCP           DNS                Nginx        │
   (Port 22)     (Port 67/UDP)  (Port 53)            (Port 80)      │
       │              │              │          ┌────────┴────────┐ │
   Quản trị       Cấp IP tự      Phân giải      ▼                 ▼ │
    từ xa         động cho       lab.local  web.lab.local  monitor.lab.local
                   Client                   (HTML tĩnh)    (Reverse Proxy)
       │              │              │          │                 │ │
       │              │              │          │       ┌─────────▼─────────┐
       │              │              │          │       │ Grafana (:3000)   │
       │              │              │          │       │   ▲ (PromQL)      │
       │              │              │          │       │ Prometheus (:9090)│
       │              │              │          │       │   ▲ (Scrape 15s)  │
       │              │              │          │       │ NodeExp (:9100)   │
       │              │              │          │       └───────────────────┘
       └──────────────┴──────┬───────┴──────────┘        (Chỉ lắng nghe nội bộ)
                             │                                      │
                      [UFW FIREWALL]                                │
                (Chỉ mở: 22, 53, 67, 80)                            │
                             │                                      │
                             └───────── LUỒNG KẾT NỐI ──────────────┘
                               1. Xin cấp IP & DNS tự động (DORA)
                               2. Phân giải: web.lab.local & monitor.lab.local
                               3. Truy cập Web doanh nghiệp & Dashboard Grafana
                               4. Quản trị viên SSH vào Server kiểm tra hệ thống
```

### 2.2. Bảng phân bổ địa chỉ IP và thông số kỹ thuật

| Thành phần | Địa chỉ IP / Cấu hình | Mô tả chức năng |
|---|---|---|
| **Mạng nội bộ** | `192.168.10.0/24` (`vmnet2`) | Mạng ảo Custom cô lập hoàn toàn, đã tắt DHCP mặc định của VMware |
| **Ubuntu Server** | `192.168.10.10/24` (`enp10s0`) | IP tĩnh cố định cho card mạng nội bộ (`enp2s0` NAT dùng khi cài gói `apt`) |
| **Default Gateway** | `192.168.10.1` | Cổng mặc định của phân đoạn mạng nội bộ |
| **DNS Server nội bộ** | `192.168.10.10` | Máy chủ BIND9 phân giải thuận/nghịch cho miền `lab.local` |
| **DHCP IP Pool** | `192.168.10.100` – `192.168.10.150` | Dải cấp phát IP tự động (tối đa 51 thiết bị Client) |
| **Lease Time** | Default: 600s (10p) / Max: 7200s (2h) | Thời gian cho thuê địa chỉ IP |
| **Domain nội bộ** | `lab.local` | Không gian tên miền cục bộ |
| **Web doanh nghiệp** | `http://web.lab.local` (`192.168.10.10`) | Trang web nội bộ Nginx phục vụ trên Port 80 |
| **Cổng Giám sát** | `http://monitor.lab.local` (`192.168.10.10`) | Dashboard Grafana qua Nginx Reverse Proxy trên Port 80 |
| **Ubuntu Client** | `192.168.10.100/24` (`enp2s0`, động) | Máy trạm nhận IP và DNS tự động từ DHCP Server |

### 2.3. Bảng cổng dịch vụ (Port Matrix) và Chính sách Tường lửa (UFW)

| Dịch vụ | Cổng (Port) | Giao thức | Chiều | Hành động UFW |
|---|---|---|---|---|
| **OpenSSH** | `22` | TCP | Inbound | `ALLOW` (Quản trị dòng lệnh từ xa) |
| **DNS BIND9** | `53` | UDP & TCP | Inbound | `ALLOW` (Truy vấn tên miền `lab.local`) |
| **DHCP Server** | `67` | UDP | Inbound | `ALLOW` (Tiếp nhận yêu cầu cấp IP từ Client) |
| **Nginx (Web & Reverse Proxy)** | `80` | TCP | Inbound | `ALLOW` (Phục vụ `web.lab.local` & `monitor.lab.local`) |
| **Grafana / Prometheus / Node Exporter** | `3000`, `9090`, `9100` | TCP | Localhost | **`DEFAULT DENY` từ ngoài** (chỉ giao tiếp nội bộ, vào qua Nginx Port 80) |
| **Mọi cổng khác** | Tất cả | Tất cả | Inbound | **`DEFAULT DENY` (Chặn âm thầm)** |

---

## 3. Phân công Nhân sự, Trách nhiệm & Quy trình Thực tế (Nhóm 04 Thành viên)

Dự án được phân bổ thành 4 module liên kết theo chuỗi giá trị, do Nhóm trưởng (TV1) trực tiếp tích hợp, triển khai hệ thống giám sát Prometheus/Grafana và điều phối Demo:

```text
[TV1: Xuân (Leader)] ──► [TV2: Vượng] ──► [TV3: Trí] ───────► [TV4: Đạt] ─────► [TV1: Xuân]
  (Nền tảng & SSH)       (Cấp IP DHCP)    (DNS & Nginx Web)   (Tường lửa UFW)   (Prometheus/Grafana,
                                                                                 Tích hợp & Demo)
```

### Thành viên 1: Nguyễn Anh Xuân (Nhóm trưởng - Leader)
* **Module phụ trách:** Nền tảng Ubuntu Server LTS, Quản trị OpenSSH, **Giám sát tài nguyên Prometheus & Grafana**, Tích hợp hệ thống & Thực hiện Demo.
* **Nhiệm vụ chính:**
  1. Quản lý dự án, chuẩn hóa Git Repository, cấu trúc thư mục và tài liệu nghiên cứu cơ sở lý thuyết (Giai đoạn 1).
  2. Cài đặt Ubuntu Server & Ubuntu Client trên VMware Fusion; cấu hình mạng tĩnh Netplan `192.168.10.10/24` và bảo mật OpenSSH (Giai đoạn 2).
  3. **Triển khai hệ thống giám sát tài nguyên Prometheus + Node Exporter + Grafana** (Dashboard ID `1860`), tích hợp DNS `monitor.lab.local` và **Nginx Reverse Proxy** trên Port 80 (Giai đoạn 6).
  4. **Trực tiếp chủ trì tích hợp toàn bộ hệ thống (System Integration)** và nghiệm thu 11 Test Cases.
  5. **Trực tiếp thực hiện kịch bản Demo 5 bước** trước Giảng viên và điều phối hoàn thiện Báo cáo cuối kỳ (Giai đoạn 7).
* **Sản phẩm bàn giao:**
  * `configs/network/01-netplan.yaml`, `configs/ssh/01-lab-security.conf`
  * `configs/monitoring/prometheus.yml`, `configs/nginx/monitor.lab.local.conf`
  * `scripts/setup_network.sh`, `scripts/setup_monitoring.sh`, `scripts/run_all_tests.sh`
  * `docs/01-ly-thuyet-cac-dich-vu-mang.md`, `docs/02-trien-khai-server-va-ssh.md`, `docs/06-trien-khai-monitoring-grafana.md`, `docs/07-kiem-thu-tich-hop-va-demo.md`
* **Lệnh minh chứng kiểm tra:**
  ```bash
  ip -4 a show enp10s0 && sudo systemctl status ssh
  ssh anhxuan-devops@192.168.10.10
  systemctl is-active prometheus prometheus-node-exporter grafana-server
  ```
* **Quy trình thực tế đã triển khai (Giai đoạn 2 — Server & SSH):**
  1. **Mạng ảo (VMware Fusion):** Server dùng 2 card (`enp2s0` NAT để cài gói `apt`, `enp10s0` làm mạng nội bộ `192.168.10.0/24`); Client chỉ dùng 1 card (`enp2s0`) để tránh xung đột Gateway/DNS.
  2. **IP tĩnh Netplan (`/etc/netplan/01-netcfg.yaml`):** Sao lưu config cũ vào `/etc/netplan/backup/`, giữ `enp2s0` (`dhcp4: true`), gắn `enp10s0` IP tĩnh `192.168.10.10/24` (không gắn default route lên `enp10s0`), phân quyền `chmod 600` và `sudo netplan apply`.
  3. **Bảo mật OpenSSH (`/etc/ssh/sshd_config.d/01-lab-security.conf`):** Tạo file drop-in gồm `Port 22`, `PermitRootLogin no`, `MaxAuthTries 5`, `PasswordAuthentication yes`, kiểm tra `sudo sshd -t` và khởi động `ssh.service`.
  4. **Kiểm thử từ Client:** Đặt IP tạm `192.168.10.20/24` trên Client, `ping -c 3 192.168.10.10` (0% loss) và `ssh anhxuan-devops@192.168.10.10` thành công.
  *(Xem chi tiết từng lệnh tại [docs/02-trien-khai-server-va-ssh.md](docs/02-trien-khai-server-va-ssh.md))*.
* **Quy trình thực tế đã triển khai (Giai đoạn 6 — Giám sát Prometheus & Grafana):**
  1. **Sao lưu an toàn:** Thực hiện *Take Snapshot* máy ảo trước khi mở rộng; chuyển mirror APT từ `vn.archive.ubuntu.com` sang `ports.ubuntu.com/ubuntu-ports` (ARM64) để cài gói ổn định.
  2. **Prometheus & Node Exporter:** Cài đặt `prometheus` và `prometheus-node-exporter` qua `apt`, bật tự khởi chạy (`localhost:9090` tự động scrape `localhost:9100` mỗi 15s).
  3. **Grafana:** Thêm GPG key & kho APT chính thức `apt.grafana.com`, cài `grafana` và kích hoạt `grafana-server` (`localhost:3000`).
  4. **DNS & Nginx Reverse Proxy:** Thêm bản ghi `monitor IN A 192.168.10.10` vào `/etc/bind/zones/db.lab.local`; cấu hình `/etc/nginx/sites-available/monitor.lab.local.conf` chuyển tiếp `http://monitor.lab.local` (Port 80) vào `127.0.0.1:3000` (không phải mở thêm cổng UFW).
  5. **Kiểm thử trên Client:** Mở Firefox vào `http://monitor.lab.local`, nối Prometheus Data Source (`http://localhost:9090`), import Dashboard ID **`1860`** (*Node Exporter Full*) hiển thị CPU, RAM, Disk, Network thời gian thực của `ubuntu-server`.
  *(Xem chi tiết từng lệnh tại [docs/06-trien-khai-monitoring-grafana.md](docs/06-trien-khai-monitoring-grafana.md))*.

---

### Thành viên 2: Nguyễn Phúc Vượng
* **Module phụ trách:** Dịch vụ cấp phát địa chỉ IP tự động (DHCP Server).
* **Nhiệm vụ chính:**
  1. Nghiên cứu giao thức DHCP và tiến trình 4 bước DORA (Discover – Offer – Request – Acknowledge).
  2. Cài đặt và cấu hình `isc-dhcp-server` lắng nghe cố định trên `enp10s0`.
  3. Khai báo Subnet `192.168.10.0/24`, dải cấp phát `192.168.10.100–150`, Gateway `192.168.10.1`, DNS `192.168.10.10`, Domain `lab.local`.
  4. Xử lý xung đột với DHCP tích hợp sẵn của VMware Fusion và kiểm tra sổ lease.
* **Sản phẩm bàn giao:** `configs/dhcp/dhcpd.conf`, `scripts/check_dhcp_leases.sh`, `docs/03-trien-khai-dhcp-server.md`.
* **Quy trình thực tế đã triển khai (Giai đoạn 3):**
  1. Cài `isc-dhcp-server` trên Server, cấu hình `INTERFACESv4="enp10s0"` trong `/etc/default/isc-dhcp-server`.
  2. Nạp `/etc/dhcp/dhcpd.conf`, kiểm tra cú pháp `sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf` và kích hoạt dịch vụ.
  3. **Xử lý xung đột DHCP VMware:** Tạo mạng Custom **`vmnet2`** trong *VMware Fusion $\rightarrow$ Settings $\rightarrow$ Network* (bỏ tích DHCP & NAT của VMware), chuyển card `enp10s0` (Server) và `enp2s0` (Client) sang `vmnet2`.
  4. **Kiểm thử:** Trên Client chạy `nmcli dev disconnect enp2s0 && nmcli dev connect enp2s0` $\rightarrow$ nhận đúng `192.168.10.100/24`; kiểm tra `cat /var/lib/dhcp/dhcpd.leases` trên Server ghi nhận đầy đủ MAC & hostname `ubuntu-client`.
  *(Xem chi tiết từng lệnh tại [docs/03-trien-khai-dhcp-server.md](docs/03-trien-khai-dhcp-server.md))*.

---

### Thành viên 3: Nguyễn Minh Trí
* **Module phụ trách:** Dịch vụ phân giải tên miền nội bộ (DNS BIND9) & Máy chủ Web Nginx.
* **Nhiệm vụ chính:**
  1. Nghiên cứu nguyên lý DNS BIND9 (Zone file, Resource Records) và kiến trúc Web Server Nginx.
  2. Cấu hình `named.conf.options` (ACL mạng LAN & Forwarders), Forward Zone (`db.lab.local`) và Reverse Zone (`db.10.168.192`).
  3. Cài đặt Nginx, thiết kế trang web nội bộ HTML5/CSS (`index.html`) và cấu hình Virtual Host `web.lab.local.conf`.
  4. Kiểm thử phân giải DNS thuận/nghịch và truy cập web qua IP lẫn tên miền.
* **Sản phẩm bàn giao:** `configs/dns/*`, `configs/nginx/web.lab.local.conf`, `configs/nginx/html/index.html`, `scripts/test_dns.sh`, `docs/04-trien-khai-dns-va-nginx.md`.
* **Quy trình thực tế đã triển khai (Giai đoạn 4):**
  1. **DNS BIND9:** Cài `bind9 bind9utils dnsutils`, cấu hình `named.conf.options`, `named.conf.local`, tạo `/etc/bind/zones/db.lab.local` & `db.10.168.192`, kiểm tra `sudo named-checkconf` / `named-checkzone` và restart `bind9`.
  2. **Nginx Web Server:** Cài `nginx`, nạp `/var/www/lab.local/html/index.html`, tạo `/etc/nginx/sites-available/web.lab.local.conf` (gắn `default_server` để truy cập qua IP hay Domain đều ra trang web nhóm), xóa `sites-enabled/default`, kiểm tra `sudo nginx -t` và khởi động lại.
  3. **Kiểm thử từ Client:** Client tự động dùng DNS `192.168.10.10` phân giải `web.lab.local` và `dig -x 192.168.10.10`; `wget -S --spider` và trình duyệt Firefox truy cập `http://192.168.10.10` lẫn `http://web.lab.local` đều đạt `HTTP/1.1 200 OK`.
  *(Xem chi tiết từng lệnh tại [docs/04-trien-khai-dns-va-nginx.md](docs/04-trien-khai-dns-va-nginx.md))*.

---

### Thành viên 4: Nguyễn Thành Đạt
* **Module phụ trách:** Tường lửa UFW, An toàn hệ thống & Slide thuyết trình.
* **Nhiệm vụ chính:**
  1. Nghiên cứu cơ chế lọc gói Netfilter/UFW và nguyên tắc đặc quyền tối thiểu (Least Privilege).
  2. Xây dựng bảng Port Matrix và viết script tự động kích hoạt UFW (`scripts/setup_firewall.sh`).
  3. Kiểm thử quét cổng chứng minh UFW chặn toàn bộ cổng không hợp lệ.
  4. Thiết kế Slide thuyết trình bảo vệ đề tài (`presentation/Slide_Bao_ve_He_dieu_hanh_mang.pptx`).
* **Sản phẩm bàn giao:** `configs/firewall/ufw-rules.txt`, `scripts/setup_firewall.sh`, `docs/05-trien-khai-firewall-ufw.md`, `presentation/Slide_Bao_ve_He_dieu_hanh_mang.pptx`.
* **Quy trình thực tế đã triển khai (Giai đoạn 5):**
  1. Merge nhánh `nguyen_thanh_dat` vào `main`, clone repo `linux-network-services` về Ubuntu Server và cấp quyền thực thi `chmod +x scripts/*.sh`.
  2. Chạy `./scripts/setup_firewall.sh` thực hiện 5 bước: `ufw --force reset` $\rightarrow$ `default deny incoming` / `default allow outgoing` $\rightarrow$ mở đúng 4 cổng `22/tcp`, `53`, `67/udp`, `80/tcp` $\rightarrow$ `ufw --force enable` $\rightarrow$ `ufw status verbose`.
  3. **Kiểm thử từ Client:** Chạy `nc -zv -w 2 192.168.10.10 22 80 23 8080` $\rightarrow$ cổng `22`, `80` báo `succeeded!`; cổng lạ `23`, `8080` bị chặn âm thầm (`timed out`).
  *(Xem chi tiết từng lệnh tại [docs/05-trien-khai-firewall-ufw.md](docs/05-trien-khai-firewall-ufw.md))*.

---

## 4. Kế hoạch & Tiến độ Thực hiện theo 07 Giai đoạn (14 Ngày)

| Giai đoạn | Thời gian | Nhiệm vụ trọng tâm | Tài liệu quy trình chi tiết | Phụ trách | Tiến độ |
|---|---|---|---|---|:---:|
| **Giai đoạn 1** | Ngày 1–2 | Chốt đề tài, sơ đồ mạng, khởi tạo Git Repo & nghiên cứu cơ sở lý thuyết | [01-ly-thuyet-cac-dich-vu-mang.md](docs/01-ly-thuyet-cac-dich-vu-mang.md) | TV1 (Leader) & Cả nhóm | ✅ Xong |
| **Giai đoạn 2** | Ngày 3–4 | Cài đặt Ubuntu Server/Client, Netplan IP tĩnh `192.168.10.10`, bảo mật SSH | [02-trien-khai-server-va-ssh.md](docs/02-trien-khai-server-va-ssh.md) | TV1 (Xuân) | ✅ Xong |
| **Giai đoạn 3** | Ngày 5–7 | Triển khai DHCP Server (`192.168.10.100–150`) & xử lý xung đột `vmnet2` | [03-trien-khai-dhcp-server.md](docs/03-trien-khai-dhcp-server.md) | TV2 (Vượng) | ✅ Xong |
| **Giai đoạn 4** | Ngày 8–9 | Triển khai DNS BIND9 (thuận/nghịch) & Máy chủ Web Nginx (`web.lab.local`) | [04-trien-khai-dns-va-nginx.md](docs/04-trien-khai-dns-va-nginx.md) | TV3 (Trí) | ✅ Xong |
| **Giai đoạn 5** | Ngày 10–11 | Thiết lập tường lửa UFW (4 cổng vàng) & kiểm thử chặn cổng trái phép | [05-trien-khai-firewall-ufw.md](docs/05-trien-khai-firewall-ufw.md) | TV4 (Đạt) | ✅ Xong |
| **Giai đoạn 6** | Ngày 12–13 | Tích hợp hệ thống & triển khai **Prometheus + Node Exporter + Grafana** (`monitor.lab.local`) | [06-trien-khai-monitoring-grafana.md](docs/06-trien-khai-monitoring-grafana.md) | TV1 (Xuân) | ✅ Xong |
| **Giai đoạn 7** | Ngày 14 | Nghiệm thu **11/11 Test Cases**, hoàn thiện Báo cáo Word, Slide & Tổng duyệt Demo | [07-kiem-thu-tich-hop-va-demo.md](docs/07-kiem-thu-tich-hop-va-demo.md) | TV1 (Demo/Báo cáo), TV4 (Slide) | 🔄 Đang làm Báo cáo & Slide |

---

## 5. Cấu trúc Thư mục Dự án Chuẩn hóa

```text
linux-network-services/
├── .gitignore                                      # Loại bỏ file máy ảo (*.iso, *.vmdk...), file tạm & log
├── README.md                                       # Tài liệu tổng quan kiến trúc, phân công & tiến độ 7 giai đoạn
│
├── docs/                                           # Quy trình chi tiết từng giai đoạn (01 -> 07)
│   ├── 01-ly-thuyet-cac-dich-vu-mang.md            # [GĐ 1] Nghiên cứu cơ sở lý thuyết 4 module & Monitoring
│   ├── 02-trien-khai-server-va-ssh.md              # [GĐ 2] Quy trình cài Ubuntu Server, Netplan & OpenSSH (TV1)
│   ├── 03-trien-khai-dhcp-server.md                # [GĐ 3] Quy trình cài DHCP Server & cấu hình vmnet2 (TV2)
│   ├── 04-trien-khai-dns-va-nginx.md               # [GĐ 4] Quy trình cài DNS BIND9 & Web Nginx (TV3)
│   ├── 05-trien-khai-firewall-ufw.md               # [GĐ 5] Quy trình cài Tường lửa UFW & test chặn cổng (TV4)
│   ├── 06-trien-khai-monitoring-grafana.md         # [GĐ 6] Quy trình cài Prometheus, Node Exporter & Grafana (TV1)
│   └── 07-kiem-thu-tich-hop-va-demo.md             # [GĐ 7] Biên bản nghiệm thu 11 Test Cases & Kịch bản Demo (TV1)
│
├── configs/                                        # Toàn bộ file cấu hình chuẩn khớp 100% với Server thực tế
│   ├── network/
│   │   └── 01-netplan.yaml                         # Netplan 2 card (NAT enp2s0 + IP tĩnh enp10s0 192.168.10.10/24)
│   ├── ssh/
│   │   └── 01-lab-security.conf                    # File drop-in bảo mật OpenSSH (/etc/ssh/sshd_config.d/)
│   ├── dhcp/
│   │   └── dhcpd.conf                              # Cấu hình dải IP 192.168.10.100–150, Gateway, DNS
│   ├── dns/
│   │   ├── named.conf.local                        # Khai báo Forward & Reverse Zone
│   │   ├── named.conf.options                      # ACL mạng LAN & Forwarders
│   │   ├── db.lab.local                            # Forward Zone (ns, server, web, monitor -> 192.168.10.10)
│   │   └── db.10.168.192                           # Reverse Zone (PTR 192.168.10.10)
│   ├── nginx/
│   │   ├── web.lab.local.conf                      # Virtual Host Web nhóm (default_server Port 80)
│   │   ├── monitor.lab.local.conf                  # Reverse Proxy cho Grafana (Port 80 -> localhost:3000)
│   │   └── html/
│   │       └── index.html                          # Giao diện cổng thông tin nội bộ giới thiệu nhóm
│   ├── firewall/
│   │   └── ufw-rules.txt                           # Bảng Port Matrix chính sách đặc quyền tối thiểu
│   └── monitoring/
│       └── prometheus.yml                          # Cấu hình Prometheus scrape Node Exporter (localhost:9100)
│
├── scripts/                                        # Shell script tự động hóa triển khai & kiểm thử
│   ├── setup_network.sh                            # Tự động backup và áp dụng IP tĩnh Netplan (GĐ 2)
│   ├── check_dhcp_leases.sh                        # Đọc và định dạng bảng Client đang thuê IP (GĐ 3)
│   ├── test_dns.sh                                 # Kiểm thử tự động phân giải thuận/nghịch DNS (GĐ 4)
│   ├── setup_firewall.sh                           # Thiết lập nhanh 5 bước tường lửa UFW (GĐ 5 - TV4)
│   ├── setup_monitoring.sh                         # Cài tự động Prometheus + Grafana + Reverse Proxy (GĐ 6 - TV1)
│   └── run_all_tests.sh                            # Quét trạng thái toàn bộ 7 dịch vụ, port & UFW (GĐ 7 - TV1)
│
├── evidence/                                       # Ảnh chụp màn hình nghiệm thu thực tế (11/11 Test Cases)
│   ├── server/
│   │   └── tc01-tc02-server-ip-ssh-status.jpg      # TC-01 & TC-02: IP tĩnh enp10s0 & ssh.service active
│   ├── ssh/
│   │   └── tc03-client-ssh-login.jpg               # TC-03: Ping 0% loss & SSH từ Client vào Server
│   ├── dhcp/
│   │   ├── tc04-client-dhcp-ip.jpg                 # TC-04: Client nhận IP động 192.168.10.100/24
│   │   └── tc05-server-dhcp-leases.jpg             # TC-05: Bảng dhcpd.leases ghi nhận MAC Client
│   ├── dns/
│   │   └── tc06-tc07-dns-resolution.jpg            # TC-06 & TC-07: dig phân giải thuận & nghịch
│   ├── web/
│   │   ├── tc08-tc09-nginx-wget.jpg                # TC-08 & TC-09: wget HTTP/1.1 200 OK (IP & Domain)
│   │   └── tc09-firefox-web-lab-local.jpg          # TC-09: Trình duyệt Firefox truy cập http://web.lab.local
│   ├── firewall/
│   │   ├── tc10-real-ufw-status.jpg                # TC-10: Kết quả chạy setup_firewall.sh trên Server tích hợp
│   │   ├── tc10-real-nc-port-block.jpg             # TC-10: Client test nc mở 22/80, chặn 23/8080
│   │   ├── tc10-ufw-status.png                     # Ảnh kiểm thử độc lập của TV4
│   │   └── port-scan-blocked.png                   # Ảnh test quét cổng của TV4
│   └── monitoring/
│       └── tc11-grafana-node-exporter-dashboard.jpg # TC-11: Grafana Dashboard 1860 tại http://monitor.lab.local
│
├── report/                                         # Thư mục lưu Báo cáo tổng kết Word/PDF
└── presentation/                                   # Thư mục lưu Slide thuyết trình PowerPoint
```

---

## 6. Ma trận 11 Kịch bản Kiểm thử Nghiệm thu (Test Cases)

| Test ID | Tên bài kiểm thử | Thao tác thực hiện | Kết quả mong đợi | Người kiểm tra | Trạng thái |
|:---:|---|---|---|:---:|:---:|
| **TC-01** | IP tĩnh Server | Chạy `ip -4 a show enp10s0` | Server có đúng IP `192.168.10.10/24` | TV1 | [x] Pass |
| **TC-02** | Trạng thái SSH | Chạy `sudo systemctl status ssh` | Trạng thái `active (running)`, Port 22 | TV1 | [x] Pass |
| **TC-03** | Đăng nhập SSH từ xa | Client: `ssh anhxuan-devops@192.168.10.10` | Đăng nhập thành công vào Terminal Server | TV1 | [x] Pass |
| **TC-04** | Client xin IP động | Client: `nmcli dev disconnect/connect enp2s0` | Nhận IP `192.168.10.100/24` (dải `100–150`) | TV2 | [x] Pass |
| **TC-05** | Bảng cấp phát DHCP | Server: `cat /var/lib/dhcp/dhcpd.leases` | Ghi nhận MAC Client và IP `192.168.10.100` | TV2 | [x] Pass |
| **TC-06** | Phân giải thuận DNS | Client: `dig web.lab.local +short` | Trả về chính xác địa chỉ `192.168.10.10` | TV3 | [x] Pass |
| **TC-07** | Phân giải nghịch DNS | Client: `dig -x 192.168.10.10 +short` | Trả về `ns.lab.local.`, `web.lab.local.` | TV3 | [x] Pass |
| **TC-08** | Truy cập Web bằng IP | Client: `wget -S --spider http://192.168.10.10` | Nginx trả về `HTTP/1.1 200 OK` (trang nhóm) | TV3 | [x] Pass |
| **TC-09** | Truy cập Web bằng Domain | Firefox / `wget`: `http://web.lab.local` | Trang web load thành công qua tên miền | TV3 | [x] Pass |
| **TC-10** | Chính sách Firewall UFW | Server `ufw status verbose`; Client `nc -zv` | Chỉ mở `22, 53, 67, 80`; chặn cổng `23, 8080` | TV4 | [x] Pass |
| **TC-11** | Giám sát Prometheus & Grafana | Firefox Client: `http://monitor.lab.local` | Dashboard `1860` hiển thị CPU, RAM, Disk, Network thời gian thực qua Nginx Port 80 | TV1 | [x] Pass |

---

## 7. Kịch bản Demo Trực tiếp trước Giảng viên (10 Phút)

Khi lên báo cáo, nhóm bật sẵn 2 máy ảo từ Snapshot: **Ubuntu Server** và **Ubuntu Client** (chạy chung mạng `vmnet2`). **Nhóm trưởng (TV1 - Nguyễn Anh Xuân) trực tiếp thao tác trọn vẹn 5 bước demo**, các thành viên hỗ trợ thuyết minh và trả lời phản biện chuyên sâu theo từng module:

```text
[BƯỚC 1: Hạ tầng & SSH (2p)]    ──► TV1 demo IP tĩnh enp10s0 & SSH từ Client vào Ubuntu Server.
[BƯỚC 2: DHCP tự động (1.5p)]   ──► TV1 demo Client xin IP 192.168.10.100 (TV2), show dhcpd.leases.
[BƯỚC 3: DNS & Web (2p)]        ──► TV1 dig web/monitor.lab.local & mở http://web.lab.local (TV3).
[BƯỚC 4: UFW & Grafana (2.5p)]  ──► TV1 show UFW + test chặn cổng nc (TV4) & mở http://monitor.lab.local (TV1).
[BƯỚC 5: Tổng kết & Hỏi đáp]    ──► TV1 tổng kết giá trị hệ thống, điều phối cả nhóm trả lời phản biện.
```

* **Bước 1 (2 phút):** Trên Client gõ `ssh anhxuan-devops@192.168.10.10`, chạy `ip -4 a show enp10s0` và `sudo sshd -T | grep permitrootlogin` chứng minh IP tĩnh và SSH đã Hardening.
* **Bước 2 (1.5 phút):** Trên Client gõ `nmcli dev disconnect enp2s0 && nmcli dev connect enp2s0 && ip -4 a show enp2s0` chứng minh nhận IP `192.168.10.100/24`; trên Server chạy `./scripts/check_dhcp_leases.sh`.
* **Bước 3 (2 phút):** Trên Client gõ `dig web.lab.local +short` và `dig -x 192.168.10.10 +short`; mở Firefox vào **`http://web.lab.local`** hiển thị trang web nội bộ nhóm.
* **Bước 4 (2.5 phút):** Trên Server gõ `sudo ufw status verbose`, trên Client chạy `nc -zv -w 2 192.168.10.10 22 80 23 8080` chứng minh chặn cổng lạ. Sau đó chuyển sang tab **`http://monitor.lab.local`** trình diễn Dashboard **Grafana + Prometheus** giám sát CPU, RAM, Disk, Network thời gian thực của Server qua Nginx Reverse Proxy Port 80.
* **Bước 5 (2 phút):** Chạy `./scripts/run_all_tests.sh` tổng kết 7/7 dịch vụ đang hoạt động ổn định, sau đó cùng TV2, TV3, TV4 trả lời phản biện.

---

## 8. Cẩm nang Lệnh Quản trị & Xử lý Sự cố Nhanh (Troubleshooting)

```bash
# 1. Tổng kiểm tra toàn bộ 7 dịch vụ, cổng lắng nghe và UFW (chạy trước khi Demo)
cd ~/linux-network-services && ./scripts/run_all_tests.sh

# 2. Quản lý mạng và IP
sudo netplan apply                                  # Áp dụng cấu hình Netplan mới
ip -4 a show enp10s0                                # Kiểm tra IP tĩnh Server

# 3. Quản lý trạng thái các dịch vụ cốt lõi & giám sát
sudo systemctl restart ssh isc-dhcp-server bind9 nginx
sudo systemctl restart prometheus prometheus-node-exporter grafana-server

# 4. Kiểm tra cổng lắng nghe & cú pháp cấu hình
sudo ss -tulnp | grep -E ':(22|53|67|80|3000|9090|9100)\b'
sudo sshd -t && sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
sudo named-checkconf && sudo nginx -t

# 5. Theo dõi log thời gian thực khi gặp sự cố
journalctl -u isc-dhcp-server -f                    # Log DHCP
journalctl -u bind9 -f                              # Log DNS
journalctl -u prometheus -u grafana-server -f       # Log Monitoring
sudo tail -f /var/log/nginx/error.log               # Log lỗi Nginx
```

---

## 9. Bộ Câu hỏi Phản biện Chuyên môn Thường gặp & Cách Trả lời Điểm 10

* **Câu 1 (TV1): *"Tại sao Server bắt buộc phải đặt IP tĩnh, còn Client lại dùng DHCP?"***
  * 👉 **Trả lời:** *"Dạ máy chủ là điểm cung cấp dịch vụ trung tâm (DNS, Web, SSH, Monitoring). Nếu IP máy chủ thay đổi thì toàn bộ Client mất kết nối ngay lập tức, nên Server bắt buộc đặt IP tĩnh cố định. Ngược lại, Client là người dùng cuối số lượng lớn nên dùng DHCP giúp tự động hóa cấu hình IP/Gateway/DNS và tránh trùng lặp IP."*
* **Câu 2 (TV2): *"Quy trình cấp phát IP của DHCP diễn ra như thế nào?"***
  * 👉 **Trả lời:** *"Dạ tiến trình DORA gồm 4 bước: 1. **Discover** (Client broadcast tìm DHCP Server); 2. **Offer** (Server đề xuất IP trống kèm Gateway/DNS); 3. **Request** (Client gửi yêu cầu xác nhận thuê IP đã chọn); 4. **Acknowledge** (Server chốt giao dịch và lưu vào `/var/lib/dhcp/dhcpd.leases`)."*
* **Câu 3 (TV3): *"Tại sao dùng BIND9 mà không dùng file `/etc/hosts` để gán tên miền?"***
  * 👉 **Trả lời:** *"Dạ `/etc/hosts` chỉ có tác dụng cục bộ trên từng máy lẻ; mạng doanh nghiệp hàng trăm máy không thể đi sửa tay từng máy mỗi khi thêm tên miền như `web.lab.local` hay `monitor.lab.local`. Dùng BIND9 là giải pháp DNS tập trung, Client chỉ cần nhận IP DNS từ DHCP là phân giải được toàn mạng LAN."*
* **Câu 4 (TV4): *"Nguyên tắc cấu hình Firewall UFW của nhóm là gì?"***
  * 👉 **Trả lời:** *"Dạ nhóm tuân thủ nguyên tắc Least Privilege (Đặc quyền tối thiểu): mặc định chặn toàn bộ luồng vào (`default deny incoming`), chỉ mở đúng 4 cổng dịch vụ hợp lệ (`22/tcp`, `53`, `67/udp`, `80/tcp`). Thử nghiệm bằng `nc` từ Client cho thấy các cổng lạ như `23`, `8080` đều bị drop âm thầm (`timed out`)."*
* **Câu 5 (TV1): *"Tại sao cài thêm Prometheus (9090), Node Exporter (9100), Grafana (3000) mà trên UFW không phải mở thêm 3 cổng này?"***
  * 👉 **Trả lời:** *"Dạ để tối ưu bảo mật và thu hẹp bề mặt tấn công, cả 3 dịch vụ giám sát chỉ giao tiếp nội bộ trên `localhost` của Server. Client truy cập Grafana thông qua **Nginx Reverse Proxy** tại tên miền `http://monitor.lab.local` dùng chung **Port 80** đã mở sẵn. Khi mở rộng ra doanh nghiệp đa máy chủ, chỉ cần tách Prometheus/Grafana sang node riêng và mở Port `9100` duy nhất cho IP của node giám sát đó ạ."*

---

## 10. Checklist Nghiệm thu Dự án

- [x] Máy ảo Ubuntu Server & Client cài đặt hoàn tất, cô lập trên mạng Custom `vmnet2`.
- [x] IP tĩnh `192.168.10.10/24` cấu hình chuẩn bằng Netplan, ping thông nội bộ.
- [x] Dịch vụ OpenSSH hoạt động, đã Hardening (`PermitRootLogin no`), đăng nhập từ Client thành công.
- [x] DHCP Server cấp IP đúng dải `100–150` (`192.168.10.100`), ghi nhận đầy đủ bảng lease.
- [x] DNS BIND9 phân giải thuận/nghịch chính xác `web.lab.local` và `monitor.lab.local`.
- [x] Nginx Web Server hiển thị trang web giới thiệu nhóm qua IP và tên miền (`http://web.lab.local`).
- [x] Tường lửa UFW kích hoạt, chỉ mở đúng 4 cổng dịch vụ (`22, 53, 67, 80`), chặn đứng cổng lạ.
- [x] Giám sát tài nguyên **Prometheus + Node Exporter + Grafana** hoạt động thời gian thực tại `http://monitor.lab.local` qua Nginx Reverse Proxy.
- [x] Thực hiện đủ **11/11 Test Cases**, lưu đầy đủ ảnh minh chứng thực tế trong `evidence/`.
- [ ] Hoàn thiện Báo cáo Word 5 chương (`report/`) và Slide thuyết trình (`presentation/`).
- [ ] Cả 4 thành viên nắm chắc luồng vận hành và tập dượt phản biện trước ngày bảo vệ.
