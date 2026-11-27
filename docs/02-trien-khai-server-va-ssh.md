# GIAI ĐOẠN 2: CÀI ĐẶT UBUNTU SERVER, NETPLAN IP TĨNH & BẢO MẬT OPENSSH

> **Giai đoạn:** Giai đoạn 2 (Ngày 3–4)  
> **Người phụ trách:** Nguyễn Anh Xuân (TV1 - Leader)  
> **Test Cases nghiệm thu:** **TC-01** (IP tĩnh), **TC-02** (Trạng thái SSH), **TC-03** (Đăng nhập SSH từ Client)  
> **File cấu hình liên quan:** `configs/network/01-netplan.yaml`, `configs/ssh/01-lab-security.conf`, `scripts/setup_network.sh`

---

## Bước 1: Thiết lập hạ tầng mạng ảo trên VMware Fusion (macOS)

1. **Ubuntu Server (dùng 2 card mạng):**
   * **Card 1 (`enp2s0` — Share with my Mac / NAT):** Giữ nguyên chế độ NAT để máy chủ có Internet cài đặt gói `apt`.
   * **Card 2 (`enp10s0` — Mạng nội bộ):** Gắn vào mạng nội bộ cách ly (ban đầu dùng *Private to my Mac*, ở Giai đoạn 3 chuyển sang Custom **`vmnet2`** đã tắt DHCP của VMware).
2. **Ubuntu Client (chỉ dùng 1 card mạng duy nhất):**
   * **Card 1 (`enp2s0` — Mạng nội bộ):** Tuyệt đối **không gắn thêm card NAT** cho Client để tránh nhận 2 Default Gateway/DNS làm sai lệch kết quả test DHCP và DNS.
3. **Kiểm tra tên card và địa chỉ MAC trên Server:**
   ```bash
   ip -br link
   ip -4 a
   ping -c 2 8.8.8.8
   ```

---

## Bước 2: Cấu hình IP tĩnh `192.168.10.10/24` bằng Netplan (TC-01)

1. **Sao lưu các file Netplan gốc để tránh xung đột:**
   ```bash
   sudo mkdir -p /etc/netplan/backup
   sudo mv /etc/netplan/*.yaml /etc/netplan/backup/
   ```

2. **Tạo file `/etc/netplan/01-netcfg.yaml`** (tham chiếu `configs/network/01-netplan.yaml`):
   ```bash
   sudo tee /etc/netplan/01-netcfg.yaml << 'EOF'
   network:
     version: 2
     ethernets:
       enp2s0:
         dhcp4: true
       enp10s0:
         dhcp4: false
         addresses:
           - 192.168.10.10/24
   EOF
   ```
   > **Lưu ý kỹ thuật quan trọng:** Không khai báo `routes: default` trên card nội bộ `enp10s0` để tránh đụng tuyến đường Internet mặc định với card NAT `enp2s0`.

3. **Phân quyền bảo mật và áp dụng cấu hình:**
   ```bash
   sudo chmod 600 /etc/netplan/01-netcfg.yaml
   sudo netplan apply
   ip -br addr
   ip -4 a show enp10s0
   ```
   * **Kết quả đạt (TC-01):** `enp10s0` hiển thị `inet 192.168.10.10/24` với `valid_lft forever preferred_lft forever`.

---

## Bước 3: Kích hoạt và Bảo mật (Hardening) OpenSSH Server (TC-02)

1. **Kiểm tra dịch vụ SSH (cài mới nếu chưa có):**
   ```bash
   sudo systemctl status ssh
   # Nếu chưa có: sudo apt update && sudo apt install -y openssh-server
   ```

2. **Tạo file cấu hình bảo mật drop-in `/etc/ssh/sshd_config.d/01-lab-security.conf`:**
   *(Sử dụng thư mục `sshd_config.d/` chuẩn của Ubuntu giúp ghi đè tham số an toàn mà không cần chỉnh sửa file gốc dài dòng).*
   ```bash
   sudo tee /etc/ssh/sshd_config.d/01-lab-security.conf << 'EOF'
   Port 22
   PermitRootLogin no
   MaxAuthTries 5
   PasswordAuthentication yes
   EOF
   ```
   * **Ý nghĩa từng tham số bảo mật:**
     * `Port 22`: Khớp với Port Matrix và luật tường lửa UFW.
     * `PermitRootLogin no`: Cấm đăng nhập trực tiếp bằng `root` từ xa (chống brute-force vào tài khoản mặc định, buộc dùng user thường rồi mới `sudo`).
     * `MaxAuthTries 5`: Tự ngắt kết nối nếu nhập sai mật khẩu quá 5 lần.
     * `PasswordAuthentication yes`: Cho phép xác thực mật khẩu phục vụ thao tác demo trực tiếp.

3. **Kiểm tra cú pháp và khởi động dịch vụ:**
   ```bash
   sudo sshd -t && sudo systemctl enable --now ssh && sudo systemctl restart ssh
   sudo sshd -T | grep -E "^(port|permitrootlogin|maxauthtries|passwordauthentication) "
   sudo systemctl status ssh
   ```
   * **Kết quả đạt (TC-02):** `ssh.service` ở trạng thái `active (running)` và lắng nghe tại `0.0.0.0:22`.

---

## Bước 4: Kiểm thử kết nối SSH từ Ubuntu Client sang Server (TC-03)

*(Thực hiện trước Giai đoạn 3 khi chưa có DHCP Server — đặt IP tạm cùng lớp mạng cho Client bằng lệnh `ip`):*

1. **Trên Ubuntu Client:**
   ```bash
   sudo ip addr flush dev enp2s0
   sudo ip addr add 192.168.10.20/24 dev enp2s0
   ip -4 a show enp2s0
   ```
2. **Ping kiểm tra thông mạng và SSH vào Server:**
   ```bash
   ping -c 3 192.168.10.10
   ssh anhxuan-devops@192.168.10.10
   ```
   * **Kết quả đạt (TC-03):** `ping` mất **0% packet loss**, đăng nhập thành công vào dấu nhắc lệnh `anhxuan-devops@ubuntu-server:~$`.
   * **Mẹo quản trị từ máy Host (macOS):** Từ Terminal máy Mac có thể SSH vào Server qua IP card NAT `enp2s0` (vd: `ssh anhxuan-devops@192.168.79.130`) để copy-paste lệnh nhanh, còn nghiệm thu TC-03 luôn thực hiện từ Client sang `192.168.10.10`.

---

## Minh chứng nghiệm thu đã lưu
* **TC-01 & TC-02:** `evidence/server/tc01-tc02-server-ip-ssh-status.jpg`
* **TC-03:** `evidence/ssh/tc03-client-ssh-login.jpg`
