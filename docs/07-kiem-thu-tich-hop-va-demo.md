# GIAI ĐOẠN 7: NGHIỆM THU 11 TEST CASES & KỊCH BẢN DEMO TRỰC TIẾP (10 PHÚT)

> **Giai đoạn:** Giai đoạn 7 (Ngày 14 — Kiểm thử tổng thể, Báo cáo & Bảo vệ)  
> **Người phụ trách:** Nguyễn Anh Xuân (TV1 - Leader) chủ trì Demo & Báo cáo; TV4 (Đạt) hoàn thiện Slide; cả 4 thành viên sẵn sàng phản biện.  
> **Script kiểm thử tổng hợp:** `./scripts/run_all_tests.sh`

---

## 1. Ma trận 11 Kịch bản Kiểm thử Nghiệm thu (Đạt 11/11 Pass)

| Test ID | Tên bài kiểm thử | Thao tác kiểm tra | Kết quả thực tế đã nghiệm thu | Phụ trách | Trạng thái | Minh chứng |
|:---:|---|---|---|:---:|:---:|---|
| **TC-01** | IP tĩnh Server | `ip -4 a show enp10s0` | `192.168.10.10/24` (`valid_lft forever`) | TV1 | [x] Pass | `evidence/server/tc01-tc02-server-ip-ssh-status.jpg` |
| **TC-02** | Dịch vụ OpenSSH | `sudo systemctl status ssh` | `active (running)`, lắng nghe `0.0.0.0:22`, `PermitRootLogin no` | TV1 | [x] Pass | `evidence/server/tc01-tc02-server-ip-ssh-status.jpg` |
| **TC-03** | Đăng nhập SSH từ xa | Client: `ssh anhxuan-devops@192.168.10.10` | Ping 0% loss, đăng nhập Terminal Server thành công | TV1 | [x] Pass | `evidence/ssh/tc03-client-ssh-login.jpg` |
| **TC-04** | Client xin IP động | Client: `nmcli dev disconnect/connect enp2s0` | Nhận IP `192.168.10.100/24` (`valid_lft 600s`) trên `vmnet2` | TV2 | [x] Pass | `evidence/dhcp/tc04-client-dhcp-ip.jpg` |
| **TC-05** | Bảng cấp phát DHCP | Server: `cat /var/lib/dhcp/dhcpd.leases` | Ghi nhận `192.168.10.100`, MAC `00:0c:29:3a:fb:01`, `ubuntu-client` | TV2 | [x] Pass | `evidence/dhcp/tc05-server-dhcp-leases.jpg` |
| **TC-06** | Phân giải thuận DNS | Client: `dig web.lab.local +short` | Trả về `192.168.10.10` tự động qua DNS của DHCP | TV3 | [x] Pass | `evidence/dns/tc06-tc07-dns-resolution.jpg` |
| **TC-07** | Phân giải nghịch DNS | Client: `dig @192.168.10.10 -x 192.168.10.10 +short` | Trả về `ns.lab.local.`, `web.lab.local.`, `server.lab.local.` | TV3 | [x] Pass | `evidence/dns/tc06-tc07-dns-resolution.jpg` |
| **TC-08** | Truy cập Web qua IP | Client: `wget -S --spider http://192.168.10.10` | Trả về `HTTP/1.1 200 OK` (Nginx `default_server`) | TV3 | [x] Pass | `evidence/web/tc08-tc09-nginx-wget.jpg` |
| **TC-09** | Truy cập Web qua Domain | Firefox / `wget`: `http://web.lab.local` | Load thành công giao diện giới thiệu nhóm (`200 OK`) | TV3 | [x] Pass | `evidence/web/tc09-firefox-web-lab-local.jpg` |
| **TC-10** | Tường lửa UFW | Server: `sudo ufw status verbose`; Client: `nc -zv -w 2 192.168.10.10 22 80 23 8080` | Mở đúng `22, 53, 67, 80`; chặn đứng cổng `23, 8080` (`timed out`) | TV4 | [x] Pass | `evidence/firewall/tc10-real-ufw-status.jpg`, `tc10-real-nc-port-block.jpg` |
| **TC-11** | Giám sát Prometheus & Grafana | Firefox Client: `http://monitor.lab.local` | Dashboard `1860` hiển thị CPU, RAM, Disk, Network thời gian thực của `ubuntu-server` qua Nginx Reverse Proxy Port 80 | TV1 | [x] Pass | `evidence/monitoring/tc11-grafana-node-exporter-dashboard.jpg` |

---

## 2. Checklist chuẩn bị 5 phút trước giờ bảo vệ

1. Bật sẵn 2 máy ảo từ Snapshot ổn định: **Ubuntu Server** (`vmnet2`) và **Ubuntu Client** (`vmnet2`).
2. Trên Ubuntu Server chạy nhanh:
   ```bash
   cd ~/linux-network-services && ./scripts/run_all_tests.sh
   ```
   Đảm bảo đủ **7/7 `[ PASS ]`** (`ssh`, `isc-dhcp-server`, `bind9`, `nginx`, `prometheus`, `prometheus-node-exporter`, `grafana-server`).
3. Mở sẵn Firefox trên Ubuntu Client với 2 tab chuẩn bị sẵn: `http://web.lab.local` và `http://monitor.lab.local`.

---

## 3. Kịch bản Demo 5 Bước (10 phút — TV1 trực tiếp thao tác)

1. **Bước 1 — Hạ tầng & Quản trị SSH (2 phút):**
   * Trên Client: gõ `ssh anhxuan-devops@192.168.10.10` đăng nhập vào Server.
   * Trên Server: chạy `ip -4 a show enp10s0` chứng minh IP tĩnh `192.168.10.10/24` và `sudo sshd -T | grep permitrootlogin` chứng minh đã khóa đăng nhập `root`.
2. **Bước 2 — Cấp phát IP động DHCP (1.5 phút — TV2 thuyết minh cơ chế DORA):**
   * Trên Client: chạy `nmcli dev disconnect enp2s0 && nmcli dev connect enp2s0 && ip -4 a show enp2s0` cho thấy Client tự xin lại IP `192.168.10.100/24`.
   * Trên Server: chạy `./scripts/check_dhcp_leases.sh` hoặc `cat /var/lib/dhcp/dhcpd.leases`.
3. **Bước 3 — Phân giải DNS & Web Nginx (2 phút — TV3 thuyết minh):**
   * Trên Client: chạy `dig web.lab.local +short`, `dig monitor.lab.local +short`, và `dig -x 192.168.10.10 +short`.
   * Mở Firefox tải trang **`http://web.lab.local`** giới thiệu đề tài và 4 thành viên.
4. **Bước 4 — Tường lửa UFW & Giám sát Prometheus/Grafana (2.5 phút — TV4 & TV1 thuyết minh):**
   * Trên Server: chạy `sudo ufw status verbose`; trên Client chạy `nc -zv -w 2 192.168.10.10 22 80 23 8080` chứng minh chỉ mở 4 cổng vàng và chặn cổng lạ.
   * Chuyển sang tab **`http://monitor.lab.local`** trình diễn Dashboard **Node Exporter Full** giám sát CPU, RAM, Disk, Network của Server theo thời gian thực qua Nginx Reverse Proxy (không cần mở cổng 3000/9090/9100 trên UFW).
5. **Bước 5 — Tổng kết & Hỏi đáp phản biện (2 phút):**
   * TV1 tổng kết giá trị thực tiễn, sau đó điều phối TV2 (DHCP), TV3 (DNS/Nginx), TV4 (UFW) và TV1 (Kiến trúc/SSH/Monitoring) trả lời chuyên sâu câu hỏi của Hội đồng.
