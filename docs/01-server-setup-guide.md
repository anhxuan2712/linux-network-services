# HƯỚNG DẪN CÀI ĐẶT NỀN TẢNG UBUNTU SERVER 24.04 LTS & DỊCH VỤ OPENSSH

> **Người phụ trách:** Nguyễn Anh Xuân (TV1 - Leader)  
> **Mục tiêu:** Thiết lập mạng ảo VMware, cấu hình Netplan gán IP tĩnh `192.168.10.10/24` cho card nội bộ, kích hoạt và bảo mật OpenSSH.

---

## 1. Thiết lập Card mạng ảo trên VMware Fusion

* **Ubuntu Server (2 card mạng):**
  * **Card 1 (`enp2s0` — Share with my Mac / NAT):** Dùng để Server có Internet chạy `sudo apt update && sudo apt install`.
  * **Card 2 (`enp10s0` — Private to my Mac / Host-Only):** Dùng làm mạng nội bộ `192.168.10.0/24` giao tiếp với Client.
* **Ubuntu Client (chỉ 1 card mạng):**
  * **Card 1 (`enp2s0` — Private to my Mac / Host-Only):** Tuyệt đối không gắn thêm card NAT cho Client để tránh nhận 2 Default Gateway/DNS gây nhiễu khi test DHCP và DNS.

*(Kiểm tra tên card thực tế trên từng máy bằng lệnh `ip -4 a`).*

---

## 2. Cấu hình Card Mạng Tĩnh (Netplan) trên Server

1. **Sao lưu file Netplan mặc định để tránh xung đột:**
   ```bash
   sudo mkdir -p /etc/netplan/backup
   sudo mv /etc/netplan/*.yaml /etc/netplan/backup/
   ```

2. **Tạo file `/etc/netplan/01-netcfg.yaml`:**
   ```yaml
   network:
     version: 2
     ethernets:
       enp2s0:
         dhcp4: true
       enp10s0:
         dhcp4: false
         addresses:
           - 192.168.10.10/24
   ```
   *(Lưu ý: Không khai báo `routes: default` trên `enp10s0` để tránh xung đột đường ra Internet với card NAT `enp2s0`).*

3. **Phân quyền và áp dụng cấu hình:**
   ```bash
   sudo chmod 600 /etc/netplan/01-netcfg.yaml
   sudo netplan apply
   ip -4 a show enp10s0
   ```
   *Kết quả đạt (TC-01):* Hiện `inet 192.168.10.10/24` với `valid_lft forever`.

---

## 3. Kích hoạt và Bảo mật OpenSSH Server (Port 22)

1. **Kiểm tra / Cài đặt OpenSSH:**
   ```bash
   sudo systemctl status ssh
   # Nếu chưa có thì cài: sudo apt update && sudo apt install -y openssh-server
   ```

2. **Tạo file cấu hình bảo mật `/etc/ssh/sshd_config.d/01-lab-security.conf`:**
   *(Dùng file phụ trong `sshd_config.d/` để ghi đè gọn gàng mà không phải sửa file gốc dài dòng).*
   ```bash
   sudo tee /etc/ssh/sshd_config.d/01-lab-security.conf << 'EOF'
   Port 22
   PermitRootLogin no
   MaxAuthTries 5
   PasswordAuthentication yes
   EOF
   ```
   * **Giải thích ý nghĩa từng dòng:**
     * `Port 22`: Khớp với Port Matrix và luật tường lửa UFW.
     * `PermitRootLogin no`: Cấm đăng nhập trực tiếp bằng tài khoản `root` từ xa (chống tấn công dò mật khẩu vào `root`, buộc dùng user thường rồi mới `sudo`).
     * `MaxAuthTries 5`: Nhập sai quá 5 lần sẽ tự ngắt kết nối (chống brute-force).
     * `PasswordAuthentication yes`: Cho phép đăng nhập bằng mật khẩu để thao tác demo nhanh.

3. **Kiểm tra cú pháp và khởi động lại SSH:**
   ```bash
   sudo sshd -t && sudo systemctl enable --now ssh && sudo systemctl restart ssh
   sudo ss -tulnp | grep :22
   ```
   *Kết quả đạt (TC-02):* `ssh.service` ở trạng thái `active (running)`, lắng nghe ở `0.0.0.0:22`.

---

## 4. Kiểm thử kết nối SSH từ Ubuntu Client (TC-03)

*Trước khi TV2 triển khai DHCP Server, đặt IP tĩnh tạm cho Ubuntu Client (**Settings $\rightarrow$ Network $\rightarrow$ Wired $\rightarrow$ IPv4 $\rightarrow$ Manual**): `192.168.10.20`, Netmask `255.255.255.0`, Gateway `192.168.10.1`.*

```bash
ping -c 3 192.168.10.10
ssh anhxuan-devops@192.168.10.10
```
*(Mẹo: Trong quá trình quản trị, từ Terminal máy Mac cũng có thể SSH vào Server qua IP của card NAT `enp2s0`, còn khi nghiệm thu **TC-03** phải đứng từ Ubuntu Client SSH vào `192.168.10.10`).*
