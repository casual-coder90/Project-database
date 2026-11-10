# PHỤ LỤC KỸ THUẬT

## 1. Bổ sung từ điển dữ liệu

| Bảng.cột | Kiểu | NULL | Khóa/ràng buộc | Ý nghĩa |
|---|---|---:|---|---|
| orders.*_snapshot | varchar/text/decimal | Không | tọa độ có CHECK | Người nhận và địa chỉ bất biến tại lúc đặt |
| deliveries.order_id | bigint | Không | FK, UNIQUE | Một lần giao cho một đơn |
| deliveries.delivery_status | varchar(30) | Không | CHECK | Trạng thái giao, độc lập trạng thái đơn |
| delivery_assignments.delivery_id | bigint | Không | FK; partial UNIQUE khi `ended_at IS NULL` | Lịch sử phân công |
| delivery_assignments.driver_id | bigint | Không | FK | Tài xế được phân công |
| driver_location_history.captured_at | timestamptz | Không | UNIQUE cùng driver | Thời điểm thiết bị ghi nhận |
| driver_location_history.recorded_at | timestamptz | Không | DEFAULT | Thời điểm CSDL nhận dữ liệu |
| payments.order_id | bigint | Không | FK; partial UNIQUE khi SUCCESS | Cho phép nhiều lần thử |

## 2. Phụ thuộc hàm và chuẩn hóa

- `users`: `user_id →` mọi thuộc tính; `email → user_id`; `phone_number → user_id`.
- `customer_addresses`: `address_id →` mọi thuộc tính; partial key nghiệp vụ `(customer_id) → address_id` chỉ trong tập `is_default=true`.
- `restaurants`: `restaurant_id →` mọi thuộc tính. `branches`: `branch_id →` mọi thuộc tính.
- `categories`, `items`, `option_groups`, `option_items`: khóa chính tương ứng quyết định các thuộc tính còn lại.
- `orders`: `order_id →` mọi thuộc tính; `order_code → order_id`.
- `order_items`: `order_item_id →` mọi thuộc tính. Giá snapshot phụ thuộc dòng đơn, không phụ thuộc giá menu hiện tại.
- `deliveries`: `delivery_id ↔ order_id`; `delivery_assignments`: `assignment_id →` mọi thuộc tính.
- `payments`: `payment_id →` mọi thuộc tính; không có `order_id → payment_id` vì một đơn có nhiều lần thử.

Tất cả thuộc tính là nguyên tử (1NF); không có khóa ghép chứa phụ thuộc bộ phận (2NF); các phụ thuộc bắc cầu được tách thành quan hệ riêng (3NF). Các determinant liệt kê đều là candidate/superkey, nên các quan hệ trên đạt BCNF theo tập FD đã biết. Snapshot là phi chuẩn hóa có chủ đích nhằm bảo toàn hóa đơn lịch sử.

## 3. Ma trận truy vết

| Mã | Quy tắc | Bảng | Cơ chế | Test |
|---|---|---|---|---|
| BR02 | Giữ giá/tên lúc đặt | order_items, order_item_options | NOT NULL, snapshot | T07 |
| BR03 | Tối đa một địa chỉ mặc định | customer_addresses | partial UNIQUE | T02 |
| BR04 | Chuyển trạng thái hợp lệ | orders, order_status_logs | trigger | T05 |
| BR05 | Nhiều lần thử, một SUCCESS | payments | partial UNIQUE | T04 |
| BR06 | Tọa độ hợp lệ | branches, addresses, locations | CHECK | T01 |
| BR07 | Đúng khách và đơn DELIVERED mới review | reviews, orders | trigger + UNIQUE | T06 |
| BR08 | Món thuộc đúng chi nhánh | orders, items, branches | trigger | T03 |
| BR09 | Một phân công hiệu lực | delivery_assignments | partial UNIQUE | T08 |

## 4. Kế hoạch kiểm thử

- T01: chèn latitude 91, kỳ vọng CHECK từ chối.
- T02: tạo hai địa chỉ mặc định cùng khách, kỳ vọng unique violation.
- T03: thêm món của nhà hàng khác vào đơn, kỳ vọng trigger từ chối.
- T04: hai payment FAILED được phép; hai SUCCESS cùng đơn bị từ chối.
- T05: `PENDING → DELIVERED` bị từ chối; `PENDING → CONFIRMED` tạo log.
- T06: review đơn chưa giao hoặc sai khách bị từ chối.
- T07: đổi giá menu/địa chỉ nguồn, snapshot đơn cũ không đổi.
- T08: hai assignment có `ended_at IS NULL` cho cùng delivery bị từ chối.
- T09: truy vấn tổng đơn phải aggregate từng quan hệ 1–N trước khi join, không nhân tiền.

Trạng thái hiện hành: **đã chạy thành công trên MySQL 8.4.11/InnoDB ngày 10/11/2026**; dùng `sql/mysql_tests.sql` và `app/test/api.test.js`.

## 5. Phân công và tiến độ đề xuất

| Thành viên | Trách nhiệm giữ nguyên/mở rộng | Đầu ra | Tiêu chí hoàn thành |
|---|---|---|---|
| Bùi Duy Quang | DRS, user/order, báo cáo tuần, rà soát menu | DRS + order queries + log cross-test | Mã BR có test, tên khớp SQL |
| Phạm Đình Phúc | menu, FD/3NF, seed, rà soát vận hành | normalization + seed | seed đúng FK; giải thích FD |
| Lương Công Phi | driver/payment/GIS, tích hợp, rà soát user/order | master SQL + test log | chạy sạch MySQL 8.4/InnoDB |

Phần ứng dụng bổ sung: Bùi Duy Quang phụ trách luồng khách hàng/theo dõi và cập nhật báo cáo; Phạm Đình Phúc phụ trách giao diện menu/nhà hàng, kiểm tra giá và dữ liệu mẫu; Lương Công Phi phụ trách API transaction, điều phối/tài xế, Docker và kiểm thử E2E. Cả ba rà soát chéo theo ma trận cũ.

Lịch dưới đây là **đề xuất**, không phải tiến độ đã xảy ra: Tuần 1 xác nhận yêu cầu/mẫu; tuần 2 chốt ER/EER; tuần 3 lược đồ và 3NF; tuần 4 DDL/seed; tuần 5 negative tests và truy vấn; tuần 6 đóng báo cáo/demo. Cross-review giữ như bản Word: SV1→SV2, SV2→SV3, SV3→SV1.
