# Hệ Thống Tự Động In File Theo Lịch (Debian Linux)

Hệ thống này cho phép đóng gói file PDF `color-test-page.pdf` và kịch bản cài đặt thành **một file duy nhất (`setup.sh`)**. Người dùng cuối chỉ cần sao chép một dòng lệnh duy nhất để tải và cài đặt tự động trên máy chạy Debian Linux (hoặc Ubuntu).

---

## 📂 Danh sách các file trong dự án

1. **`color-test-page.pdf`**: File PDF cần in.
2. **`setup_template.sh`**: Bản mẫu kịch bản cài đặt (chứa logic kiểm tra gói, chọn máy in, thiết lập giờ in và tạo cron job).
3. **`build.sh`**: Công cụ đóng gói tự động. Nó sẽ mã hóa file PDF thành Base64 và chèn vào `setup_template.sh` để sinh ra file cài đặt độc lập `setup.sh`.
4. **`setup.sh`**: File cài đặt tích hợp hoàn chỉnh (được sinh ra sau khi chạy `build.sh`).

---

## 🛠️ Hướng dẫn sử dụng cho Quản trị viên (Chủ Host)

### Bước 1: Đóng gói kịch bản cài đặt
Mỗi khi bạn thay đổi file `color-test-page.pdf` hoặc cập nhật logic trong `setup_template.sh`, hãy chạy lệnh sau trên terminal:
```bash
./build.sh
```
Sau khi chạy thành công, file `setup.sh` sẽ được tạo ra.

### Bước 2: Tải lên hosting hoặc GitHub
Bạn có thể tải file `setup.sh` lên bất kỳ máy chủ web nào hoặc đưa lên một kho lưu trữ (repository) công khai trên GitHub.

- **Cách 1: Sử dụng Host riêng**: Tải file `setup.sh` lên host của bạn tại một đường dẫn công khai (ví dụ: `https://my-host.com/print-automation/setup.sh`).
- **Cách 2: Sử dụng GitHub (Miễn phí & Khuyên dùng)**:
  1. Tạo một repository công khai trên GitHub (ví dụ: `print-automation`).
  2. Push file `setup.sh` (và các file nguồn khác nếu muốn chia sẻ mã nguồn) lên repository này.
  3. Đường dẫn tải trực tiếp (Raw link) của bạn sẽ là: `https://raw.githubusercontent.com/mr-old-youtube/print-automation/main/setup.sh`.

---

## 💻 Hướng dẫn dành cho Người dùng cuối (Client chạy Debian)

Người dùng cuối chỉ cần sao chép và chạy lệnh sau trên máy chủ/máy trạm Debian để bắt đầu cài đặt:

- **Nếu dùng Host riêng**:
  ```bash
  curl -fsSL https://<HOST_CUA_BAN>/setup.sh | sudo bash
  ```
- **Nếu dùng GitHub**:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/mr-old-youtube/print-automation/main/setup.sh | sudo bash
  ```
*(Thay thế các giá trị trong `<...>` bằng thông tin thực tế của bạn nếu sử dụng host riêng)*

### Quá trình cài đặt tự động sẽ hỏi người dùng:
1. **Lựa chọn máy in**: Liệt kê các máy in có sẵn trên hệ thống CUPS để người dùng chọn bằng số thứ tự. Nếu chưa có máy in, script sẽ hướng dẫn cách thêm hoặc để trống để in bằng máy in mặc định.
2. **Thiết lập giờ in**: Nhập giờ muốn in (0-23, mặc định 8h sáng).
3. **Thiết lập phút in**: Nhập phút muốn in (0-59, mặc định 0 phút).
4. **Thiết lập ngày in**: 
   - Hàng ngày.
   - Các ngày làm việc (Thứ 2 đến Thứ 6).
   - Cuối tuần (Thứ 7 & Chủ nhật).
   - Hoặc các ngày cụ thể tuỳ chọn (Ví dụ: in vào các ngày Thứ 2, Thứ 4, Thứ 6).
5. **In thử nghiệm**: Hỏi người dùng xem có muốn in thử 1 bản ngay lập tức để kiểm tra kết nối máy in hay không.

---

## 🔄 Chỉnh sửa/Thay đổi lịch in hoặc máy in

Nếu hệ thống đã được cài đặt và bạn muốn **chỉnh sửa lịch in hoặc chọn máy in khác**, bạn chỉ cần chạy lại lệnh cài đặt:

- **Cách 1: Chạy tương tác (Khuyên dùng)**:
  Chạy lại lệnh cài đặt trên máy client:
  ```bash
  sudo ./setup.sh
  ```
  Hệ thống sẽ phát hiện phiên bản cũ và hiển thị menu. Chọn `1) Chỉnh sửa cấu hình / Thay đổi lịch in`. 
  Script sẽ tự động đọc các thiết lập hiện tại (máy in đang dùng, giờ/phút/ngày in hiện tại) để hiển thị làm **[Đang dùng]** và **điền sẵn làm mặc định**, giúp bạn chỉnh sửa cực kỳ nhanh mà không cần gõ lại toàn bộ. Ngoài ra, script sẽ tự động bỏ qua bước cập nhật gói (`apt-get update`) để tiết kiệm thời gian.

- **Cách 2: Chạy trực tiếp qua mạng bằng cờ cấu hình**:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/mr-old-youtube/print-automation/main/setup.sh | sudo bash -s -- --reconfigure
  ```

---

## 🔍 Kiểm tra trạng thái và Lịch sử in

- **Thư mục cài đặt**: `/opt/print-automation/`
- **File in trực tiếp**: Bạn có thể chạy thử lệnh in bất kỳ lúc nào bằng cách chạy file `/opt/print-automation/print-job.sh` dưới quyền root:
  ```bash
  sudo /opt/print-automation/print-job.sh
  ```
- **Xem lịch sử in (Log)**: Nhật ký in sẽ được ghi chi tiết tại `/var/log/print-automation.log`. Xem nhật ký in bằng cách chạy:
  ```bash
  cat /var/log/print-automation.log
  ```
- **Kiểm tra lịch Cron Job**:
  ```bash
  cat /etc/cron.d/print-automation
  ```

---

## ❌ Hướng dẫn Gỡ cài đặt (Uninstall)

Bạn có thể gỡ cài đặt hệ thống in tự động một cách nhanh chóng theo các cách sau:

### Cách 1: Chạy trực tiếp từ file cài đặt đã tải (Khuyên dùng)
Nếu file cài đặt `setup.sh` vẫn còn trên máy, hãy chạy lệnh sau:
```bash
sudo ./setup.sh --uninstall
```
Hoặc đơn giản là chạy lại lệnh cài đặt thông thường (`sudo ./setup.sh`), hệ thống sẽ tự động phát hiện bản cài đặt cũ và hỏi bạn có muốn gỡ cài đặt hay không.

### Cách 2: Chạy trực tiếp qua mạng (Không cần lưu file)
Bạn có thể chạy lệnh gỡ cài đặt trực tuyến bằng cách truyền thêm tham số `--uninstall` vào sau kịch bản chạy:

- **Nếu dùng Host riêng**:
  ```bash
  curl -fsSL https://<HOST_CUA_BAN>/setup.sh | sudo bash -s -- --uninstall
  ```
- **Nếu dùng GitHub**:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/mr-old-youtube/print-automation/main/setup.sh | sudo bash -s -- --uninstall
  ```

### Cách 3: Gỡ cài đặt thủ công (Nếu muốn)
Chạy các lệnh sau dưới quyền root để gỡ cài đặt thủ công:
```bash
# 1. Xóa lịch in tự động
sudo rm -f /etc/cron.d/print-automation
sudo systemctl restart cron || true

# 2. Xóa các file cài đặt
sudo rm -rf /opt/print-automation/

# 3. (Tùy chọn) Xóa file nhật ký in
sudo rm -f /var/log/print-automation.log

echo "Đã gỡ cài đặt thành công hệ thống tự động in!"
```
