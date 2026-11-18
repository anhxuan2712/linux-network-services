# BÁO CÁO NGHIÊN CỨU CƠ SỞ LÝ THUYẾT CÁC DỊCH VỤ MẠNG (PHẦN NGHIÊN CỨU TIỀN TRIỂN KHAI)

> **Môn học:** Hệ điều hành mạng (Network Operating System)\
> **Đề tài:** Nghiên cứu và triển khai hệ thống dịch vụ mạng doanh nghiệp trên nền tảng Ubuntu Server 24.04 LTS\
> **Mục đích tài liệu:** Tổng hợp toàn bộ nội dung nghiên cứu lý thuyết, nguyên lý hoạt động, cơ chế xử lý gói tin và chuẩn giao thức của 4 module trước khi tiến hành cấu hình thực tế. Tài liệu này đóng vai trò là Chương 2 (Cơ sở lý thuyết) trong Báo cáo tổng kết cuối kỳ.

---

## TÓM TẮT TRỰC QUAN: HỆ THỐNG MẠNG NHÌN TỪ "ĐỜI THỰC" (ĐỌC 2 PHÚT LÀ HIỂU)

> Để cả 4 thành viên dễ dàng nắm bắt bức tranh toàn cảnh mà không bị ngợp bởi thuật ngữ học thuật, hãy hình dung hệ thống mạng đề tài này như việc vận hành một **Tòa nhà Văn phòng Doanh nghiệp**:

| Thành phần kỹ thuật | Hình tượng đời thực | Vai trò trong hệ thống | Thành viên |
|---|---|---|---|
| **Ubuntu Server & IP tĩnh** | **Mặt bằng tòa nhà & Số nhà cố định** | Số nhà bắt buộc cố định (`192.168.10.10`) để mọi người không bị lạc đường. | **TV1 (Xuân)** |
| **OpenSSH (Port 22)** | **Chìa khóa thông minh điều khiển từ xa** | Đường hầm bí mật có mã hóa, giúp quản trị viên ngồi bất kỳ đâu cũng mở terminal điều khiển máy chủ. | **TV1 (Xuân)** |
| **DHCP Server (Port 67)** | **Bác lễ tân phát thẻ phòng tự động** | Khách cắm mạng vào là được bác cấp ngay IP (`192.168.10.101`) qua 4 bước DORA (Hỏi - Cho - Đồng ý - Xác nhận). | **TV2 (Vượng)** |
| **DNS BIND9 (Port 53)** | **Cuốn danh bạ điện thoại nội bộ** | Dịch tên miền thân thiện (`web.lab.local`) thành số IP (`192.168.10.10`) mà máy tính hiểu được. | **TV3 (Trí)** |
| **Nginx Web Server (Port 80)** | **Nhân viên tiếp tân bưng tài liệu** | Khi khách gõ đúng địa chỉ, Nginx bưng ngay trang web (`index.html`) giới thiệu công ty và 4 thành viên ra màn hình. | **TV3 (Trí)** |
| **Tường lửa UFW** | **Bác bảo vệ gác cổng nghiêm ngặt** | Mặc định đóng hết 65.535 cửa (`Default Deny`), chỉ mở đúng 4 cửa làm ăn hợp pháp (22, 53, 67, 80). Cửa khác cấm vào! | **TV4 (Đạt)** |

```text
                               LUỒNG HOẠT ĐỘNG 1 PHÚT KHI DEMO:
[Client cắm mạng] ──► Bác lễ tân DHCP cấp IP ──► Gõ tên web vào trình duyệt ──► Cuốn danh bạ DNS chỉ đường
                                                                                        │
[Trang web hiện lên!] ◄── Anh phục vụ Nginx trả file ◄── Bác bảo vệ UFW mở Cửa 80 ◄──────┘
         │
[Bạn gõ lệnh SSH] ──► Dùng chìa khóa đi vào Cửa 22, chứng minh quyền quản trị toàn bộ hệ thống!
```

---

## MỤC LỤC
1. [Module 1: Nghiên cứu Hệ điều hành Ubuntu Server 24.04 & Quản trị SSH (TV1: Nguyễn Anh Xuân)](#1-module-1-nghiên-cứu-hệ-điều-hành-ubuntu-server-2404--quản-trị-ssh-tv1)
2. [Module 2: Nghiên cứu Giao thức Cấp phát IP Động DHCP & Tiến trình DORA (TV2: Nguyễn Phúc Vượng)](#2-module-2-nghiên-cứu-giao-thức-cấp-phát-ip-động-dhcp--tiến-trình-dora-tv2)
3. [Module 3: Nghiên cứu Hệ thống Phân giải Tên miền DNS BIND9 & Web Server Nginx (TV3: Nguyễn Minh Trí)](#3-module-3-nghiên-cứu-hệ-thống-phân-giải-tên-miền-dns-bind9--web-server-nginx-tv3)
4. [Module 4: Nghiên cứu Cơ chế Lọc Gói Tường lửa UFW & Mô hình An ninh (TV4: Nguyễn Thành Đạt)](#4-module-4-nghiên-cứu-cơ-chế-lọc-gói-tường-lửa-ufw--mô-hình-an-ninh-tv4)

---

<a name="1-module-1-nghiên-cứu-hệ-điều-hành-ubuntu-server-2404--quản-trị-ssh-tv1"></a>
## 1. Module 1: Nghiên cứu Hệ điều hành Ubuntu Server 24.04 & Quản trị SSH (TV1: Nguyễn Anh Xuân)

### 1.1. Tổng quan kiến trúc Ubuntu Server 24.04 LTS (Noble Numbat)
* **Nhân Linux (Linux Kernel 6.8+):** Quản lý tài nguyên phần cứng (CPU scheduling, Virtual Memory Management, TCP/IP Network Stack).
* **Init System (systemd):** Bộ quản lý tiến trình khởi động hệ thống theo cấu trúc song song, quản lý dịch vụ thông qua các unit file (`*.service`, `*.socket`).
* **Cơ chế cấu hình mạng Netplan:**
  * Kể từ các bản Ubuntu hiện đại, cấu hình mạng không còn dùng trực tiếp file `/etc/network/interfaces`. Thay vào đó, Canonical sử dụng **Netplan** – công cụ trừu tượng hóa cấu hình mạng sử dụng định dạng YAML.
  * Netplan phân tích cú pháp file `.yaml` tại `/etc/netplan/` và biên dịch thành cấu hình cho backend renderer phía dưới (mặc định trên server là `systemd-networkd`).
  * **Tại sao máy chủ bắt buộc đặt IP tĩnh:** Để cung cấp dịch vụ mạng (DNS, DHCP, Web, SSH) tin cậy, vị trí của máy chủ trên không gian mạng phải là bất biến. Nếu IP bị thay đổi, mọi yêu cầu từ Client và cấu hình trỏ dịch vụ sẽ bị tê liệt.

### 1.2. Nghiên cứu Giao thức Quản trị Dòng lệnh từ xa OpenSSH (Port 22/TCP)
* **Khái niệm:** SSH (Secure Shell) là giao thức mạng mật mã dùng để vận hành các dịch vụ mạng một cách an toàn qua mạng không an toàn. SSH thay thế hoàn toàn giao thức Telnet và rlogin (truyền văn bản rõ - plaintext).
* **Cơ chế hoạt động và Bắt tay mã hóa (SSH Handshake):**
  1. **Thỏa thuận phiên bản giao thức:** Client và Server trao đổi phiên bản SSH hỗ trợ (hiện nay chuẩn hóa SSH-2).
  2. **Trao đổi khóa (Key Exchange - KEX):** Sử dụng thuật toán Diffie-Hellman hoặc Elliptic Curve Diffie-Hellman (ECDH) để sinh ra **Khóa phiên dùng chung (Shared Session Key)** mà không cần truyền khóa qua đường truyền.
  3. **Xác thực Server (Host Key Verification):** Server gửi Public Host Key (`/etc/ssh/ssh_host_*_key.pub`). Client đối chiếu với file `~/.ssh/known_hosts` để chống tấn công Man-in-the-Middle (MitM).
  4. **Thiết lập kênh mã hóa đối xứng:** Toàn bộ dữ liệu sau đó được mã hóa bằng thuật toán mã hóa đối xứng mạnh (AES-256-GCM, ChaCha20-Poly1305).
  5. **Xác thực người dùng (User Authentication):** 
     * *Password Authentication:* Truyền mật khẩu đã được mã hóa trong kênh an toàn.
     * *Public Key Authentication:* Sử dụng cặp khóa RSA/Ed25519; Server gửi một chuỗi ngẫu nhiên (challenge), Client ký bằng Private Key và gửi lại để chứng minh danh tính.

```text
[CLIENT]                                                 [UBUNTU SERVER]
   │                                                            │
   ├─────────────── 1. Khởi tạo kết nối TCP Port 22 ───────────►│
   │◄────────────── 2. Trao đổi thuật toán & KEX (ECDH) ────────┤
   │                (Sinh Shared Session Key bí mật)            │
   │◄────────────── 3. Server gửi Public Host Key ──────────────┤
   │                (Client xác minh Fingerprint)               │
   │                                                            │
   │════════════════ KÊNH MÃ HÓA ĐỐI XỨNG THIẾT LẬP ════════════│
   │                                                            │
   ├─────────────── 4. Gửi yêu cầu xác thực người dùng ────────►│
   │◄────────────── 5. Đăng nhập thành công, cấp quyền PTY ─────┤
```

---

<a name="2-module-2-nghiên-cứu-giao-thức-cấp-phát-ip-động-dhcp--tiến-trình-dora-tv2"></a>
## 2. Module 2: Nghiên cứu Giao thức Cấp phát IP Động DHCP & Tiến trình DORA (TV2: Nguyễn Phúc Vượng)

### 2.1. Khái niệm và Vai trò của DHCP (Dynamic Host Configuration Protocol)
* DHCP (chuẩn RFC 2131) hoạt động ở tầng Ứng dụng (Application Layer), sử dụng giao thức truyền vận UDP trên hai cổng:
  * **Port 67 (UDP):** Dành cho DHCP Server lắng nghe yêu cầu.
  * **Port 68 (UDP):** Dành cho DHCP Client tiếp nhận phản hồi.
* **Lợi ích trong doanh nghiệp:** Giúp tự động hóa hoàn toàn cấu hình IP, Subnet Mask, Default Gateway, DNS Server cho hàng trăm Client; loại bỏ nguy cơ trùng lặp địa chỉ IP (IP conflict) do con người cấu hình thủ công.

### 2.2. Phân tích chi tiết Tiến trình 4 bước DORA

```text
[DHCP CLIENT]                                              [DHCP SERVER]
  (Port 68)                                                  (Port 67)
      │                                                          │
      ├─────── 1. DHCP DISCOVER (Broadcast: 255.255.255.255) ────►│
      │        "Tôi cần một địa chỉ IP, có ai ở đây không?"      │
      │                                                          │
      │◄────── 2. DHCP OFFER (Unicast / Broadcast) ──────────────┤
      │        "Tôi có IP 192.168.10.101, bạn có muốn lấy?"      │
      │                                                          │
      ├─────── 3. DHCP REQUEST (Broadcast: 255.255.255.255) ─────►│
      │        "Tôi đồng ý thuê IP 192.168.10.101 từ Server này" │
      │                                                          │
      │◄────── 4. DHCP ACK (Unicast / Broadcast) ────────────────┤
      │        "Xác nhận! Bạn được thuê IP trong 600 giây"       │
```

1. **Bước 1: DHCP DISCOVER**
   * Client mới khởi động chưa có IP (IP nguồn: `0.0.0.0`).
   * Gửi gói tin quảng bá (Broadcast) tới địa chỉ đích `255.255.255.255` trên toàn phân đoạn mạng LAN để dò tìm máy chủ DHCP.
   * Gói tin chứa địa chỉ MAC vật lý của Client.

2. **Bước 2: DHCP OFFER**
   * Server nhận được DISCOVER, kiểm tra dải IP cấp phát (`range 192.168.10.100 192.168.10.150`).
   * Chọn một IP còn trống (ví dụ `192.168.10.101`), tạm khóa IP này lại và gửi gói OFFER chứa: IP đề xuất, Subnet Mask, thời gian thuê (Lease time), Default Gateway, IP của DNS Server.

3. **Bước 3: DHCP REQUEST**
   * Client có thể nhận được OFFER từ nhiều DHCP Server khác nhau (nếu mạng có redundancy). Client sẽ chọn gói OFFER đầu tiên nhận được.
   * Client phát quảng bá gói REQUEST thông báo cho toàn mạng biết: nó đã đồng ý chọn IP của Server nào, đồng thời ngầm báo cho các DHCP Server khác giải phóng IP mà họ đã đề xuất.

4. **Bước 4: DHCP ACKNOWLEDGE (ACK)**
   * DHCP Server được chọn ghi nhận thông tin thuê (MAC, IP, Lease Start/End) vào cơ sở dữ liệu (`/var/lib/dhcp/dhcpd.leases`).
   * Server gửi gói tin ACK xác nhận giao dịch thành công. Client nhận ACK và chính thức kích hoạt địa chỉ IP trên card mạng.

### 2.3. Cơ chế Lease Time và Gia hạn địa chỉ (T1, T2)
* **T1 (Renewal Time - 50% Lease time):** Khi hết một nửa thời gian thuê, Client tự động gửi gói `DHCPREQUEST` (Unicast) trực tiếp tới Server để xin gia hạn.
* **T2 (Rebinding Time - 87.5% Lease time):** Nếu Server ban đầu không phản hồi, Client phát quảng bá `DHCPREQUEST` ra toàn mạng để tìm bất kỳ DHCP Server nào khác gia hạn giúp.
* Nếu hết 100% thời gian mà không được gia hạn, Client buộc phải hủy bỏ IP và quay lại bước DISCOVER từ đầu.

---

<a name="3-module-3-nghiên-cứu-hệ-thống-phân-giải-tên-miền-dns-bind9--web-server-nginx-tv3"></a>
## 3. Module 3: Nghiên cứu Hệ thống Phân giải Tên miền DNS BIND9 & Web Server Nginx (TV3: Nguyễn Minh Trí)

### 3.1. Nghiên cứu Dịch vụ Phân giải Tên miền (DNS BIND9 - Port 53)
* **Khái niệm:** DNS (Domain Name System - chuẩn RFC 1034/1035) hoạt động trên cổng 53 (UDP cho truy vấn chuẩn, TCP khi zone transfer hoặc gói phản hồi vượt quá 512 bytes). DNS đóng vai trò "danh bạ của mạng máy tính", chuyển đổi tên miền thân thiện (`web.lab.local`) thành địa chỉ IP số học (`192.168.10.10`) mà máy tính có thể định tuyến được.
* **Cấu trúc Không gian Tên miền Cây (Domain Tree Hierarchy):**
  * Root Domain (`.`) $\rightarrow$ Top-Level Domain (`.com`, `.net`, hoặc nội bộ `.local`) $\rightarrow$ Second-Level Domain (`lab.local`) $\rightarrow$ Subdomain / Hostname (`web.lab.local`).
* **Các loại Bản ghi Tài nguyên cốt lõi (Resource Records - RR):**
  * **SOA (Start of Authority):** Khai báo thông tin quản trị zone (Primary Name Server, Email quản trị, Serial number để đồng bộ, thời gian làm mới Refresh/Retry/Expire).
  * **NS (Name Server):** Chỉ định máy chủ có thẩm quyền quản lý zone (`ns.lab.local`).
  * **A (Address):** Ánh xạ từ Tên miền (FQDN) sang địa chỉ IPv4 (`web.lab.local` $\rightarrow$ `192.168.10.10`).
  * **PTR (Pointer):** Dùng trong Reverse Zone, ánh xạ ngược từ IP sang Tên miền (`10.10.168.192.in-addr.arpa` $\rightarrow$ `ns.lab.local`). Dùng để xác thực tính tin cậy của máy chủ.
* **Forwarding & Caching Mechanism:** Khi Client truy vấn một tên miền Internet lạ (ví dụ `google.com`), BIND9 sử dụng chỉ thị `forwarders { 8.8.8.8; };` để chuyển tiếp truy vấn ra máy chủ công cộng, sau đó lưu kết quả vào bộ nhớ đệm (Cache) theo thời gian sống (TTL).

### 3.2. Nghiên cứu Máy chủ Web Nginx (Port 80/TCP)
* **Kiến trúc hướng sự kiện bất đồng bộ (Event-Driven Asynchronous Architecture):**
  * Khác với mô hình hướng tiến trình/tiểu trình truyền thống của Apache (mỗi kết nối client tốn 1 thread/process gây lãng phí RAM), Nginx sử dụng mô hình **Master - Worker** kết hợp cơ chế `epoll` của nhân Linux.
  * Một worker process đơn lẻ có thể phục vụ đồng thời hàng chục ngàn kết nối đồng thời với mức chiếm dụng tài nguyên CPU/RAM cực kỳ thấp.
* **Cơ chế Máy chủ Ảo (Server Block / Virtual Host):**
  * Nginx sử dụng trường header `Host` trong giao thức HTTP/1.1 để phân biệt website mà Client muốn truy cập khi nhiều tên miền cùng chạy trên một địa chỉ IP duy nhất.
  * Khi nhận request có header `Host: web.lab.local`, Nginx định tuyến chính xác vào thư mục Document Root (`/var/www/lab.local/html/`) để trả về file `index.html`.

```text
[CLIENT HTTP REQUEST]
GET / HTTP/1.1
Host: web.lab.local ────────┐
                             ▼
              [NGINX WEB SERVER (192.168.10.10:80)]
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
   Server Block A                    Server Block B
   server_name: default              server_name: web.lab.local
   (Trang mặc định Nginx)            Root: /var/www/lab.local/html
                                     (Trả về: index.html nhóm)
```

---

<a name="4-module-4-nghiên-cứu-cơ-chế-lọc-gói-tường-lửa-ufw--mô-hình-an-ninh-tv4"></a>
## 4. Module 4: Nghiên cứu Cơ chế Lọc Gói Tường lửa UFW & Mô hình An ninh (TV4: Nguyễn Thành Đạt)

### 4.1. Bản chất của Tường lửa Linux: Netfilter & UFW
* **Netfilter Framework:** Hệ thống framework xử lý gói tin nằm sâu trong nhân Linux (Linux Kernel Space), có khả năng phân tích, định tuyến và can thiệp vào các gói tin đi vào (INPUT), đi ra (OUTPUT) hoặc chuyển tiếp qua máy (FORWARD).
* **iptables / nftables:** Công cụ dòng lệnh ở User Space để thao tác với các bảng quy tắc của Netfilter.
* **UFW (Uncomplicated Firewall):** Là lớp bọc giao diện người dùng thân thiện (frontend interface) được Canonical phát triển cho Ubuntu. UFW đơn giản hóa các câu lệnh iptables phức tạp, giúp quản trị viên cấu hình luật bảo vệ một cách trực quan, tránh sai sót cú pháp dẫn đến mất quyền quản trị từ xa.

### 4.2. Nguyên lý An ninh "Đặc quyền Tối thiểu" (Least Privilege / Whitelisting)
* Trong mô hình bảo mật chuẩn doanh nghiệp, chính sách tường lửa luôn được thiết lập theo quy tắc: **"Chặn toàn bộ theo mặc định (Default Deny), chỉ mở những gì thực sự cần thiết (Explicit Allow)"**.
* **Phân tích luồng lọc gói trên máy chủ của đề tài:**

```text
                                GÓI TIN ĐẾN MÁY CHỦ (INBOUND TRAFFIC)
                                                  │
                                                  ▼
                                      [UFW DEFAULT FILTERING]
                                                  │
               ┌──────────────────┬───────────────┴───────────────┬──────────────────┐
               ▼                  ▼                               ▼                  ▼
          Port 22/tcp        Port 53/any                     Port 67/udp        Port 80/tcp
         (Quản trị SSH)      (Truy vấn DNS)                 (Xin cấp IP DHCP)   (Truy cập Web)
               │                  │                               │                  │
               ▼                  ▼                               ▼                  ▼
            [ALLOW]            [ALLOW]                         [ALLOW]            [ALLOW]
               │                  │                               │                  │
               └──────────────────┴───────────────┬───────────────┴──────────────────┘
                                                  ▼
                                      ĐƯỢC ĐƯA VÀO DỊCH VỤ XỬ LÝ
                                                  
                     TẤT CẢ CÁC CỔNG CÒN LẠI (Telnet 23, FTP 21, SMB 445, MySQL 3306...)
                                                  │
                                                  ▼
                                          [DEFAULT DENY / DROP]
                                        (Gói tin bị hủy âm thầm)
```

* **Chống tấn công quét cổng (Port Scanning Prevention):** Khi hacker hoặc kẻ tấn công sử dụng công cụ quét cổng (nmap) vào Server, tất cả các cổng ngoài 22, 53, 67, 80 đều ở trạng thái `filtered/closed`, ngăn chặn kẻ tấn công dò tìm các lỗ hổng phần mềm chưa được vá.

---

## 5. Tổng hợp Luồng Tích hợp Dịch vụ End-to-End (Data Flow Matrix)

Toàn bộ 4 module trên không hoạt động riêng lẻ mà kết hợp thành một chuỗi vận hành khép kín khi một Client kết nối vào mạng doanh nghiệp:

```text
[BƯỚC 1: DHCP] ──► Client cắm mạng ──► Gửi Broadcast DORA ──► Nhận IP 192.168.10.101 & DNS 192.168.10.10
       │
[BƯỚC 2: DNS]  ──► Người dùng mở trình duyệt gõ: http://web.lab.local
                     └──► Client gửi truy vấn UDP 53 tới 192.168.10.10 ──► Server trả về IP 192.168.10.10
       │
[BƯỚC 3: UFW]  ──► Gói tin HTTP (Port 80 TCP) từ Client chạm vào card mạng Server
                     └──► Tường lửa UFW kiểm tra bảng luật ──► Thấy Port 80 ALLOW ──► Cho phép đi tiếp
       │
[BƯỚC 4: NGINX]──► Nginx nhận HTTP Request chứa Header `Host: web.lab.local`
                     └──► Trả về nội dung trang HTML giới thiệu nhóm nghiên cứu
       │
[BƯỚC 5: SSH]  ──► Quản trị viên từ xa kết nối Port 22/tcp để giám sát log hoạt động và bảo trì hệ thống
```

---
> **Tài liệu tham khảo học thuật:**
> 1. RFC 2131 - Dynamic Host Configuration Protocol.
> 2. RFC 1034 & RFC 1035 - Domain Names - Concepts and Facilities / Implementation and Specification.
> 3. RFC 4253 - The Secure Shell (SSH) Transport Layer Protocol.
> 4. Canonical Ltd. - Ubuntu Server 24.04 LTS Official Documentation (Netplan & UFW Manuals).
