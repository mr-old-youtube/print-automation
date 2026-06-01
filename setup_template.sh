#!/usr/bin/env bash

# ==============================================================================
# BỘ CÀI ĐẶT & GỠ CÀI ĐẶT TỰ ĐỘNG IN FILE THEO LỊCH (DÀNH CHO DEBIAN LINUX)
# ==============================================================================

set -e

# Khai báo hàm gỡ cài đặt hệ thống
uninstall_system() {
    echo "======================================================================"
    echo "    BẮT ĐẦU GỠ CÀI ĐẶT HỆ THỐNG TỰ ĐỘNG IN FILE"
    echo "======================================================================"
    echo
    
    # 1. Xóa lịch in tự động (Cron Job)
    if [ -f "/etc/cron.d/print-automation" ]; then
        echo "Đang gỡ bỏ lịch in tự động (Cron Job)..."
        rm -f /etc/cron.d/print-automation
        
        # Khởi động lại cron để áp dụng cấu hình mới
        if command -v systemctl &>/dev/null; then
            systemctl restart cron || true
        else
            service cron restart || true
        fi
        echo "- Đã xóa lịch Cron Job."
    else
        echo "- Không tìm thấy lịch in tự động."
    fi

    # 2. Xóa các file vận hành
    if [ -d "/opt/print-automation" ]; then
        echo "Đang xóa thư mục cài đặt /opt/print-automation..."
        rm -rf /opt/print-automation
        echo "- Đã xóa thư mục ứng dụng."
    else
        echo "- Không tìm thấy thư mục cài đặt."
    fi

    # 3. Hỏi người dùng có muốn xóa file log không
    if [ -f "/var/log/print-automation.log" ]; then
        echo
        read -p "Bạn có muốn xóa file nhật ký in (/var/log/print-automation.log) không? (y/n) [Mặc định: n]: " DELETE_LOG < /dev/tty
        DELETE_LOG=${DELETE_LOG:-n}
        if [[ "$DELETE_LOG" =~ ^[yY](e[sS])?$ ]]; then
            echo "Đang xóa file nhật ký..."
            rm -f /var/log/print-automation.log
            echo "- Đã xóa file nhật ký."
        else
            echo "- Đã giữ lại file nhật ký."
        fi
    fi

    echo
    echo "======================================================================"
    echo "    GỠ CÀI ĐẶT HOÀN TẤT THÀNH CÔNG!"
    echo "======================================================================"
    exit 0
}

# Đảm bảo script được chạy dưới quyền root
if [ "$EUID" -ne 0 ]; then
    echo "LỖI: Vui lòng chạy script này dưới quyền root (sudo)." >&2
    echo "Ví dụ: sudo bash setup.sh" >&2
    exit 1
fi

# Xử lý tham số dòng lệnh (ví dụ: --uninstall)
UNINSTALL_MODE=false
for arg in "$@"; do
    case $arg in
        -u|--uninstall)
            UNINSTALL_MODE=true
            shift
            ;;
    esac
done

# Nếu chạy với tham số gỡ cài đặt
if [ "$UNINSTALL_MODE" = true ]; then
    uninstall_system
fi

# Tự động phát hiện phiên bản cài đặt cũ
if [ -d "/opt/print-automation" ] || [ -f "/etc/cron.d/print-automation" ]; then
    echo "======================================================================"
    echo "    HỆ THỐNG IN TỰ ĐỘNG ĐÃ ĐƯỢC CÀI ĐẶT TRÊN MÁY NÀY"
    echo "======================================================================"
    echo "Vui lòng chọn thao tác bạn muốn thực hiện:"
    echo "1) Cài đặt lại / Cấu hình lại lịch in (Reconfigure)"
    echo "2) Gỡ cài đặt hoàn toàn hệ thống (Uninstall)"
    echo "3) Thoát (Exit)"
    echo "----------------------------------------------------------------------"
    
    while true; do
        read -p "Lựa chọn của bạn (1-3): " ALREADY_CHOICE < /dev/tty
        case "$ALREADY_CHOICE" in
            1)
                echo "Bắt đầu cập nhật cấu hình hệ thống..."
                echo
                break
                ;;
            2)
                uninstall_system
                ;;
            3)
                echo "Đã thoát cài đặt."
                exit 0
                ;;
            *)
                echo "Lựa chọn không hợp lệ. Vui lòng nhập số từ 1 đến 3."
                ;;
        esac
    done
fi

echo "======================================================================"
echo "    BẮT ĐẦU CÀI ĐẶT HỆ THỐNG TỰ ĐỘNG IN FILE (COLOR TEST PAGE)"
echo "======================================================================"
echo

# 1. Cập nhật và cài đặt dependencies
echo ">>> Bước 1: Cài đặt các gói phụ thuộc (cups, cups-client, cron)..."
apt-get update -y

install_if_missing() {
    local pkg=$1
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        echo "Đang cài đặt $pkg..."
        apt-get install -y "$pkg"
    else
        echo "- $pkg đã được cài đặt."
    fi
}

install_if_missing cups
install_if_missing cups-client
install_if_missing cron

# Đảm bảo các services đang chạy
echo "Kích hoạt và chạy các dịch vụ..."
systemctl enable cups || true
systemctl start cups || true
systemctl enable cron || true
systemctl start cron || true

echo "Đã cài đặt và kích hoạt thành công các dịch vụ cần thiết."
echo

# 2. Cấu hình máy in
echo ">>> Bước 2: Cấu hình và chọn máy in..."
echo "Đang kiểm tra các máy in đã được cấu hình trên hệ thống..."
sleep 2

# Lấy danh sách máy in từ CUPS
PRINTER_LIST=()
while IFS= read -r line; do
    if [ -n "$line" ]; then
        PRINTER_LIST+=("$line")
    fi
done < <(lpstat -e 2>/dev/null)

SELECTED_PRINTER=""
if [ ${#PRINTER_LIST[@]} -eq 0 ]; then
    echo "CẢNH BÁO: Hiện tại hệ thống CUPS chưa có máy in nào được cấu hình."
    echo "Bạn có thể cấu hình máy in sau. Xem hướng dẫn tại giao diện web CUPS: http://localhost:631"
    read -p "Nhập tên máy in muốn sử dụng (để trống nếu sử dụng máy in mặc định): " SELECTED_PRINTER < /dev/tty
else
    echo "Tìm thấy danh sách các máy in sau:"
    echo "0) Sử dụng máy in mặc định của hệ thống"
    for i in "${!PRINTER_LIST[@]}"; do
        echo "$((i+1))) ${PRINTER_LIST[$i]}"
    done
    
    while true; do
        read -p "Chọn số thứ tự máy in muốn cấu hình (0-${#PRINTER_LIST[@]}) [Mặc định: 0]: " PRINTER_CHOICE < /dev/tty
        PRINTER_CHOICE=${PRINTER_CHOICE:-0}
        
        if [ "$PRINTER_CHOICE" -eq 0 ]; then
            SELECTED_PRINTER=""
            echo "Đã chọn: Máy in mặc định"
            break
        elif [[ "$PRINTER_CHOICE" =~ ^[0-9]+$ ]] && [ "$PRINTER_CHOICE" -le ${#PRINTER_LIST[@]} ]; then
            SELECTED_PRINTER="${PRINTER_LIST[$((PRINTER_CHOICE-1))]}"
            echo "Đã chọn máy in: $SELECTED_PRINTER"
            break
        else
            echo "Lựa chọn không hợp lệ. Vui lòng chọn lại."
        fi
    done
fi
echo

# 3. Cấu hình thời gian chạy lịch in tự động
echo ">>> Bước 3: Lên lịch thời gian in tự động..."
while true; do
    read -p "Nhập giờ muốn in (0-23) [Mặc định: 8]: " INPUT_HOUR < /dev/tty
    INPUT_HOUR=${INPUT_HOUR:-8}
    if [[ "$INPUT_HOUR" =~ ^[0-9]+$ ]] && [ "$INPUT_HOUR" -ge 0 ] && [ "$INPUT_HOUR" -le 23 ]; then
        HOUR=$INPUT_HOUR
        break
    else
        echo "Giờ không hợp lệ (phải từ 0 đến 23). Vui lòng nhập lại."
    fi
done

while true; do
    read -p "Nhập phút muốn in (0-59) [Mặc định: 0]: " INPUT_MIN < /dev/tty
    INPUT_MIN=${INPUT_MIN:-0}
    if [[ "$INPUT_MIN" =~ ^[0-9]+$ ]] && [ "$INPUT_MIN" -ge 0 ] && [ "$INPUT_MIN" -le 59 ]; then
        MIN=$INPUT_MIN
        break
    else
        echo "Phút không hợp lệ (phải từ 0 đến 59). Vui lòng nhập lại."
    fi
done

echo "Chọn các ngày trong tuần bạn muốn in:"
echo "1) Hàng ngày"
echo "2) Các ngày làm việc (Thứ 2 đến Thứ 6)"
echo "3) Ngày cuối tuần (Thứ 7 & Chủ Nhật)"
echo "4) Lựa chọn ngày cụ thể"
while true; do
    read -p "Nhập lựa chọn của bạn (1-4) [Mặc định: 1]: " DAY_CHOICE < /dev/tty
    DAY_CHOICE=${DAY_CHOICE:-1}
    
    case "$DAY_CHOICE" in
        1)
            CRON_DAYS="*"
            DAY_DESC="Hàng ngày"
            break
            ;;
        2)
            CRON_DAYS="1-5"
            DAY_DESC="Từ Thứ 2 đến Thứ 6"
            break
            ;;
        3)
            CRON_DAYS="6,0"
            DAY_DESC="Thứ 7 và Chủ Nhật"
            break
            ;;
        4)
            echo "Nhập danh sách ngày cách nhau bằng dấu phẩy:"
            echo "  1: Thứ 2, 2: Thứ 3, 3: Thứ 4, 4: Thứ 5, 5: Thứ 6, 6: Thứ 7, 0: Chủ Nhật"
            read -p "Ví dụ (1,3,5 - Thứ 2, 4, 6): " CUSTOM_DAYS < /dev/tty
            if [[ "$CUSTOM_DAYS" =~ ^[0-6](,[0-6])*$ ]]; then
                CRON_DAYS="$CUSTOM_DAYS"
                DAY_DESC="Các ngày cụ thể ($CRON_DAYS)"
                break
            else
                echo "Định dạng không hợp lệ. Ví dụ đúng: 1,3,5"
            fi
            ;;
        *)
            echo "Lựa chọn không hợp lệ. Vui lòng nhập số từ 1 đến 4."
            ;;
    esac
done
echo "Đã lên lịch in vào lúc: $(printf "%02d" $HOUR):$(printf "%02d" $MIN) - Lịch: $DAY_DESC."
echo

# 4. Tạo thư mục và ghi file PDF
echo ">>> Bước 4: Tạo thư mục lưu trữ và giải nén file PDF..."
INSTALL_DIR="/opt/print-automation"
mkdir -p "$INSTALL_DIR"

PDF_PATH="$INSTALL_DIR/color-test-page.pdf"
echo "Đang trích xuất file PDF..."

cat << 'EOF' | base64 -d > "$PDF_PATH"
__PDF_BASE64__
EOF

if [ -f "$PDF_PATH" ]; then
    echo "Đã trích xuất thành công file PDF tại $PDF_PATH"
else
    echo "LỖI: Trích xuất file PDF thất bại!" >&2
    exit 1
fi
echo

# 5. Tạo script in phụ trợ ghi log
echo ">>> Bước 5: Tạo script in và thiết lập ghi nhật ký (Log)..."
JOB_SCRIPT="$INSTALL_DIR/print-job.sh"

cat << EOF > "$JOB_SCRIPT"
#!/usr/bin/env bash
# Script tự động thực hiện in file PDF
LOG_FILE="/var/log/print-automation.log"
PDF_FILE="$PDF_PATH"
PRINTER_NAME="$SELECTED_PRINTER"

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "[\$(date '+%Y-%m-%d %H:%M:%S')] Bắt đầu tiến trình in..." >> "\$LOG_FILE"

if [ ! -f "\$PDF_FILE" ]; then
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] LỖI: Không tìm thấy file PDF tại \$PDF_FILE" >> "\$LOG_FILE"
    exit 1
fi

# Thực thi lệnh in
if [ -z "\$PRINTER_NAME" ]; then
    PRINT_OUTPUT=\$(lp "\$PDF_FILE" 2>&1)
    STATUS=\$?
else
    PRINT_OUTPUT=\$(lp -d "\$PRINTER_NAME" "\$PDF_FILE" 2>&1)
    STATUS=\$?
fi

if [ \$STATUS -eq 0 ]; then
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] THÀNH CÔNG: Đã gửi lệnh in. Chi tiết: \$PRINT_OUTPUT" >> "\$LOG_FILE"
else
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] THẤT BẠI: Lỗi khi in. Chi tiết: \$PRINT_OUTPUT" >> "\$LOG_FILE"
fi
EOF

chmod +x "$JOB_SCRIPT"
echo "Đã tạo script in tại: $JOB_SCRIPT"
echo

# 6. Đăng ký lịch Cron Job
echo ">>> Bước 6: Cấu hình lịch tự động chạy (Cron Job)..."
CRON_FILE="/etc/cron.d/print-automation"

# Ghi cấu hình Cron Job chạy dưới quyền root
echo "$MIN $HOUR * * $CRON_DAYS root $JOB_SCRIPT > /dev/null 2>&1" > "$CRON_FILE"

# Quyền hạn cực kỳ quan trọng cho file trong /etc/cron.d/
chmod 644 "$CRON_FILE"
chown root:root "$CRON_FILE"

# Khởi động lại dịch vụ cron để cập nhật cấu hình mới
systemctl restart cron || true

echo "Đã đăng ký lịch Cron Job thành công tại $CRON_FILE!"
echo "Lịch biểu chạy Cron: $MIN $HOUR * * $CRON_DAYS"
echo

# 7. In thử nghiệm (Tùy chọn)
echo "======================================================================"
echo "    CÀI ĐẶT HOÀN TẤT!"
echo "======================================================================"
echo "Máy in đã cấu hình: ${SELECTED_PRINTER:-'(Máy in mặc định của hệ thống)'}"
echo "Thời gian in: $(printf "%02d" $HOUR):$(printf "%02d" $MIN) - Lịch: $DAY_DESC"
echo "Nhật ký in (log) sẽ được lưu tại: /var/log/print-automation.log"
echo "----------------------------------------------------------------------"
echo

read -p "Bạn có muốn thực hiện in thử một bản ngay bây giờ không? (y/n) [Mặc định: n]: " TEST_PRINT < /dev/tty
TEST_PRINT=${TEST_PRINT:-n}

if [[ "$TEST_PRINT" =~ ^[yY](e[sS])?$ ]]; then
    echo "Đang tiến hành in thử..."
    bash "$JOB_SCRIPT"
    echo "Đã gửi lệnh in thử. Bạn có thể kiểm tra log bằng lệnh:"
    echo "cat /var/log/print-automation.log"
else
    echo "Đã bỏ qua in thử."
fi

echo
echo "Cảm ơn bạn đã sử dụng bộ cài đặt tự động in!"
