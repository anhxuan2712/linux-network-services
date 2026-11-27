# GIAI ĐOẠN 7: CẨM NANG HƯỚNG DẪN DEMO TỪ A–Z & NGHIỆM THU 11 TEST CASES

> **Giai đoạn:** Giai đoạn 7 (Ngày 14 — Tổng duyệt & Bảo vệ trước Hội đồng)  
> **Người trực tiếp thao tác Demo:** Nguyễn Anh Xuân (TV1 - Leader)  
> **Hỗ trợ thuyết minh & phản biện:** TV2 (DHCP), TV3 (DNS & Nginx), TV4 (UFW & Slide)  
> **Thời lượng tiêu chuẩn:** 10 phút thực hành trực tiếp (05 bước liền mạch)

---

## PHẦN A: CHUẨN BỊ TỪ A ĐẾN Z TRƯỚC KHI LÊN BỤC (KHÔNG ĐỂ XẢY RA LỖI!)

### 1. Chuẩn bị từ tối hôm trước
* **Chụp Snapshot bản hoàn chỉnh:** Trong VMware Fusion, chọn `Ubuntu Server` $\rightarrow$ **Virtual Machine $\rightarrow$ Snapshots $\rightarrow$ Take Snapshot** đặt tên `demo-ready-11-test-cases` (làm tương tự với `Ubuntu Client`).
* **Đồng bộ code mới nhất trên Server:** Mở Terminal trên Ubuntu Server chạy:
  ```bash
  cd ~/linux-network-services && git pull && chmod +x scripts/*.sh
  ```
* **Tắt chế độ tự khóa màn hình / sleep** trên máy Mac và máy ảo Ubuntu Client để lúc đang nói không bị tối màn hình.

### 2. Chuẩn bị 5 phút trước khi gọi tên lên báo cáo
1. **Khởi động sẵn 2 máy ảo** (`Ubuntu Server` & `Ubuntu Client`), kiểm tra cả 2 đang cắm đúng mạng **`vmnet2`** (tuyệt đối không phụ thuộc Wi-Fi phòng học!).
2. **Chạy 1 lệnh tổng kiểm tra sức khỏe toàn hệ thống trên Ubuntu Server:**
   ```bash
   cd ~/linux-network-services && ./scripts/run_all_tests.sh
   ```
   Đảm bảo hiện đủ **7/7 `[ PASS ]`**: `ssh`, `isc-dhcp-server`, `bind9`, `nginx`, `prometheus`, `prometheus-node-exporter`, `grafana-server`.
3. **Bố trí sẵn màn hình trên Ubuntu Client cho gọn đẹp khi chiếu lên bảng:**
   * **Cửa sổ 1 (Terminal Client):** Đã phóng to cỡ chữ (`Ctrl + Shift + +`) để giảng viên ngồi xa vẫn đọc rõ.
   * **Cửa sổ 2 (Trình duyệt Firefox):** Mở sẵn 2 tab trống (hoặc đã đăng nhập sẵn Grafana để khỏi mất công nhập `admin/admin` lúc đứng trước thầy cô):
     * Tab 1: `http://web.lab.local`
     * Tab 2: `http://monitor.lab.local` (chỉnh sẵn thời gian **`Last 5 minutes`** và tự làm mới **`5s`** ở góc trên phải!).

---

## PHẦN B: KỊCH BẢN DEMO TỪ A–Z (5 BƯỚC — 10 PHÚT CẦM TAY CHỈ VIỆC)

### BƯỚC 1: HẠ TẦNG IP TĨNH & QUẢN TRỊ TỪ XA OPENSSH (2 phút — TV1 thực hiện & trình bày)

* **Lời dẫn ngắn:** *"Dạ thưa thầy/cô, toàn bộ hệ thống nhóm em chạy khép kín trên 2 máy ảo nối qua mạng ảo cô lập `vmnet2` (`192.168.10.0/24`). Bước đầu tiên em xin chứng minh khả năng quản trị máy chủ từ xa bằng SSH và cấu hình IP tĩnh."*
* **Thao tác trên Terminal Ubuntu Client:**
  ```bash
  ssh anhxuan-devops@192.168.10.10
  ```
  *(Nhập mật khẩu $\rightarrow$ dấu nhắc đổi sang `anhxuan-devops@ubuntu-server:~$` — **chứng minh TC-03**).*
* **Thao tác ngay trong phiên SSH đó (đang đứng bên trong Ubuntu Server):**
  ```bash
  ip -4 a show enp10s0
  sudo sshd -T | grep -E "^(port|permitrootlogin|maxauthtries) "
  ```
* **Chỉ tay lên màn hình cho Giảng viên thấy:**
  1. Dòng `inet 192.168.10.10/24` và `valid_lft forever` $\rightarrow$ **IP tĩnh Netplan (TC-01)**.
  2. Dòng `permitrootlogin no` và `maxauthtries 5` $\rightarrow$ **SSH đã bật bảo mật Hardening (TC-02)**, chống dò mật khẩu và cấm đăng nhập thẳng `root`.
* *(Gõ `exit` để thoát về lại màn hình Ubuntu Client).*

---

### BƯỚC 2: CẤP PHÁT IP TỰ ĐỘNG DHCP SERVER (1.5 phút — TV1 thao tác, TV2 thuyết minh DORA)

* **Lời dẫn ngắn:** *"Tiếp theo em xin demo dịch vụ DHCP Server cấp IP tự động cho Client thông qua tiến trình 4 bước DORA (TV2 - bạn Vượng sẽ thuyết minh nguyên lý)."*
* **Thao tác trên Terminal Ubuntu Client:**
  ```bash
  nmcli dev disconnect enp2s0 && nmcli dev connect enp2s0
  ip -4 a show enp2s0
  ```
  * **Chỉ tay:** Client vừa ngắt mạng và xin lại thành công IP động **`192.168.10.100/24`** (nằm đúng dải `100–150`) kèm `valid_lft ~600sec` (**TC-04**).
* **Thao tác trên cửa sổ Terminal Ubuntu Server (hoặc qua SSH):**
  ```bash
  ~/linux-network-services/scripts/check_dhcp_leases.sh
  # Hoặc: tail -n 15 /var/lib/dhcp/dhcpd.leases
  ```
  * **Chỉ tay:** Bảng lease trên Server ghi nhận đúng `192.168.10.100`, địa chỉ MAC của Client và tên máy `ubuntu-client` (**TC-05**).

---

### BƯỚC 3: PHÂN GIẢI TÊN MIỀN DNS BIND9 & WEB SERVER NGINX (2 phút — TV1 thao tác, TV3 thuyết minh)

* **Lời dẫn ngắn:** *"Sau khi Client nhận IP và địa chỉ DNS `192.168.10.10` tự động từ DHCP, em xin kiểm tra phân giải tên miền nội bộ BIND9 và truy cập Website Nginx (TV3 - bạn Trí thuyết minh)."*
* **Thao tác trên Terminal Ubuntu Client:**
  ```bash
  dig web.lab.local +short
  dig monitor.lab.local +short
  dig -x 192.168.10.10 +short
  ```
  * **Chỉ tay:** Không cần chỉ định `@192.168.10.10`, Client tự động hỏi DNS Server nội bộ và phân giải thuận ra `192.168.10.10` (**TC-06**), phân giải nghịch ra `ns.lab.local.`, `web.lab.local.`, `server.lab.local.` (**TC-07**).
* **Chuyển sang Firefox trên Ubuntu Client (Tab 1):**
  * Gõ **`http://192.168.10.10`** (**TC-08**) và **`http://web.lab.local`** (**TC-09**) $\rightarrow$ bấm `F5` tải lại để thấy trang web doanh nghiệp giới thiệu đề tài và 4 thành viên hiện lên mượt mà.

---

### BƯỚC 4: TƯỜNG LỬA UFW & GIÁM SÁT TÀI NGUYÊN PROMETHEUS/GRAFANA (2.5 phút — TV4 & TV1 thuyết minh)

#### 4.1. Chứng minh Tường lửa UFW (TV4 - bạn Đạt thuyết minh Least Privilege)
* **Trên Terminal Ubuntu Server:**
  ```bash
  sudo ufw status verbose
  ```
  * **Chỉ tay:** `Status: active`, `Default: deny (incoming)` và **chỉ mở đúng 4 cổng `22/tcp`, `53`, `67/udp`, `80/tcp`**.
* **Trên Terminal Ubuntu Client (chứng minh chặn cổng lạ trực tiếp):**
  ```bash
  nc -zv -w 2 192.168.10.10 22 80 23 8080
  ```
  * **Chỉ tay:** Cổng `22` và `80` báo **`succeeded!`**, còn cổng `23` và `8080` báo **`timed out`** (bị tường lửa drop âm thầm — **TC-10**).

#### 4.2. Chứng minh Giám sát Tài nguyên Real-time (TV1 trình bày phần mở rộng)
* **Chuyển sang Firefox trên Ubuntu Client (Tab 2):** Tải **`http://monitor.lab.local`** (**TC-11**).
* **Nhấn mạnh điểm ăn tiền về kiến trúc:** *"Như thầy/cô thấy trên UFW vừa rồi, nhóm em **không hề mở cổng `3000`, `9090` hay `9100`** ra ngoài. Toàn bộ Grafana/Prometheus/Node Exporter chạy ẩn trên `localhost` và đi qua **Nginx Reverse Proxy** trên đúng Port 80 để đảm bảo an toàn tối đa."*
* **Chỉ tay giải thích nhanh 4 chỉ số cốt lõi trên Dashboard `1860`:**
  * **CPU Busy %**, **RAM Used %** (tách biệt với Cache), **RootFS Used %** (tránh đầy ổ cứng làm chết log), và **Network Traffic**.
* *(Tùy chọn gây ấn tượng mạnh — mất 15 giây):* Chạy lệnh giả lập tải trên Server:
  ```bash
  timeout 15 sh -c 'yes > /dev/null & yes > /dev/null & wait'
  ```
  Chỉ lên màn hình Grafana thấy biểu đồ **CPU Busy nhảy vọt theo thời gian thực** rồi tự giảm xuống!

---

### BƯỚC 5: TỔNG KẾT & HỎI ĐÁP PHẢN BIỆN (2 phút — TV1 chủ trì)

* **Chạy chốt 1 lệnh cuối trên Ubuntu Server:**
  ```bash
  ~/linux-network-services/scripts/run_all_tests.sh
  ```
  *(Hiện nguyên bảng **7/7 `[ PASS ]`** cực đẹp trên màn hình chiếu!).*
* **Lời kết:** *"Dạ trên đây là toàn bộ phần demo hệ thống 5 dịch vụ mạng cốt lõi kết hợp giám sát tài nguyên Prometheus & Grafana hoạt động hoàn toàn khép kín của nhóm em. Nhóm em rất mong nhận được câu hỏi và góp ý từ thầy/cô ạ!"*
* **Điều phối trả lời câu hỏi:**
  * Hỏi về IP tĩnh, Netplan, SSH, Prometheus/Grafana, Nginx Reverse Proxy, Kiến trúc tổng thể $\rightarrow$ **TV1 (Xuân)** trả lời.
  * Hỏi về DHCP, tiến trình DORA, Lease time, xung đột DHCP ảo hóa $\rightarrow$ **TV2 (Vượng)** trả lời.
  * Hỏi về DNS BIND9, bản ghi SOA/NS/A/PTR, Virtual Host Nginx $\rightarrow$ **TV3 (Trí)** trả lời.
  * Hỏi về Netfilter/UFW, nguyên tắc Least Privilege, phòng chống quét cổng $\rightarrow$ **TV4 (Đạt)** trả lời.

---

## PHẦN C: BẢNG CỨU HỘ KHẨN CẤP (10 GIÂY XỬ LÝ NẾU CÓ SỰ CỐ LÚC ĐANG DEMO)

| Sự cố có thể gặp lúc bảo vệ | Nguyên nhân thường gặp | Lệnh xử lý nhanh trong 10 giây |
|---|---|---|
| Client mất IP hoặc hiện IP lạ (`172.16.x.x`) | Nhầm card mạng VMware về *Private to my Mac* | Đổi card sang `vmnet2` $\rightarrow$ trên Client chạy `nmcli dev disconnect enp2s0 && nmcli dev connect enp2s0` |
| `dig web.lab.local` không ra IP | `bind9` chưa kịp lên hoặc Client chưa nhận DNS `.10` | Trên Server: `sudo systemctl restart bind9`; kiểm tra `resolvectl status` trên Client |
| Mở `http://web.lab.local` lỗi hoặc hiện trang trắng | Firefox tự chuyển sang `https://` | Gõ rõ `http://web.lab.local` trên thanh địa chỉ hoặc mở cửa sổ Ẩn danh (`Ctrl + Shift + P`) |
| Mở `http://monitor.lab.local` báo `502 Bad Gateway` | `grafana-server` chưa khởi động xong | Trên Server: `sudo systemctl restart grafana-server nginx` (đợi 3 giây rồi F5) |
| Grafana hiện `No data` trên biểu đồ | `prometheus` hoặc `node-exporter` chưa chạy / sai khung giờ | Trên Server: `sudo systemctl restart prometheus prometheus-node-exporter`; trên web đổi sang `Last 15 minutes` |
| Lỗi nặng không rõ nguyên nhân | Thay đổi nhầm cấu hình trước giờ thi | **Restore Snapshot `demo-ready-11-test-cases`** (10 giây về trạng thái hoàn hảo!) |

---

## PHẦN D: MA TRẬN NGHIỆM THU 11/11 TEST CASES (ĐÃ HOÀN THÀNH)

| Test ID | Tên bài kiểm thử | Thao tác kiểm tra | Kết quả thực tế đã nghiệm thu | Phụ trách | Trạng thái | Minh chứng |
|:---:|---|---|---|:---:|:---:|---|
| **TC-01** | IP tĩnh Server | `ip -4 a show enp10s0` | `192.168.10.10/24` (`valid_lft forever`) | TV1 | [x] Pass | `evidence/server/tc01-tc02-server-ip-ssh-status.jpg` |
| **TC-02** | Dịch vụ OpenSSH | `sudo systemctl status ssh` | `active (running)`, Port 22, `PermitRootLogin no` | TV1 | [x] Pass | `evidence/server/tc01-tc02-server-ip-ssh-status.jpg` |
| **TC-03** | SSH từ xa | Client: `ssh anhxuan-devops@192.168.10.10` | Ping 0% loss, đăng nhập Terminal Server thành công | TV1 | [x] Pass | `evidence/ssh/tc03-client-ssh-login.jpg` |
| **TC-04** | Client nhận DHCP | `nmcli dev disconnect/connect enp2s0` | Nhận IP `192.168.10.100/24` (`valid_lft 600s`) trên `vmnet2` | TV2 | [x] Pass | `evidence/dhcp/tc04-client-dhcp-ip.jpg` |
| **TC-05** | Bảng cấp phát DHCP | `cat /var/lib/dhcp/dhcpd.leases` | Ghi nhận `192.168.10.100`, MAC Client, `ubuntu-client` | TV2 | [x] Pass | `evidence/dhcp/tc05-server-dhcp-leases.jpg` |
| **TC-06** | Phân giải thuận DNS | Client: `dig web.lab.local +short` | Trả về `192.168.10.10` tự động qua DNS của DHCP | TV3 | [x] Pass | `evidence/dns/tc06-tc07-dns-resolution.jpg` |
| **TC-07** | Phân giải nghịch DNS | Client: `dig -x 192.168.10.10 +short` | Trả về `ns.lab.local.`, `web.lab.local.`, `server.lab.local.` | TV3 | [x] Pass | `evidence/dns/tc06-tc07-dns-resolution.jpg` |
| **TC-08** | Truy cập Web qua IP | `wget -S --spider http://192.168.10.10` | Trả về `HTTP/1.1 200 OK` (Nginx `default_server`) | TV3 | [x] Pass | `evidence/web/tc08-tc09-nginx-wget.jpg` |
| **TC-09** | Truy cập Web qua Domain | Firefox / `wget`: `http://web.lab.local` | Load thành công giao diện giới thiệu nhóm (`200 OK`) | TV3 | [x] Pass | `evidence/web/tc09-firefox-web-lab-local.jpg` |
| **TC-10** | Tường lửa UFW | `ufw status verbose` & `nc -zv` | Mở đúng `22, 53, 67, 80`; chặn cổng `23, 8080` (`timed out`) | TV4 | [x] Pass | `evidence/firewall/tc10-real-ufw-status.jpg`, `tc10-real-nc-port-block.jpg` |
| **TC-11** | Giám sát Prometheus & Grafana | Firefox Client: `http://monitor.lab.local` | Dashboard `1860` hiển thị CPU, RAM, Disk, Network thời gian thực qua Nginx Port 80 | TV1 | [x] Pass | `evidence/monitoring/tc11-grafana-node-exporter-dashboard.jpg` |
