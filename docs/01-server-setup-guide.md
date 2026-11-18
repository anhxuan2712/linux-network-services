# HƯỚNG DẪN CÀI ĐẶT NỀN TẢNG UBUNTU SERVER 24.04 LTS & DỊCH VỤ OPENSSH

> **Người phụ trách:** Nguyễn Anh Xuân (TV1 - Leader)  
> **Mục tiêu:** Cài đặt hệ điều hành, cấu hình Netplan gán IP tĩnh `192.168.10.10/24`, kích hoạt và bảo mật OpenSSH.

---

## 1. Cấu hình Card Mạng Tĩnh (Netplan)

* **File cấu hình:** `/etc/netplan/50-cloud-init.yaml` hoặc `01-netcfg.yaml` (lưu mẫu tại `configs/network/01-netplan.yaml`)
* **Kiểm tra tên interface:**
  ```bash
  ip link show
  ```
  *(Thường là `ens33` trên VMware Workstation/Fusion hoặc `enp0s3` trên VirtualBox)*

* **Áp dụng cấu hình:**
  ```bash
  sudo netplan apply
  ```

* **Kiểm tra trạng thái IP:**
  ```bash
  ip a show dev <interface>
  ip route
  ```

---

## 2. Cài đặt và Quản trị dịch vụ OpenSSH Server

* **Cài đặt gói:**
  ```bash
  sudo apt update
  sudo apt install -y openssh-server
  ```

* **Kiểm tra trạng thái SSH:**
  ```bash
  sudo systemctl status ssh
  sudo systemctl enable ssh
  ```

* **Kiểm tra cổng lắng nghe (Port 22):**
  ```bash
  sudo ss -tuln | grep :22
  ```

* **Thử nghiệm kết nối từ máy Client:**
  ```bash
  ssh user@192.168.10.10
  ```
