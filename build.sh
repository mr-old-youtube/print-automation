#!/usr/bin/env bash

# ==============================================================================
# SCRIPT ĐÓNG GÓI SETUP.SH (PRINT AUTOMATION BUILDER)
# ==============================================================================
# Chuyển đổi color-test-page.pdf thành Base64 và chèn vào setup_template.sh
# Kết quả sẽ sinh ra file setup.sh tự chạy duy nhất.
# ==============================================================================

set -e

echo "======================================================================"
echo "    BẮT ĐẦU ĐÓNG GÓI SETUP.SH"
echo "======================================================================"

PDF_FILE="color-test-page.pdf"
TEMPLATE_FILE="setup_template.sh"
OUTPUT_FILE="setup.sh"

# Kiểm tra sự tồn tại của file PDF
if [ ! -f "$PDF_FILE" ]; then
    echo "LỖI: Không tìm thấy file '$PDF_FILE' trong thư mục hiện tại!" >&2
    exit 1
fi

# Kiểm tra sự tồn tại của file template
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "LỖI: Không tìm thấy file '$TEMPLATE_FILE'!" >&2
    exit 1
fi

echo "1. Đang chuyển đổi file PDF sang dạng Base64..."
# Tạo dữ liệu base64 tạm thời
base64 < "$PDF_FILE" > temp_pdf.b64

echo "2. Đang tạo file cài đặt tích hợp '$OUTPUT_FILE'..."
# Thay thế placeholder bằng Python để tối ưu hóa hiệu suất và tránh lỗi độ dài tham số dòng lệnh
if command -v python3 &>/dev/null; then
    python3 -c "
with open('$TEMPLATE_FILE', 'r', encoding='utf-8') as f:
    template = f.read()
with open('temp_pdf.b64', 'r', encoding='utf-8') as f:
    b64_content = f.read()
output = template.replace('__PDF_BASE64__', b64_content)
with open('$OUTPUT_FILE', 'w', encoding='utf-8') as f:
    f.write(output)
"
else
    echo "Cảnh báo: Không tìm thấy python3. Đang cố gắng sử dụng perl..."
    if command -v perl &>/dev/null; then
        perl -pe 'BEGIN{open(F,"temp_pdf.b64"); $b=join("",<F>); close(F)} s/__PDF_BASE64__/$b/g' "$TEMPLATE_FILE" > "$OUTPUT_FILE"
    else
        echo "LỖI: Máy tính cần cài đặt python3 hoặc perl để thực hiện đóng gói." >&2
        rm -f temp_pdf.b64
        exit 1
    fi
fi

# Xóa file tạm
rm -f temp_pdf.b64

# Gán quyền thực thi cho setup.sh
chmod +x "$OUTPUT_FILE"

echo "======================================================================"
echo "    ĐÓNG GÓI HOÀN TẤT!"
echo "======================================================================"
echo "Đã tạo thành công file: $OUTPUT_FILE"
echo "Cách sử dụng:"
echo "1. Upload file '$OUTPUT_FILE' lên hosting/server của bạn."
echo "2. Người dùng cuối chỉ cần chạy câu lệnh sau trên máy Debian:"
echo "   curl -fsSL https://<HOST_CUA_BAN>/$OUTPUT_FILE | sudo bash"
echo "======================================================================"
