# ĐỀ TÀI: NGHIÊN CỨU VÀ TRIỂN KHAI HỆ THỐNG DỊCH VỤ MẠNG TRÊN UBUNTU SERVER 24.04 LTS

> **Tên đề tài:** Nghiên cứu và triển khai hệ thống dịch vụ mạng doanh nghiệp trên nền tảng Ubuntu Server 24.04 LTS\
> **Môn học:** Hệ điều hành mạng (2 tín chỉ)\
> **Quy mô nhóm:** 04 thành viên\
> **Nền tảng triển khai:** Ubuntu Server 24.04 LTS (Máy chủ) & Ubuntu Desktop / Windows (Client)\
> **Môi trường ảo hóa:** VMware Workstation / VMware Fusion / VirtualBox (Chế độ Host-Only / Custom VMnet)\
> **Thời gian thực hiện:** 14 ngày\
> **Kho mã nguồn:** GitHub Repository

---

## 1. Mục tiêu và Phạm vi đề tài

### 1.1. Mục tiêu nghiên cứu
Xây dựng một hệ thống mạng máy chủ – máy trạm hoàn chỉnh, mô phỏng hạ tầng mạng dịch vụ của một doanh nghiệp vừa và nhỏ trên nền tảng **Ubuntu Server 24.04 LTS**. Hệ thống vận hành tự động, khép kín và an toàn, giải quyết trọn vẹn 5 bài toán cốt lõi:
1. **Quản trị hệ thống từ xa (Remote Management):** Quản trị dòng lệnh an toàn qua giao thức SSH.
2. **Cấp phát địa chỉ tự động (Dynamic Addressing):** Triển khai DHCP Server cấp phát IP, Subnet mask, Gateway và DNS cho toàn bộ mạng nội bộ.
3. **Dịch vụ phân giải tên miền (Name Resolution):** Thiết lập DNS Server (BIND9) phân giải thuận/nghịch cho tên miền nội bộ `lab.local`.
4. **Dịch vụ máy chủ web (Web Hosting):** Triển khai Nginx Web Server cung cấp cổng thông tin nội bộ `http://web.lab.local`.
5. **An toàn & Kiểm soát truy cập (Network Security):** Thiết lập tường lửa UFW (Uncomplicated Firewall) theo nguyên tắc đặc quyền tối thiểu (Least Privilege).

### 1.2. Phạm vi giới hạn
- **Phần bắt buộc:** Cấu hình mạng tĩnh Netplan, OpenSSH, DHCP Server (Kea/ISC-DHCP), DNS BIND9, Nginx Web Server, Tường lửa UFW, kiểm thử tích hợp 10 Test Cases.
- **Phần mở rộng (nếu còn thời gian):** Cấu hình bảo mật SSH bằng cặp khóa Public/Private Key, bật HTTPS nội bộ với chứng chỉ tự ký (Self-signed Certificate), sao lưu cấu hình tự động bằng Shell script.

---

## 2. Thiết kế Kiến trúc Hệ thống & Kế hoạch Địa chỉ IP

### 2.1. Sơ đồ kiến trúc mạng logic

```text
                           MÔI TRƯỜNG MẠNG NỘI BỘ (HOST-ONLY / VMNET)
                                 Subnet: 192.168.10.0/24
                                            │
                     ┌──────────────────────┴──────────────────────┐
                     │                                             │
          ┌─────────────────────┐                       ┌─────────────────────┐
          │    UBUNTU SERVER    │                       │    CLIENT MACHINE   │
          │    192.168.10.10    │                       │     (DHCP Client)   │
          └──────────┬──────────┘                       └──────────┬──────────┘
                     │                                             │
      ┌──────────────┼──────────────┬──────────────┐               │
      ▼              ▼              ▼              ▼               │
   OpenSSH          DHCP           DNS           Nginx             │
  (Port 22)     (Port 67/UDP)  (Port 53)       (Port 80)           │
      │              │              │              │               │
  Quản trị       Cấp IP tự      Phân giải      Web doanh           │
   từ xa         động cho       tên miền       nghiệp nội          │
                  Client        lab.local         bộ               │
      │              │              │              │               │
      └──────────────┴──────┬───────┴──────────────┘               │
                            │                                      │
                     [UFW FIREWALL]                                │
               (Chỉ mở: 22, 53, 67, 80)                            │
                            │                                      │
                            └───────── LUỒNG KẾT NỐI ──────────────┘
                                  1. Xin cấp IP tự động (DORA)
                                  2. Phân giải: web.lab.local
                                  3. Truy cập HTTP Web Server
                                  4. Quản trị viên SSH vào Server
```

### 2.2. Bảng phân bổ địa chỉ IP và thông số kỹ thuật

| Thành phần | Địa chỉ IP / Cấu hình | Mô tả chức năng |
|---|---|---|
| **Mạng mạng nội bộ** | `192.168.10.0/24` | Mạng ảo Host-Only cách ly hoàn toàn với mạng ngoài |
| **Ubuntu Server** | `192.168.10.10/24` | IP tĩnh cố định gắn trên interface máy chủ (`ens33`/`enp0s3`) |
| **Default Gateway** | `192.168.10.1` | Cổng mặc định của phân đoạn mạng nội bộ |
| **DNS Server nội bộ** | `192.168.10.10` | Máy chủ BIND9 phân giải tên miền cho mạng LAN |
| **DHCP IP Pool** | `192.168.10.100` – `192.168.10.150` | Dải cấp phát IP tự động (tối đa 51 thiết bị client) |
| **Lease Time** | Default: 600s (10p) / Max: 7200s (2h) | Thời gian cho thuê địa chỉ IP |
| **Domain nội bộ** | `lab.local` | Không gian tên miền cục bộ phục vụ phân giải |
| **Web Server** | `web.lab.local` (`192.168.10.10`) | Trang web nội bộ Nginx phục vụ qua giao thức HTTP |
| **Client** | Nhận động từ DHCP Server | Máy kiểm thử (Ubuntu Desktop hoặc Windows ảo) |

### 2.3. Bảng cổng dịch vụ (Port Matrix) và Chính sách Tường lửa (UFW)

| Dịch vụ | Cổng (Port) | Giao thức (Protocol) | Chiều (Direction) | Hành động (Action) |
|---|---|---|---|---|
| **SSH** | `22` | TCP | Inbound | `ALLOW` (Cho phép quản trị từ xa) |
| **DNS** | `53` | UDP & TCP | Inbound | `ALLOW` (Truy vấn tên miền nội bộ) |
| **DHCP** | `67` | UDP | Inbound | `ALLOW` (Tiếp nhận yêu cầu cấp IP từ Client) |
| **HTTP (Nginx)** | `80` | TCP | Inbound | `ALLOW` (Truy cập website nội bộ) |
| **Các cổng khác** | Tất cả | Tất cả | Inbound | **`DEFAULT DENY` (Chặn toàn bộ)** |

---

## 3. Phân công Nhân sự & Trách nhiệm (Nhóm 04 Thành viên)

Dự án được phân bổ khoa học thành 4 module độc lập nhưng liên kết chặt chẽ theo dạng chuỗi giá trị, do Nhóm trưởng (TV1) trực tiếp tích hợp và điều phối thực hiện demo:

```text
[TV1: Xuân (Leader)] ───► [TV2: Vượng] ───► [TV3: Trí] ────────► [TV4: Đạt] ──────► [TV1: Xuân]
  (Nền tảng & SSH)        (Cấp IP DHCP)    (DNS & Nginx Web)    (Tường lửa UFW)   (Tích hợp & Demo)
```

### Thành viên 1: Nguyễn Anh Xuân (Nhóm trưởng - Leader)
* **Module phụ trách:** Nền tảng Ubuntu Server 24.04 LTS, Quản trị từ xa OpenSSH, Tích hợp hệ thống & Thực hiện Demo.
* **Nhiệm vụ chính:**
  1. Quản lý dự án, lập kế hoạch, khởi tạo Git Repository và chuẩn hóa tài liệu nhóm.
  2. Cài đặt hệ điều hành Ubuntu Server 24.04 LTS trên nền tảng máy ảo VMware.
  3. Cấu hình mạng tĩnh bằng Netplan (`/etc/netplan/*.yaml`) gán cố định IP `192.168.10.10/24`.
  4. Cài đặt, kích hoạt và bảo mật dịch vụ OpenSSH Server.
  5. Thiết lập tài khoản quản trị hệ thống phục vụ demo; kiểm tra kết nối từ máy Host/Client.
  6. **Trực tiếp chủ trì tích hợp toàn bộ hệ thống (System Integration):** ghép nối và vận hành đồng bộ 4 dịch vụ (SSH, DHCP, DNS, Nginx) kết hợp Tường lửa UFW.
  7. **Trực tiếp thực hiện buổi Demo trực tiếp trước Giảng viên:** chuẩn bị môi trường kiểm thử End-to-End, thực hiện các thao tác demo 5 bước từ Client và Server.
  8. Điều phối biên soạn Báo cáo cuối kỳ và tổng duyệt kịch bản bảo vệ.
* **Sản phẩm bàn giao:**
  - File cấu hình Netplan chuẩn (`configs/network/01-netplan.yaml`).
  - File cấu hình SSH (`configs/ssh/sshd_config`).
  - Tài liệu hướng dẫn cài đặt nền tảng (`docs/01-server-setup-guide.md`).
  - Kịch bản demo và Biên bản kiểm thử tích hợp 10 Test Cases (`docs/05-integration-testing.md`).
* **Lệnh minh chứng kiểm tra:**
  ```bash
  ip a && ip route
  sudo systemctl status ssh
  ssh anhxuan-devops@192.168.10.10
  ```
* **Quy trình thực tế đã triển khai (Giai đoạn 2 — để các thành viên nắm rõ hạ tầng):**
  1. **Mạng ảo (VMware Fusion):** Server dùng 2 card (`enp2s0` NAT để cài gói `apt`, `enp10s0` *Private to my Mac* làm mạng nội bộ `192.168.10.0/24`); Client chỉ dùng 1 card (`Private to my Mac`) để tránh xung đột Gateway/DNS.
  2. **IP tĩnh Netplan (`/etc/netplan/01-netcfg.yaml`):** Sao lưu config cũ vào `/etc/netplan/backup/`, giữ `enp2s0` chạy `dhcp4: true`, gắn `enp10s0` IP tĩnh `192.168.10.10/24` (không gắn default route lên `enp10s0` để tránh đụng Internet của NAT), sau đó `sudo chmod 600` và `sudo netplan apply`.
  3. **Bảo mật OpenSSH (`/etc/ssh/sshd_config.d/01-lab-security.conf`):** Tạo file cấu hình phụ gồm `Port 22`, `PermitRootLogin no` (cấm đăng nhập thẳng bằng root), `MaxAuthTries 5` (chống dò mật khẩu), `PasswordAuthentication yes` (phục vụ demo), kiểm tra bằng `sudo sshd -t` và bật `ssh.service`.
  4. **Kiểm thử từ Client:** Đặt IP tạm `192.168.10.20/24` trên Client (trước khi có DHCP của TV2) để `ping` và `ssh anhxuan-devops@192.168.10.10`. *(Xem chi tiết từng bước tại `docs/01-server-setup-guide.md`)*.

---

### Thành viên 2: Nguyễn Phúc Vượng
* **Module phụ trách:** Dịch vụ cấp phát địa chỉ IP tự động (DHCP Server).
* **Nhiệm vụ chính:**
  1. Nghiên cứu cơ chế vận hành giao thức DHCP và tiến trình 4 bước DORA (Discover – Offer – Request – Acknowledge).
  2. Cài đặt và cấu hình dịch vụ DHCP Server (ISC-DHCP-Server hoặc Kea DHCP trên Ubuntu 24.04).
  3. Khai báo Subnet `192.168.10.0/24`, dải cấp phát `192.168.10.100 - 150`, Gateway `192.168.10.1`, DNS Server `192.168.10.10`, Domain name `lab.local`.
  4. Gán interface lắng nghe cố định, xử lý lỗi xung đột với DHCP có sẵn của phần mềm ảo hóa.
  5. Viết script kiểm tra và hiển thị các IP đang được cấp phát (Lease file).
* **Sản phẩm bàn giao:**
  - File cấu hình DHCP (`configs/dhcp/dhcpd.conf` hoặc `kea-dhcp4.conf`).
  - Script kiểm tra danh sách máy đang thuê IP (`scripts/check_dhcp_leases.sh`).
  - Tài liệu hướng dẫn cấu hình DHCP (`docs/02-dhcp-service-guide.md`).
* **Lệnh minh chứng kiểm tra:**
  ```bash
  sudo systemctl status isc-dhcp-server
  cat /var/lib/dhcp/dhcpd.leases
  # Trên Client:
  ip -4 a show enp2s0
  ```
* **Quy trình thực tế đã triển khai (Giai đoạn 3):**
  1. **Cài đặt & gán interface (`/etc/default/isc-dhcp-server`):** Cài gói `isc-dhcp-server` trên Ubuntu Server, cấu hình `INTERFACESv4="enp10s0"` để chỉ lắng nghe trên card mạng nội bộ.
  2. **Nạp cấu hình DHCP (`/etc/dhcp/dhcpd.conf`):** Khai báo dải `192.168.10.100–150`, Gateway `192.168.10.1`, DNS `192.168.10.10`, domain `lab.local`, lease time `600s/7200s`; kiểm tra cú pháp bằng `sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf` và khởi động dịch vụ.
  3. **Xử lý xung đột DHCP của VMware Fusion:** Tạo mạng Custom `vmnet2` trong *VMware Fusion $\rightarrow$ Settings $\rightarrow$ Network* (bỏ tích DHCP và NAT của VMware), sau đó chuyển card `enp10s0` của Server và `enp2s0` của Client sang `vmnet2`.
  4. **Kiểm thử từ Client:** Chạy `nmcli dev disconnect enp2s0 && nmcli dev connect enp2s0` $\rightarrow$ Client nhận đúng IP `192.168.10.100/24` và Server ghi nhận lease trong `/var/lib/dhcp/dhcpd.leases`. *(Xem chi tiết tại `docs/02-dhcp-service-guide.md`)*.

---

### Thành viên 3: Nguyễn Minh Trí
* **Module phụ trách:** Dịch vụ phân giải tên miền nội bộ (DNS BIND9) & Máy chủ Web Nginx.
* **Nhiệm vụ chính:**
  1. Nghiên cứu nguyên lý phân giải tên miền DNS và cấu trúc BIND9 (Zone file, Resource Records).
  2. Cài đặt gói `bind9`, `bind9utils`, `dnsutils` trên Ubuntu Server.
  3. Cấu hình file `named.conf.options` (Forwarders, quyền truy vấn ACL cho mạng LAN).
  4. Tạo Forward Lookup Zone (`db.lab.local`) phân giải tên miền `web.lab.local`, `ns.lab.local`, `server.lab.local` về IP `192.168.10.10`.
  5. Tạo Reverse Lookup Zone (`db.10.168.192`) phân giải ngược từ địa chỉ IP về tên miền (PTR Record).
  6. **Cài đặt và cấu hình Web Server Nginx;** thiết lập Virtual Host/Server Block phục vụ website `http://web.lab.local`.
  7. **Thiết kế giao diện trang web nội bộ chuẩn HTML5/CSS** giới thiệu thông tin đề tài và 4 thành viên.
  8. Kiểm thử tính đúng đắn của cú pháp cấu hình BIND9, Nginx và kiểm thử phân giải DNS, truy cập Web từ máy Client.
* **Sản phẩm bàn giao:**
  - File cấu hình BIND9 (`configs/dns/named.conf.local`, `configs/dns/db.lab.local`, `configs/dns/db.10.168.192`).
  - File cấu hình Nginx Server Block (`configs/nginx/web.lab.local.conf`).
  - Mã nguồn trang web demo (`configs/nginx/html/index.html`).
  - Script kiểm thử tự động phân giải DNS (`scripts/test_dns.sh`).
  - Tài liệu hướng dẫn cấu hình DNS (`docs/03-dns-service-guide.md`) & Web Nginx (`docs/04-nginx-web-guide.md`).
* **Lệnh minh chứng kiểm tra:**
  ```bash
  sudo named-checkconf
  sudo named-checkzone lab.local /etc/bind/zones/db.lab.local
  sudo nginx -t
  sudo systemctl status bind9 nginx
  # Trên Client:
  dig web.lab.local +short
  wget -S --spider http://web.lab.local
  ```
* **Quy trình thực tế đã triển khai (Giai đoạn 4):**
  1. **DNS BIND9 (`/etc/bind/`):** Cài `bind9 bind9utils dnsutils`, cấu hình `named.conf.options` (`allow-query { localhost; 192.168.10.0/24; };`), khai báo `named.conf.local`, tạo `/etc/bind/zones/db.lab.local` (Forward) và `db.10.168.192` (Reverse), kiểm tra bằng `named-checkconf` / `named-checkzone`.
  2. **Nginx Web Server (`/etc/nginx/`):** Cài `nginx`, nạp trang HTML tại `/var/www/lab.local/html/index.html`, tạo Server Block `/etc/nginx/sites-available/web.lab.local.conf` (gắn `default_server` để cả IP và tên miền đều vào đúng web nhóm), xóa `sites-enabled/default`, kiểm tra `sudo nginx -t` và khởi động lại.
  3. **Kiểm thử từ Client:** Client tự động dùng DNS `192.168.10.10` (do DHCP cấp) phân giải `web.lab.local` và `dig -x 192.168.10.10`; `wget -S --spider` tới cả `http://192.168.10.10` và `http://web.lab.local` đều trả về `HTTP/1.1 200 OK`. *(Xem chi tiết tại `docs/03-dns-service-guide.md` và `docs/04-nginx-web-guide.md`)*.

---

### Thành viên 4: Nguyễn Thành Đạt
* **Module phụ trách:** Tường lửa UFW, An toàn hệ thống & Slide thuyết trình.
* **Nhiệm vụ chính:**
  1. Nghiên cứu cơ chế kiểm soát gói tin và chính sách tường lửa trên Linux với UFW (Uncomplicated Firewall).
  2. Cấu hình tường lửa UFW theo chính sách bảo mật: Mở chính xác các cổng 22/tcp, 53/any, 67/udp, 80/tcp; kích hoạt chế độ chặn mặc định `default deny incoming`.
  3. Thực hiện kiểm thử an toàn mạng: thử nghiệm quét cổng (port scanning) để chứng minh UFW chặn đứng các port không được phép.
  4. Phối hợp với TV1 trong buổi kiểm thử tích hợp toàn bộ hệ thống.
  5. **Thiết kế Slide thuyết trình bảo vệ đề tài hoàn chỉnh (`presentation/final-slides.pptx`)** với cấu trúc chuyên nghiệp, trực quan.
* **Sản phẩm bàn giao:**
  - Script kích hoạt chính sách Firewall UFW (`scripts/setup_firewall.sh`).
  - File danh sách luật tường lửa UFW (`configs/firewall/ufw-rules.txt`).
  - Tài liệu hướng dẫn cấu hình Firewall & An toàn mạng (`docs/05-firewall-security-guide.md`).
  - Slide thuyết trình hoàn chỉnh (`presentation/final-slides.pptx`).
* **Lệnh minh chứng kiểm tra:**
  ```bash
  sudo ufw status verbose
  sudo ufw app list
  ```

---

## 4. Kế hoạch Thực hiện theo Giai đoạn (14 Ngày)

| Giai đoạn | Thời gian | Nhiệm vụ trọng tâm | Sản phẩm đầu ra | Người phụ trách |
|---|---|---|---|---|
| **Giai đoạn 1** | Ngày 1–2 | Chốt đề tài, thống nhất mô hình IP, khởi tạo Git Repo & phân công | Project Charter, README.md, sơ đồ mạng | TV1 (Leader) |
| **Giai đoạn 2** | Ngày 3–4 | Cài đặt Ubuntu Server, cấu hình Netplan IP tĩnh, kích hoạt SSH | Server chạy ổn định, SSH kết nối thành công | TV1 (Xuân) |
| **Giai đoạn 3** | Ngày 5–7 | Triển khai dịch vụ cấp IP tự động DHCP Server | DHCP cấp đúng dải 100–150 cho Client | TV2 (Vượng) |
| **Giai đoạn 4** | Ngày 8–9 | Triển khai dịch vụ phân giải tên miền DNS BIND9 & Máy chủ Web Nginx | Phân giải thuận/nghịch `web.lab.local`, website hoạt động | TV3 (Trí) |
| **Giai đoạn 5** | Ngày 10–11| Thiết lập tường lửa UFW & Chính sách an toàn mạng | Firewall chặn cổng lạ, bảo vệ nghiêm ngặt hệ thống | TV4 (Đạt) |
| **Giai đoạn 6** | Ngày 12–13| Tích hợp toàn hệ thống, kiểm thử 10 Test Cases, thu thập log & ảnh | Bảng Test Case hoàn chỉnh, biên bản nghiệm thu | TV1 chủ trì (Cả nhóm phối hợp) |
| **Giai đoạn 7** | Ngày 14 | Hoàn thiện Báo cáo tổng kết 5 chương, hoàn thiện Slide & Tổng duyệt Demo | Báo cáo hoàn chỉnh, Slide PPTX, Kịch bản Demo chuẩn | TV1 (Demo & Báo cáo), TV4 (Slide) |

---

## 5. Cấu trúc Thư mục Dự án Chuẩn hóa

```text
Network-Operating-System-Ubuntu-Server/
├── .gitignore                      # Loại bỏ file tạm, log thừa, file máy ảo (*.vmdk, *.iso)
├── README.md                       # Tài liệu hướng dẫn quy trình và tổng quan đề tài
│
├── docs/                           # Tài liệu quản lý, thiết kế và hướng dẫn dịch vụ
│   ├── 00-nghien-cuu-co-so-ly-thuyet.md # Báo cáo nghiên cứu cơ sở lý thuyết 4 module (Cả nhóm)
│   ├── 01-server-setup-guide.md    # Hướng dẫn cài đặt Ubuntu Server & SSH (TV1)
│   ├── 02-dhcp-service-guide.md    # Hướng dẫn cấu hình DHCP Server (TV2)
│   ├── 03-dns-service-guide.md     # Hướng dẫn cấu hình DNS BIND9 (TV3)
│   ├── 04-nginx-web-guide.md       # Hướng dẫn cấu hình Nginx Web Server (TV3)
│   ├── 05-firewall-security-guide.md # Hướng dẫn Firewall UFW & An toàn mạng (TV4)
│   └── 06-integration-testing.md   # Biên bản kiểm thử tích hợp 10 Test Cases & Demo (TV1)
│
├── configs/                        # Lưu trữ toàn bộ file cấu hình gốc của các dịch vụ
│   ├── network/
│   │   └── 01-netplan.yaml         # Cấu hình IP tĩnh Netplan
│   ├── ssh/
│   │   └── sshd_config             # Cấu hình dịch vụ SSH
│   ├── dhcp/
│   │   └── dhcpd.conf              # Cấu hình dải IP và tham số DHCP
│   ├── dns/
│   │   ├── named.conf.local        # Khai báo zone DNS
│   │   ├── named.conf.options      # Cấu hình chuyển tiếp DNS
│   │   ├── db.lab.local            # Forward Zone (phân giải thuận)
│   │   └── db.10.168.192           # Reverse Zone (phân giải nghịch)
│   ├── nginx/
│   │   ├── web.lab.local.conf      # Virtual host Nginx
│   │   └── html/
│   │       └── index.html          # Trang web giới thiệu nhóm
│   └── firewall/
│       └── ufw-rules.txt           # Danh sách luật UFW
│
├── scripts/                        # Các shell script tự động hóa cài đặt và kiểm thử
│   ├── setup_network.sh            # Script áp dụng IP tĩnh Netplan
│   ├── check_dhcp_leases.sh        # Script đọc và lọc danh sách lease DHCP
│   ├── test_dns.sh                 # Script tự động kiểm tra phân giải DNS
│   ├── setup_firewall.sh           # Script thiết lập nhanh tường lửa UFW
│   └── run_all_tests.sh            # Script tự động chạy kiểm thử toàn bộ hệ thống
│
├── evidence/                       # Ảnh chụp màn hình minh chứng kết quả kiểm thử
│   ├── server/                     # Ảnh `ip a`, `ip route`
│   ├── ssh/                        # Ảnh đăng nhập SSH thành công
│   ├── dhcp/                       # Ảnh Client nhận IP, bảng lease
│   ├── dns/                        # Ảnh `dig`, `nslookup`
│   ├── web/                        # Ảnh truy cập web trên trình duyệt
│   └── firewall/                   # Ảnh `ufw status verbose`
│
├── report/                         # Báo cáo tổng kết hoàn chỉnh
│   └── Bao_cao_He_dieu_hanh_mang_Nhom.docx
│
└── presentation/                   # Slide trình chiếu bảo vệ đề tài
    └── Slide_Bao_ve_He_dieu_hanh_mang.pptx
```

---

## 6. Ma trận 10 Kịch bản Kiểm thử Nghiệm thu (Test Cases)

| Test ID | Tên bài kiểm thử | Thao tác thực hiện | Kết quả mong đợi | Người kiểm tra | Trạng thái |
|:---:|---|---|---|:---:|:---:|
| **TC-01** | IP tĩnh Server | Chạy `ip a show dev <iface>` | Server có đúng IP `192.168.10.10/24` | TV1 | [x] Pass |
| **TC-02** | Trạng thái SSH | Chạy `sudo systemctl status ssh` | Trạng thái `active (running)`, Port 22 | TV1 | [x] Pass |
| **TC-03** | Đăng nhập SSH từ xa | Trên Client gõ: `ssh anhxuan-devops@192.168.10.10` | Đăng nhập thành công vào Terminal Server | TV1 | [x] Pass |
| **TC-04** | Client xin IP động | Đặt Client nhận DHCP, kích hoạt kết nối | Client nhận IP trong dải `192.168.10.100-150` | TV2 | [x] Pass |
| **TC-05** | Bảng cấp phát DHCP | Chạy `cat /var/lib/dhcp/dhcpd.leases` | Ghi nhận MAC Client và IP tương ứng | TV2 | [x] Pass |
| **TC-06** | Phân giải thuận DNS | Client chạy `dig web.lab.local +short` | Trả về chính xác địa chỉ `192.168.10.10` | TV3 | [x] Pass |
| **TC-07** | Phân giải nghịch DNS | Client chạy `dig -x 192.168.10.10 +short` | Trả về tên miền `ns.lab.local.` | TV3 | [x] Pass |
| **TC-08** | Truy cập Web bằng IP | Mở trình duyệt / `wget` gõ `http://192.168.10.10` | Nginx trả về trang web demo đề tài | TV3 | [x] Pass |
| **TC-09** | Truy cập Web bằng Domain | Mở trình duyệt / `wget` gõ `http://web.lab.local` | Trang web load thành công qua tên miền | TV3 | [x] Pass |
| **TC-10** | Chính sách Firewall UFW | Chạy `sudo ufw status verbose` | Chỉ mở 22, 53, 67, 80; chặn mọi port khác | TV4 | [ ] Pass |

---

## 7. Kịch bản Demo Trực tiếp trước Giảng viên (Chiến lược lấy điểm 10 trong 10 phút)

Khi lên báo cáo, nhóm chuẩn bị sẵn 2 máy ảo: **Ubuntu Server** (chạy nền) và **Client** (Ubuntu Desktop/Windows). **Nhóm trưởng (TV1 - Tôi) trực tiếp tích hợp toàn bộ hệ thống và thực hiện trọn vẹn quy trình demo trực tiếp** trước Giảng viên theo kịch bản 5 bước mạch lạc:

```text
[BƯỚC 1: Quản trị & Mạng (2p)]  ──► TV1 demo IP tĩnh Server (Netplan) & SSH từ Client vào Server.
[BƯỚC 2: Cấp IP tự động (2p)]   ──► TV1 demo Client nhận IP qua DHCP (module TV2), show leases.
[BƯỚC 3: Phân giải DNS (2p)]    ──► TV1 demo Client dig tên miền web.lab.local (module DNS TV3).
[BƯỚC 4: Web & Tường lửa (2p)]  ──► TV1 mở web http://web.lab.local (Nginx TV3) & show UFW (TV4).
[BƯỚC 5: Tổng kết & Hỏi đáp]    ──► TV1 tổng kết giá trị hệ thống, điều phối nhóm trả lời phản biện.
```

* **Bước 1 (TV1 thực hiện - 2 phút):** Mở terminal Client, gõ lệnh `ssh user@192.168.10.10` để chứng minh quyền quản trị máy chủ Linux từ xa. Show lệnh `ip a` chứng minh server có IP cố định `192.168.10.10/24`.
* **Bước 2 (TV1 thực hiện - 2 phút):** Trên Client, thực hiện xin cấp lại IP (ngắt/bật card mạng hoặc `sudo dhclient -v`). Show lệnh `ip a` trên Client để thầy cô thấy Client đã được cấp IP động `192.168.10.101` từ DHCP Server (module của TV2). Quay lại Server show file `cat /var/lib/dhcp/dhcpd.leases` để chứng minh cơ chế cấp phát.
* **Bước 3 (TV1 thực hiện - 2 phút):** Trên Client, gõ lệnh `dig web.lab.local` và `dig -x 192.168.10.10`. Chỉ cho thầy cô thấy kết quả phân giải thuận/nghịch trực tiếp từ Server DNS nội bộ `192.168.10.10` (module DNS do TV3 xây dựng).
* **Bước 4 (TV1 thực hiện - 2 phút):** Mở trình duyệt Web trên Client, gõ địa chỉ `http://web.lab.local`. Website doanh nghiệp hiển thị mượt mà (module Nginx do TV3 cấu hình). Tiếp đó, trên Terminal Server gõ `sudo ufw status verbose` để chứng minh hệ thống đang được tường lửa (module do TV4 thiết lập) bảo vệ nghiêm ngặt: chỉ mở 4 cổng 22, 53, 67, 80 và chặn toàn bộ cổng lạ.
* **Bước 5 (TV1 chủ trì - 2 phút):** Tóm tắt toàn bộ kết quả tích hợp hệ thống, khẳng định giải pháp vận hành đồng bộ và ổn định; sau đó điều phối các thành viên phụ trách từng module (TV2, TV3, TV4) sẵn sàng đón nhận và trả lời câu hỏi phản biện chuyên sâu từ thầy cô.

---

## 8. Cẩm nang Lệnh Quản trị & Xử lý Sự cố Nhanh (Troubleshooting)

```bash
# 1. Quản lý mạng và IP
sudo netplan apply                     # Áp dụng cấu hình Netplan mới
resolvectl status                      # Kiểm tra DNS đang sử dụng

# 2. Quản lý trạng thái các dịch vụ hệ thống
sudo systemctl restart ssh             # Khởi động lại SSH
sudo systemctl restart isc-dhcp-server # Khởi động lại DHCP
sudo systemctl restart bind9           # Khởi động lại DNS BIND9
sudo systemctl restart nginx           # Khởi động lại Web Nginx

# 3. Kiểm tra cổng lắng nghe (Rất quan trọng)
sudo ss -tulnp | grep -E ':(22|53|67|80)'

# 4. Kiểm tra cú pháp trước khi chạy (Tránh lỗi crash dịch vụ)
sudo named-checkconf                   # Kiểm tra cú pháp BIND9
sudo nginx -t                          # Kiểm tra cú pháp Nginx

# 5. Theo dõi log dịch vụ khi gặp lỗi (Real-time logs)
journalctl -u isc-dhcp-server -f       # Log DHCP
journalctl -u bind9 -f                 # Log DNS
sudo tail -f /var/log/nginx/error.log  # Log lỗi Nginx
```

---

## 9. Bộ Câu hỏi Phản biện Chuyên môn Thường gặp & Cách Trả lời Điểm 10

* **Câu 1: *"Tại sao Server bắt buộc phải đặt IP tĩnh, còn Client lại dùng DHCP?"***
  * 👉 **Trả lời:** *"Dạ thưa thầy/cô, máy chủ đóng vai trò là điểm cung cấp dịch vụ (DNS, Web, SSH). Nếu IP của máy chủ thay đổi thì toàn bộ Client sẽ mất kết nối. Do đó Server bắt buộc cấu hình IP tĩnh cố định. Ngược lại, Client là người dùng cuối thường xuyên thay đổi và số lượng lớn, dùng DHCP giúp tự động hóa cấu hình, tiết kiệm thời gian quản trị và tránh trùng lặp IP."*
* **Câu 2: *"Quy trình cấp phát IP của DHCP diễn ra như thế nào?"***
  * 👉 **Trả lời:** *"Dạ tiến trình DORA gồm 4 bước: 1. **Discover:** Client phát quảng bá tìm DHCP Server; 2. **Offer:** Server gửi đề xuất địa chỉ IP; 3. **Request:** Client chính thức gửi yêu cầu thuê IP đó; 4. **Acknowledge:** Server gửi xác nhận chấp thuận và ghi vào bảng lease."*
* **Câu 3: *"Tại sao dùng BIND9 mà không dùng file /etc/hosts để gán tên miền?"***
  * 👉 **Trả lời:** *"Dạ file /etc/hosts chỉ có tác dụng cục bộ trên 1 máy đơn lẻ, nếu mạng có 100 máy thì phải đi sửa thủ công 100 lần. Dùng BIND9 là giải pháp máy chủ DNS tập trung cho toàn mạng LAN, mọi Client chỉ cần trỏ DNS về Server là tự động phân giải được, chuẩn mô hình doanh nghiệp."*
* **Câu 4: *"Nguyên tắc cấu hình Firewall UFW của nhóm là gì?"***
  * 👉 **Trả lời:** *"Dạ nhóm tuân thủ nguyên tắc Least Privilege (Đặc quyền tối thiểu): thiết lập chính sách mặc định là Chặn toàn bộ luồng vào (default deny incoming), sau đó chỉ mở đúng các port của 4 dịch vụ đang phục vụ (22, 53, 67, 80). Tất cả các port quét khác đều bị từ chối để chống tấn công mạng."*

---

## 10. Checklist Nghiệm thu Dự án

- [x] Máy ảo Ubuntu Server 24.04 LTS cài đặt hoàn tất, card mạng Host-Only.
- [x] IP tĩnh `192.168.10.10/24` cấu hình đúng bằng Netplan, ping thông nội bộ.
- [x] Dịch vụ SSH hoạt động, đăng nhập từ xa thành công.
- [x] DHCP Server cấp IP đúng dải 100–150, ghi nhận đầy đủ bảng lease.
- [x] DNS BIND9 phân giải thuận/nghịch chính xác tên miền `web.lab.local`.
- [x] Nginx Web Server hiển thị trang web giới thiệu nhóm qua tên miền.
- [ ] Tường lửa UFW kích hoạt, chỉ mở đúng 4 cổng dịch vụ.
- [ ] Thực hiện đủ 10 Test Cases, có ảnh chụp minh chứng lưu tại `evidence/`.
- [ ] Báo cáo Word 5 chương hoàn chỉnh, Slide thuyết trình 15–20 trang sẵn sàng.
- [ ] Cả 4 thành viên đều hiểu rõ luồng vận hành và tự tin trả lời phản biện.
