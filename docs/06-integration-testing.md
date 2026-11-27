# KẾ HOẠCH TÍCH HỢP HỆ THỐNG & KỊCH BẢN DEMO BẢO VỆ

> **Người phụ trách:** Nguyễn Anh Xuân (TV1 - Leader)  
> **Mục tiêu:** Kiểm thử liên thông toàn bộ 10 Test Cases và chuẩn bị quy trình Demo thực tế trước Giảng viên.

---

## 1. Ma trận 10 Kịch bản Kiểm thử Tích hợp

| Test ID | Tên bài test | Thao tác kiểm tra | Kết quả mong đợi | Phụ trách module | Trạng thái |
|:---:|---|---|---|:---:|:---:|
| **TC-01** | IP tĩnh Server | `ip a show dev <iface>` | Server có IP `192.168.10.10/24` | TV1 | [x] Pass |
| **TC-02** | Dịch vụ OpenSSH | `sudo systemctl status ssh` | Trạng thái `active (running)`, Port 22 | TV1 | [x] Pass |
| **TC-03** | SSH từ xa | Trên Client: `ssh anhxuan-devops@192.168.10.10` | Đăng nhập Terminal thành công | TV1 | [x] Pass |
| **TC-04** | Client nhận DHCP | Client xin cấp IP động | Client nhận IP `192.168.10.100 - 150` | TV2 | [x] Pass |
| **TC-05** | Bảng cấp phát DHCP | `cat /var/lib/dhcp/dhcpd.leases` | Ghi nhận MAC Client và IP cấp | TV2 | [x] Pass |
| **TC-06** | Phân giải thuận DNS | Client: `dig web.lab.local +short` | Trả về IP `192.168.10.10` | TV3 | [x] Pass |
| **TC-07** | Phân giải nghịch DNS | Client: `dig -x 192.168.10.10 +short` | Trả về `ns.lab.local.` | TV3 | [x] Pass |
| **TC-08** | Truy cập Web qua IP | Trình duyệt / `wget`: `http://192.168.10.10` | Hiển thị website nội bộ | TV3 | [x] Pass |
| **TC-09** | Truy cập Web qua Domain| Trình duyệt / `wget`: `http://web.lab.local` | Hiển thị website nội bộ | TV3 | [x] Pass |
| **TC-10** | Tường lửa UFW | `sudo ufw status verbose` | Chỉ mở 22, 53, 67, 80; chặn cổng lạ | TV4 | [x] Pass |

---

## 2. Kịch bản Demo 5 Bước (10 phút trước Giảng viên)

1. **Bước 1 (2 phút):** TV1 mở terminal Client, SSH vào Server `192.168.10.10`, show `ip a` chứng minh máy chủ IP tĩnh và quản trị từ xa an toàn.
2. **Bước 2 (2 phút):** TV1 ngắt/bật mạng Client, show `ip a` chứng minh Client nhận IP động từ DHCP (module TV2); show file lease trên Server.
3. **Bước 3 (2 phút):** TV1 trên Client gõ lệnh `dig web.lab.local` và `dig -x 192.168.10.10` chứng minh cơ chế phân giải DNS (module TV3).
4. **Bước 4 (2 phút):** TV1 mở trình duyệt vào `http://web.lab.local` kiểm tra Web Nginx (TV3), sau đó mở terminal Server show `sudo ufw status verbose` chứng minh bảo vệ tường lửa (TV4).
5. **Bước 5 (2 phút):** TV1 tổng kết giá trị triển khai của hệ thống và điều phối nhóm đón nhận câu hỏi phản biện từ thầy cô.
