# GIAI ĐOẠN 6: TRIỂN KHAI GIÁM SÁT TÀI NGUYÊN PROMETHEUS, NODE EXPORTER & GRAFANA

> **Giai đoạn:** Giai đoạn 6 (Ngày 12–13 — Tích hợp hệ thống & Giám sát mở rộng)  
> **Người phụ trách:** Nguyễn Anh Xuân (TV1 - Leader)  
> **Test Case nghiệm thu:** **TC-11** (Giám sát CPU, RAM, Disk, Network thời gian thực tại `http://monitor.lab.local`)  
> **File cấu hình liên quan:** `configs/monitoring/prometheus.yml`, `configs/nginx/monitor.lab.local.conf`, `scripts/setup_monitoring.sh`

---

## 1. Kiến trúc triển khai

```text
[Client Browser: http://monitor.lab.local]
          │ (HTTP Port 80 — qua UFW)
          ▼
[Nginx Reverse Proxy (Port 80)] ──proxy_pass──► [Grafana Server (127.0.0.1:3000)]
                                                         │ (Truy vấn PromQL)
                                                         ▼
                                                [Prometheus (127.0.0.1:9090)]
                                                         │ (Scrape mỗi 15s)
                                                         ▼
                                                [Node Exporter (127.0.0.1:9100)]
                                                (Đọc CPU, RAM, Disk, Network Linux)
```

> **Trước khi triển khai:** Khuyến nghị **Take Snapshot** trên VMware Fusion (*Virtual Machine $\rightarrow$ Snapshots $\rightarrow$ Take Snapshot*) để lưu điểm khôi phục trạng thái 10/10 Test Cases cốt lõi.

---

## 2. Quy trình triển khai chi tiết trên Ubuntu Server

*(Có thể chạy tự động 1 lệnh bằng `./scripts/setup_monitoring.sh`, hoặc thực hiện chi tiết từng bước dưới đây).*

### Bước 1: Cài đặt Prometheus & Node Exporter
> **Xử lý sự cố mirror thực tế (ARM64/aarch64):** Nếu `apt` báo `Failed to fetch http://vn.archive.ubuntu.com/...`, chạy lệnh sau để chuyển sang kho quốc tế chính chủ `ports.ubuntu.com` trước khi cài:
> ```bash
> sudo sed -i 's|http://vn.archive.ubuntu.com/ubuntu|http://ports.ubuntu.com/ubuntu-ports|g' /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null
> ```

Cài đặt và kích hoạt:
```bash
sudo apt update
sudo apt install -y prometheus prometheus-node-exporter
sudo systemctl enable --now prometheus prometheus-node-exporter
```
*(Mặc định gói `prometheus` của Ubuntu đã cấu hình sẵn job `node` kéo metrics từ `localhost:9100` — tham chiếu `configs/monitoring/prometheus.yml`).*

### Bước 2: Cài đặt Grafana từ kho APT chính thức
```bash
sudo apt install -y apt-transport-https software-properties-common wget gpg
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update && sudo apt install -y grafana
sudo systemctl enable --now grafana-server
```

### Bước 3: Bổ sung bản ghi DNS `monitor.lab.local` vào BIND9
```bash
echo "monitor IN      A       192.168.10.10" | sudo tee -a /etc/bind/zones/db.lab.local
sudo named-checkzone lab.local /etc/bind/zones/db.lab.local
sudo systemctl restart bind9
```

### Bước 4: Cấu hình Nginx Reverse Proxy cho `http://monitor.lab.local`
Sao chép từ `configs/nginx/monitor.lab.local.conf` (có hỗ trợ WebSocket cho Grafana Live) và kích hoạt:
```bash
sudo cp configs/nginx/monitor.lab.local.conf /etc/nginx/sites-available/monitor.lab.local.conf
sudo ln -sf /etc/nginx/sites-available/monitor.lab.local.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx
```

### Bước 5: Kiểm tra trạng thái cả 3 dịch vụ giám sát
```bash
systemctl is-active prometheus prometheus-node-exporter grafana-server
# Kết quả bắt buộc: 3 dòng "active"
```

---

## 3. Cấu hình Dashboard Grafana trên trình duyệt Ubuntu Client (TC-11)

1. Mở trình duyệt **Firefox** trên Ubuntu Client, truy cập **`http://monitor.lab.local`**.
2. Đăng nhập mặc định: tài khoản **`admin`** / mật khẩu **`admin`** (có thể đổi mật khẩu hoặc chọn *Skip*).
3. **Kết nối nguồn dữ liệu Prometheus:**
   * Menu **☰** $\rightarrow$ **Connections** $\rightarrow$ **Data sources** $\rightarrow$ **Add data source** $\rightarrow$ **Prometheus**.
   * Nhập **Prometheus server URL:** `http://localhost:9090`.
   * Bấm **Save & test** $\rightarrow$ xác nhận thông báo xanh **`Successfully queried the Prometheus API.`**
4. **Import Dashboard mẫu chuẩn doanh nghiệp (ID `1860` — Node Exporter Full):**
   * Bấm dấu **`+`** (góc trên phải) $\rightarrow$ **Import dashboard**.
   * Nhập ID **`1860`** vào ô *Grafana.com dashboard URL or ID* $\rightarrow$ bấm **Load**.
   * Chọn Data source `prometheus` $\rightarrow$ bấm **Import**.
5. **Kết quả đạt (TC-11):** Bảng **Node Exporter Full** hiển thị trực tiếp thông số thời gian thực của `ubuntu-server` (`localhost:9100`): CPU Busy %, RAM Used %, Swap, RootFS Used %, CPU Cores, Uptime và các biểu đồ CPU/Memory/Network/Disk.

---

## Minh chứng nghiệm thu đã lưu
* **TC-11:** `evidence/monitoring/tc11-grafana-node-exporter-dashboard.jpg`
