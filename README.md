# ĐỀ TÀI: NGHIÊN CỨU VÀ TRIỂN KHAI HỆ THỐNG DỊCH VỤ MẠNG TRÊN UBUNTU SERVER

> **Môn học:** Hệ điều hành mạng Linux\
> **Hình thức:** Báo cáo nhóm kết hợp triển khai và demo thực tế\
> **Quy mô nhóm:** 04 thành viên\
> **Nền tảng chính:** Ubuntu Server 24.04 LTS\
> **Môi trường khuyến nghị:** VMware Workstation/Fusion hoặc VirtualBox

------------------------------------------------------------------------

## 1. Tổng quan đề tài

### 1.1. Bối cảnh

Trong hệ thống mạng doanh nghiệp, máy chủ Linux thường đảm nhiệm nhiều
dịch vụ nền tảng như cấp phát địa chỉ IP, phân giải tên miền, lưu trữ
website và hỗ trợ quản trị từ xa. Việc triển khai các dịch vụ này trên
Ubuntu Server giúp sinh viên hiểu cách một hệ điều hành mạng vận hành,
cách các máy tính giao tiếp với nhau và cách quản trị dịch vụ bằng dòng
lệnh Linux.

### 1.2. Mục tiêu

Nhóm xây dựng một mô hình mạng nhỏ trong đó Ubuntu Server cung cấp các
dịch vụ cho các máy Client. Sau khi hoàn thành, nhóm cần chứng minh
được:

-   Cài đặt và cấu hình Ubuntu Server.
-   Thiết lập cấu hình mạng phù hợp để máy chủ có địa chỉ IP ổn định.
-   Quản trị máy chủ từ xa bằng SSH.
-   Cấp phát địa chỉ IP tự động cho Client bằng DHCP.
-   Phân giải tên miền nội bộ bằng DNS.
-   Cung cấp website nội bộ bằng Nginx.
-   Kiểm soát truy cập mạng cơ bản bằng UFW Firewall.
-   Kiểm tra trạng thái dịch vụ, đọc log và xử lý một số lỗi thường gặp.

### 1.3. Phạm vi

**Phần bắt buộc:**

1.  Ubuntu Server và cấu hình mạng.
2.  SSH Server.
3.  DHCP Server.
4.  DNS Server (BIND9).
5.  Web Server (Nginx).
6.  Firewall (UFW).
7.  Kiểm thử kết nối và ghi nhận kết quả.

**Phần mở rộng nếu còn thời gian:**

-   HTTPS nội bộ bằng chứng chỉ tự ký.
-   Tách VLAN hoặc mô phỏng nhiều mạng con.
-   Thiết lập sao lưu cấu hình.
-   Theo dõi log tập trung hoặc giám sát tài nguyên máy chủ.

> Lưu ý: Nhóm nên hoàn thành toàn bộ phần bắt buộc trước khi làm phần mở
> rộng. Không triển khai quá nhiều dịch vụ khiến phần demo thiếu ổn
> định.

------------------------------------------------------------------------

## 2. Mô hình hệ thống đề xuất

### 2.1. Sơ đồ logic

``` text
                    MẠNG INTERNET (tùy chọn)
                              |
                       [NAT / Router]
                              |
                    Mạng LAN mô phỏng
                    192.168.10.0/24
                              |
             +----------------+----------------+
             |                                 |
     Ubuntu Server                       Máy Client
     192.168.10.10                       DHCP Client
             |                                 |
     +-------+--------+                        |
     |       |        |                        |
    SSH    DHCP      DNS                 Nhận IP tự động
             |        |                        |
             +--------+------------------------+
                      |
                  Nginx Web
               web.lab.local
```

Đây là sơ đồ logic minh họa. Khi cấu hình thực tế, nhóm phải bảo đảm các
máy ảo cùng kết nối vào một mạng ảo phù hợp. Không để DHCP của
VMware/VirtualBox cấp phát đồng thời với DHCP Server của nhóm trên cùng
phân đoạn mạng nếu chưa kiểm soát được cấu hình.

### 2.2. Kế hoạch địa chỉ IP tham khảo

  Thành phần        Địa chỉ / cấu hình
  ----------------- ---------------------------------
  Network           `192.168.10.0/24`
  Ubuntu Server     `192.168.10.10/24`
  Gateway           `192.168.10.1` (nếu có router)
  DNS nội bộ        `192.168.10.10`
  DHCP pool         `192.168.10.100–192.168.10.150`
  Tên miền nội bộ   `web.lab.local`
  Web Server        `http://web.lab.local`
  Client            Nhận IP tự động qua DHCP

**Quan trọng:** Đây là dải IP ví dụ, không phải cấu hình áp dụng cho mọi
máy. Trước khi cấu hình, nhóm cần kiểm tra subnet của mạng ảo và tránh
trùng với mạng LAN thật hoặc mạng VPN đang sử dụng. Nếu không có router
riêng, có thể dùng mạng Host-only/Internal Network để demo nội bộ.

### 2.3. Vai trò các máy

-   **Ubuntu Server:** Máy chủ trung tâm, chạy SSH, DHCP, DNS và Nginx.
-   **Ubuntu Desktop hoặc Windows Client:** Máy kiểm thử nhận IP, truy
    vấn DNS, truy cập website và SSH.
-   **Máy quản trị:** Có thể dùng chính máy host để SSH vào Ubuntu
    Server nếu cấu hình mạng cho phép.

------------------------------------------------------------------------

## 3. Công nghệ và công cụ sử dụng

  Công cụ                             Vai trò
  ----------------------------------- ----------------------------------
  Ubuntu Server 24.04 LTS             Hệ điều hành máy chủ
  VMware / VirtualBox                 Tạo và quản lý máy ảo
  OpenSSH Server                      Quản trị từ xa
  ISC DHCP Server                     Cấp phát IP tự động
  BIND9                               Dịch vụ DNS
  Nginx                               Web Server
  UFW                                 Quản lý firewall
  `ip`, `ss`, `ping`, `curl`, `dig`   Kiểm tra mạng và dịch vụ
  Wireshark (tùy chọn)                Quan sát gói tin DHCP, DNS, HTTP

**Lưu ý về DHCP:** Ubuntu Server 24.04 có thể sử dụng các giải pháp DHCP
khác nhau tùy môi trường và phiên bản gói. Nhóm thống nhất dùng một DHCP
server duy nhất; nếu chọn ISC DHCP Server thì cần kiểm tra khả năng
tương thích gói và tài liệu Ubuntu tại thời điểm cài đặt. Không chạy
song song nhiều DHCP server trên cùng interface.

------------------------------------------------------------------------

## 4. Phân công nhiệm vụ cho 4 thành viên

Phân công theo module để mỗi thành viên có đầu việc rõ ràng. Tuy nhiên,
tất cả thành viên đều phải hiểu sơ đồ tổng thể và tham gia kiểm thử tích
hợp.

### Thành viên 1 -- Nền tảng Ubuntu Server và SSH

**Nhiệm vụ:**

-   Tìm hiểu tổng quan Ubuntu Server và vai trò của Linux trong hệ thống
    mạng.
-   Tạo máy ảo, cài đặt Ubuntu Server.
-   Cấu hình card mạng và IP tĩnh.
-   Kiểm tra định tuyến, DNS bên ngoài (nếu có Internet).
-   Cài đặt và cấu hình OpenSSH Server.
-   Tạo tài khoản quản trị phục vụ demo; thiết lập quyền phù hợp.
-   Viết tài liệu hướng dẫn cài đặt và cấu hình nền tảng.

**Kết quả bàn giao:**

-   Ubuntu Server hoạt động ổn định.
-   Có thể SSH từ Client hoặc máy host vào Server.
-   Tài liệu cấu hình IP, SSH và ảnh chụp kết quả.

**Minh chứng cần có:**

-   `ip a`
-   `ip route`
-   `systemctl status ssh`
-   Kết quả đăng nhập SSH thành công.

### Thành viên 2 -- DHCP Server

**Nhiệm vụ:**

-   Nghiên cứu nguyên lý DHCP và quy trình DORA: Discover, Offer,
    Request, Acknowledge.
-   Cài đặt và cấu hình DHCP Server.
-   Khai báo subnet, dải IP cấp phát, gateway và DNS.
-   Chỉ định đúng interface phục vụ DHCP.
-   Kiểm thử Client nhận địa chỉ IP tự động.
-   Ghi lại log hoặc thông tin lease để chứng minh hoạt động.

**Kết quả bàn giao:**

-   DHCP Server cấp phát IP đúng dải đã thiết kế.
-   Client nhận được subnet mask, gateway và DNS phù hợp.
-   Tài liệu cấu hình và ảnh chụp kết quả.

**Minh chứng cần có:**

-   Cấu hình DHCP.
-   Trạng thái dịch vụ DHCP.
-   Thông tin IP trên Client sau khi xin lease.
-   Log hoặc lease tương ứng.

### Thành viên 3 -- DNS Server và Nginx Web Server

**Nhiệm vụ:**

-   Nghiên cứu chức năng DNS và cách phân giải tên miền.
-   Cài đặt, cấu hình BIND9.
-   Tạo zone nội bộ, ví dụ `lab.local` hoặc một tên miền lab thống nhất.
-   Tạo bản ghi A cho `web.lab.local` trỏ về IP máy chủ.
-   Kiểm tra phân giải DNS từ Client.
-   Cài đặt Nginx và tạo trang web giới thiệu đề tài.
-   Kiểm tra truy cập website bằng IP và bằng tên miền.

**Kết quả bàn giao:**

-   DNS phân giải đúng tên miền nội bộ.
-   Nginx phục vụ được trang web.
-   Client truy cập được `http://web.lab.local`.

**Minh chứng cần có:**

-   Cấu hình zone DNS.
-   Kết quả `dig web.lab.local`.
-   Trạng thái BIND9 và Nginx.
-   Kết quả `curl http://web.lab.local` hoặc ảnh trình duyệt.

### Thành viên 4 -- Firewall, kiểm thử tích hợp và điều phối báo cáo

**Nhiệm vụ:**

-   Nghiên cứu UFW và nguyên tắc chỉ mở các cổng cần thiết.
-   Xây dựng chính sách firewall cho SSH, DNS, DHCP và HTTP.
-   Phối hợp các thành viên kiểm tra luồng kết nối.
-   Lập bảng test case: mục tiêu, thao tác, kết quả mong đợi, kết quả
    thực tế.
-   Tổng hợp ảnh chụp, cấu hình và log minh chứng.
-   Chuẩn bị kịch bản demo, slide và điều phối phần báo cáo.

**Kết quả bàn giao:**

-   Firewall hoạt động đúng chính sách.
-   Có bảng kiểm thử tích hợp.
-   Có bộ minh chứng và kịch bản demo hoàn chỉnh.

**Minh chứng cần có:**

-   `sudo ufw status verbose`
-   Danh sách cổng đang lắng nghe từ `ss -tulnp`.
-   Kết quả truy cập thành công/thất bại theo chính sách.
-   Bảng test case và ảnh chụp.

> Thành viên 4 không chỉ làm slide. Thành viên này cần phối hợp kỹ
> thuật, trực tiếp kiểm thử và hiểu cách các dịch vụ liên kết với nhau.

------------------------------------------------------------------------

## 5. Quy trình thực hiện theo giai đoạn

### Giai đoạn 1 -- Khảo sát và thiết kế

**Mục tiêu:** Cả nhóm thống nhất phạm vi, sơ đồ và thông số trước khi
cài đặt.

Công việc:

1.  Đọc yêu cầu môn học và xác định nội dung giảng viên yêu cầu.
2.  Thống nhất phiên bản Ubuntu Server.
3.  Chọn VMware hoặc VirtualBox.
4.  Thiết kế sơ đồ mạng.
5.  Chốt dải IP, IP máy chủ, DHCP pool và tên miền nội bộ.
6.  Chốt người phụ trách từng module.
7.  Tạo thư mục lưu cấu hình, ảnh chụp và báo cáo.

**Đầu ra:** Sơ đồ mạng, bảng IP, phân công nhiệm vụ và danh sách công
cụ.

### Giai đoạn 2 -- Dựng môi trường

**Mục tiêu:** Có môi trường máy chủ và máy Client kết nối được với nhau.

Công việc:

1.  Tạo máy ảo Ubuntu Server.
2.  Tạo máy Client.
3.  Cấu hình network adapter cho các máy.
4.  Cấu hình IP tĩnh cho Server.
5.  Kiểm tra ping giữa Server và Client.
6.  Cập nhật hệ thống và cài các công cụ cần thiết.

**Đầu ra:** Môi trường lab hoạt động, kết nối cơ bản ổn định.

### Giai đoạn 3 -- Triển khai các dịch vụ

Thực hiện theo thứ tự:

1.  SSH: bảo đảm có thể quản trị máy chủ.
2.  DHCP: cấu hình cấp phát IP cho Client.
3.  DNS: cấu hình phân giải tên miền nội bộ.
4.  Nginx: triển khai website.
5.  UFW: áp dụng chính sách firewall.

Sau mỗi dịch vụ, người phụ trách phải kiểm tra độc lập và lưu lại cấu
hình đã hoạt động.

**Đầu ra:** Các dịch vụ chạy riêng lẻ và có minh chứng.

### Giai đoạn 4 -- Tích hợp và kiểm thử

**Mục tiêu:** Chứng minh các dịch vụ phối hợp thành một hệ thống hoàn
chỉnh.

Luồng kiểm thử chính:

1.  Client khởi động và nhận IP từ DHCP.
2.  Client nhận đúng DNS Server.
3.  Client truy vấn `web.lab.local`.
4.  DNS trả về IP `192.168.10.10`.
5.  Client gửi HTTP request đến Nginx.
6.  Nginx trả về trang web.
7.  Quản trị viên SSH vào Server.
8.  Firewall chỉ cho phép các dịch vụ cần thiết.

**Đầu ra:** Bảng kiểm thử có kết quả thực tế, ảnh chụp và log.

### Giai đoạn 5 -- Hoàn thiện báo cáo và demo

Công việc:

-   Viết báo cáo theo cấu trúc thống nhất.
-   Hoàn thiện slide.
-   Chụp ảnh sơ đồ và kết quả kiểm thử.
-   Chuẩn bị dữ liệu demo.
-   Chạy thử toàn bộ kịch bản ít nhất hai lần.
-   Chuẩn bị phương án dự phòng nếu mạng ảo hoặc dịch vụ gặp lỗi.

**Đầu ra:** Báo cáo, slide, bộ cấu hình và demo hoàn chỉnh.

------------------------------------------------------------------------

## 6. Danh sách kiểm thử nghiệm thu

  -----------------------------------------------------------------------
  ID                      Nội dung kiểm thử       Kết quả mong đợi
  ----------------------- ----------------------- -----------------------
  TC-01                   Server có IP tĩnh       Đúng IP đã thiết kế

  TC-02                   Client ping Server      Kết nối thành công

  TC-03                   SSH từ Client vào       Đăng nhập thành công
                          Server                  

  TC-04                   Client xin IP DHCP      Nhận IP trong DHCP pool

  TC-05                   Client kiểm tra DNS     DNS trỏ đúng về Server

  TC-06                   Truy vấn                Trả về `192.168.10.10`
                          `web.lab.local`         

  TC-07                   Truy cập website bằng   Nginx trả về trang web
                          IP                      

  TC-08                   Truy cập website bằng   Website hiển thị đúng
                          tên miền                

  TC-09                   Kiểm tra Firewall       Chỉ mở các cổng cần
                                                  thiết

  TC-10                   Kiểm tra trạng thái     Các dịch vụ ở trạng
                          dịch vụ                 thái hoạt động
  -----------------------------------------------------------------------

Nhóm không được đánh dấu "Pass" chỉ dựa trên cấu hình. Mỗi test case cần
có kết quả chạy thực tế và minh chứng tương ứng.

------------------------------------------------------------------------

## 7. Kịch bản demo trước giảng viên

Thời lượng đề xuất: 8--12 phút, tùy thời gian giảng viên phân bổ.

### Bước 1 -- Giới thiệu mô hình

-   Trình bày mục tiêu đề tài.
-   Giới thiệu sơ đồ mạng.
-   Giải thích vai trò Server và Client.
-   Giới thiệu các dịch vụ được triển khai.

### Bước 2 -- Demo quản trị Linux và SSH

-   Mở terminal trên Client.
-   SSH vào Ubuntu Server.
-   Thực hiện một số lệnh kiểm tra hệ thống.
-   Giới thiệu cấu hình IP và trạng thái SSH.

### Bước 3 -- Demo DHCP

-   Đưa Client về chế độ nhận IP tự động.
-   Thực hiện renew DHCP lease nếu cần.
-   Hiển thị IP, gateway và DNS mà Client nhận được.
-   Đối chiếu với dải DHCP đã cấu hình.

### Bước 4 -- Demo DNS và Web Server

-   Chạy `dig web.lab.local`.
-   Chứng minh tên miền được phân giải về IP Server.
-   Mở trình duyệt và truy cập `http://web.lab.local`.
-   Giới thiệu trang web do Nginx cung cấp.

### Bước 5 -- Demo Firewall

-   Hiển thị trạng thái UFW.
-   Giải thích các cổng được cho phép.
-   Kiểm tra một luồng truy cập được phép và một luồng bị chặn (nếu đã
    chuẩn bị test an toàn).

### Bước 6 -- Tổng kết

-   Nhắc lại các mục tiêu đã hoàn thành.
-   Nêu khó khăn và cách xử lý.
-   Đề xuất hướng mở rộng.

------------------------------------------------------------------------

## 8. Các lệnh Linux tham khảo

> Các lệnh dưới đây dùng để kiểm tra và quản trị. Cần đọc kỹ trước khi
> chạy lệnh thay đổi cấu hình.

### 8.1. Kiểm tra hệ thống và mạng

``` bash
hostnamectl
ip a
ip route
resolvectl status
ping -c 4 192.168.10.10
ss -tulnp
```

### 8.2. Quản lý dịch vụ

``` bash
sudo systemctl status ssh
sudo systemctl status nginx
sudo systemctl status bind9

sudo systemctl restart ssh
sudo systemctl restart nginx
```

Tên service DHCP phụ thuộc gói DHCP nhóm cài đặt; kiểm tra bằng
`systemctl list-units --type=service` thay vì đoán tên service.

### 8.3. Kiểm tra DNS và Web

``` bash
dig web.lab.local
nslookup web.lab.local
curl -I http://web.lab.local
```

### 8.4. Kiểm tra Firewall

``` bash
sudo ufw status verbose
sudo ufw status numbered
```

**Cảnh báo:** Nếu cấu hình UFW qua SSH, hãy cho phép cổng SSH trước khi
bật firewall để tránh tự khóa quyền quản trị từ xa. Không bật DHCP
Server trên mạng đang có DHCP khác nếu chưa kiểm soát được môi trường.

------------------------------------------------------------------------

## 9. Cấu trúc thư mục lưu trữ sản phẩm nhóm

Nhóm nên tạo một repository GitHub/GitLab để lưu toàn bộ tài liệu và cấu
hình.

``` text
linux-network-os-project/
├── README.md
├── docs/
│   ├── 01-project-overview.md
│   ├── 02-network-design.md
│   ├── 03-installation-guide.md
│   ├── 04-testing-and-results.md
│   └── 05-presentation-outline.md
├── configs/
│   ├── network/
│   ├── dhcp/
│   ├── dns/
│   ├── nginx/
│   └── firewall/
├── evidence/
│   ├── server/
│   ├── ssh/
│   ├── dhcp/
│   ├── dns/
│   ├── web/
│   └── firewall/
├── report/
│   └── final-report.pdf
└── presentation/
    └── final-slides.pptx
```

**Quy tắc làm việc:**

-   Không đưa mật khẩu, private key, token hoặc dữ liệu nhạy cảm lên
    repository.
-   Mỗi thành viên cập nhật tài liệu và minh chứng của module mình phụ
    trách.
-   Không sửa trực tiếp cấu hình đã ổn định của thành viên khác nếu chưa
    trao đổi.
-   Ghi lại thay đổi quan trọng để cả nhóm có thể khôi phục.
-   Có thể dùng Git branch hoặc thư mục riêng cho từng module; trước
    ngày demo phải tích hợp vào một phiên bản thống nhất.

------------------------------------------------------------------------

## 10. Cấu trúc báo cáo cuối kỳ đề xuất

1.  **Chương 1 -- Tổng quan:** Lý do chọn đề tài, mục tiêu, phạm vi.
2.  **Chương 2 -- Cơ sở lý thuyết:** Linux Server, SSH, DHCP, DNS,
    Nginx, Firewall.
3.  **Chương 3 -- Phân tích và thiết kế:** Sơ đồ mạng, bảng IP, mô hình
    hoạt động.
4.  **Chương 4 -- Triển khai:** Môi trường, cài đặt và cấu hình từng
    dịch vụ.
5.  **Chương 5 -- Kiểm thử và đánh giá:** Test case, kết quả, ảnh chụp,
    log.
6.  **Chương 6 -- Kết luận và hướng phát triển:** Kết quả đạt được, hạn
    chế, hướng mở rộng.

Mỗi chương cần có nội dung thực tế của nhóm, không chỉ sao chép định
nghĩa từ Internet.

------------------------------------------------------------------------

## 11. Tiêu chí hoàn thành đề tài

-   [ ] Có sơ đồ mạng và bảng địa chỉ IP thống nhất.
-   [ ] Ubuntu Server cài đặt và hoạt động ổn định.
-   [ ] Server có IP tĩnh và Client kết nối được.
-   [ ] SSH hoạt động.
-   [ ] DHCP cấp phát IP đúng.
-   [ ] DNS phân giải tên miền nội bộ đúng.
-   [ ] Nginx phục vụ website thành công.
-   [ ] UFW có chính sách truy cập rõ ràng.
-   [ ] Có tối thiểu 10 test case và minh chứng.
-   [ ] Có báo cáo và slide hoàn chỉnh.
-   [ ] Cả 4 thành viên đều giải thích được mô hình tổng thể.
-   [ ] Đã chạy thử demo và chuẩn bị phương án dự phòng.

------------------------------------------------------------------------

## 12. Nguyên tắc phối hợp nhóm

1.  Mỗi thành viên chịu trách nhiệm chính cho module được giao, nhưng
    phải hỗ trợ tích hợp khi cần.
2.  Trước khi cấu hình, phải thống nhất IP, interface, hostname và tên
    miền.
3.  Mọi cấu hình quan trọng phải được sao lưu trước khi chỉnh sửa.
4.  Sau mỗi thay đổi, phải kiểm tra dịch vụ và ghi lại kết quả.
5.  Nếu gặp lỗi, lưu thông báo lỗi, log và các bước đã thử; không sửa
    ngẫu nhiên nhiều cấu hình cùng lúc.
6.  Không để đến sát ngày báo cáo mới ghép các module.
7.  Mỗi thành viên phải chuẩn bị phần trình bày và câu hỏi chuyên môn
    thuộc module của mình.

------------------------------------------------------------------------

## 13. Việc cần làm ngay sau khi thống nhất đề tài

-   [ ] Tạo nhóm trao đổi và repository chung.
-   [ ] Chốt tên 4 thành viên và người phụ trách từng module.
-   [ ] Chốt VMware hay VirtualBox.
-   [ ] Chốt Ubuntu Server 24.04 LTS.
-   [ ] Chốt sơ đồ mạng và dải IP.
-   [ ] Tạo máy ảo Server và Client.
-   [ ] Hoàn thành Giai đoạn 1 trước khi chuyển sang cấu hình dịch vụ.

**Thông điệp chung:** Mục tiêu của đề tài không phải là cài được thật
nhiều phần mềm, mà là xây dựng một hệ thống dịch vụ mạng Linux có thiết
kế rõ ràng, vận hành ổn định, kiểm thử được và giải thích được nguyên lý
hoạt động.
