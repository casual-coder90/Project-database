# KẾT QUẢ KIỂM CHỨNG

**Thời điểm:** 10/11/2026 (Asia/Saigon)  
**Môi trường hiện hành:** Docker image `mysql:8.4`, MySQL 8.4.11, InnoDB, CSDL `food_delivery_db`  
**Lệnh:** chạy `sql/mysql_schema.sql`, `sql/demo_seed.sql`, `sql/mysql_tests.sql` và test API.

| Hạng mục | Kết quả |
|---|---|
| Tạo schema và seed | PASS, 24 bảng |
| Trigger được cài | 7 trigger |
| T01 tọa độ ngoài miền | PASS |
| T02 hai địa chỉ mặc định | PASS |
| T03 món sai chi nhánh | PASS |
| T04 hai payment SUCCESS | PASS |
| T05 chuyển trạng thái sai | PASS |
| T06 đánh giá sai khách | PASS |
| T07 snapshot bất biến | PASS |
| T08 hai phân công active | PASS |
| T09 tổng không bị nhân do join | PASS: total 100000, paid 100000 |

Container đã được dừng và xóa sau kiểm thử. Chưa đo hiệu năng với dữ liệu lớn, chưa kiểm thử concurrent race, PostGIS, quyền production hoặc khôi phục backup; đây là các phần chưa kiểm chứng.

## Kiểm chứng web tối giản trên MySQL — 10/11/2026

- Docker Compose khởi động MySQL 8.4.11/InnoDB và Node.js; trang chính trả HTTP 200.
- Luồng API đặt đơn → xác nhận → chế biến → sẵn sàng → phân công → lấy món → ghi tọa độ → giao thành công: PASS.
- Kết quả CSDL: `orders=DELIVERED`, `deliveries=DELIVERED`, COD `SUCCESS`, 6 mốc trạng thái, có lịch sử phân công và vị trí.
- Số lượng bằng 0 và `DELIVERED → CONFIRMED` đều bị từ chối: PASS.
- Chạy `demo_seed.sql` hai lần không đổi số lượng: 6 users, 2 branches, 2 items, 3 drivers.
- Restart container web rồi tra mã đơn cũ vẫn trả đầy đủ dữ liệu: PASS; dữ liệu nằm trong MySQL, không nằm trong bộ nhớ web/localStorage.
- Backend dùng prepared placeholders `?` của `mysql2`; không ghép input người dùng vào SQL.

Metadata xác nhận: 24 bảng dùng InnoDB; `@@default_storage_engine = InnoDB`. Seed chạy hai lần giữ nguyên 6 users, 2 branches, 2 items và 3 drivers.

Negative test trực tiếp MySQL: tọa độ latitude 91 bị CHECK từ chối; payment `SUCCESS` thứ hai bị `uq_one_success` từ chối; dòng món không hợp lệ bị trigger chi nhánh từ chối. API riêng xác nhận quantity 0 và chuyển `DELIVERED → CONFIRMED` bị HTTP 400.
