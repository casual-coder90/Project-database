# KỊCH BẢN DEMO ỨNG DỤNG

1. Chạy `docker compose up --build`, mở `http://localhost:3000`.
2. Chọn tài khoản mẫu loại `CUSTOMER`, mở một chi nhánh, chọn số lượng món, nhập địa chỉ và đặt COD.
3. Ghi lại mã đơn hoặc mở tab Kiểm tra dữ liệu; kiểm tra trạng thái `PENDING`, giá và địa chỉ snapshot.
4. Chọn tài khoản `MERCHANT_OWNER` Bùi Thị Thu Hương, vào Đơn hàng; lần lượt bấm Xác nhận, Bắt đầu chế biến, Sẵn sàng bàn giao.
5. Chọn tài xế `AVAILABLE` và bấm Phân công.
6. Chuyển sang đúng tài khoản `DRIVER`, bấm Đã lấy món.
7. Bấm Mô phỏng vị trí. Đây là tọa độ mẫu, không phải GPS thật.
8. Bấm Giao thành công. Trong tab Kiểm tra dữ liệu, tra theo mã đơn và xác nhận sáu trạng thái, lịch sử phân công/vị trí; COD trong CSDL chuyển `SUCCESS`.

Tài khoản mẫu chỉ là bộ chọn vai trò phục vụ thuyết trình, không phải cơ chế xác thực production.

## Kết quả kiểm thử ngày 10/11/2026

Chạy bằng Docker Compose với MySQL 8.4.11/InnoDB và web Node.js. Luồng E2E tạo đơn mới, kết thúc với `orders=DELIVERED`, `deliveries=DELIVERED`, `payments=SUCCESS`, 6 dòng lịch sử và 1 mẫu vị trí. Kiểm tra HTTP thành công; chưa thực hiện browser automation do môi trường không có công cụ trình duyệt/`open_in_codex`.
