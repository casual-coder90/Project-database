# TỪ ĐIỂN DỮ LIỆU PHÂN HỆ VẬN HÀNH, THANH TOÁN & ĐÁNH GIÁ (SV3)

* **Dự án**: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
* **Học phần**: Cơ sở dữ liệu
* **Phân hệ**: Vận hành, Kỹ thuật GIS, Thanh toán & Đánh giá (Operations Subsystem)
* **Sinh viên phụ trách**: SV3 — Lương Công Phi
* **Hệ quản trị CSDL mục tiêu**: PostgreSQL 14+ / 15 / 16
* **Danh mục 8 bảng**:
  1. `drivers` — Phân lớp tài xế giao vận (kế thừa từ `users`)
  2. `payments` — Siêu lớp thanh toán kế toán của đơn hàng
  3. `cash_payments` — Phân lớp thanh toán tiền mặt (COD)
  4. `card_payments` — Phân lớp thanh toán thẻ ngân hàng / quốc tế
  5. `ewallet_payments` — Phân lớp thanh toán ví điện tử tích hợp
  6. `order_status_logs` — Nhật ký dòng thời gian chuyển đổi trạng thái đơn
  7. `restaurant_reviews` — Phản hồi đánh giá nhà hàng từ khách hàng
  8. `driver_reviews` — Phản hồi đánh giá tài xế từ khách hàng

---

## 1. BẢNG `drivers` (Phân lớp đối tác tài xế giao hàng)

### 1.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Validation | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `driver_id` | `BIGINT` | **PK, FK** | NOT NULL | YES | | Tham chiếu `users(user_id)` | Khóa chính và Khóa ngoại kế thừa từ tài khoản định danh |
| `license_number` | `VARCHAR(50)` | | NOT NULL | YES | | `LENGTH(TRIM(license_number)) > 0` | Số giấy phép lái xe (GPLX) duy nhất |
| `vehicle_type` | `VARCHAR(20)` | | NOT NULL | NO | | `IN ('MOTORBIKE', 'ELECTRIC_BIKE', 'CAR')` | Loại phương tiện giao hàng đăng ký |
| `vehicle_plate` | `VARCHAR(20)` | | NOT NULL | YES | | `LENGTH(TRIM(vehicle_plate)) > 0` | Biển số kiểm soát phương tiện |
| `current_lat` | `DECIMAL(10, 8)` | | NULL | NO | NULL | `BETWEEN -90.0 AND 90.0` | Tọa độ vĩ độ thời gian thực của tài xế |
| `current_long` | `DECIMAL(11, 8)` | | NULL | NO | NULL | `BETWEEN -180.0 AND 180.0` | Tọa độ kinh độ thời gian thực của tài xế |
| `driver_status` | `VARCHAR(20)` | | NOT NULL | NO | `'OFFLINE'` | `IN ('OFFLINE', 'AVAILABLE', 'DELIVERING')` | Trạng thái sẵn sàng nhận cuốc xe |
| `is_active` | `BOOLEAN` | | NOT NULL | NO | `TRUE` | | Trạng thái kích hoạt hồ sơ tài xế |
| `rating_average` | `DECIMAL(3, 2)` | | NOT NULL | NO | `5.00` | `BETWEEN 1.00 AND 5.00` | Điểm đánh giá sao trung bình tích lũy |
| `total_trips` | `INTEGER` | | NOT NULL | NO | `0` | `>= 0` | Tổng số đơn hàng đã giao thành công |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm đăng ký đối tác tài xế |
| `updated_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm cập nhật trạng thái/tọa độ gần nhất |

### 1.2. Giải thích thiết kế & Tính thực dụng
* **Mô hình chuyên biệt hóa (Specialization)**: `driver_id` đóng vai trò đồng thời là PK và FK tham chiếu `users(user_id)` với hành vi `ON DELETE CASCADE ON UPDATE CASCADE`. Điều này hiện thực hóa đúng ràng buộc Disjoint/Total từ `DRS.md`.
* **Quản lý tọa độ `current_lat`, `current_long`**: Cho phép `NULL` khi tài xế vừa cài app hoặc đang `OFFLINE` chưa cấp quyền vị trí GPS. Khi bật sang `AVAILABLE`, ứng dụng client cập nhật tọa độ vào CSDL để phục vụ câu truy vấn Spatial Dispatching.

---

## 2. BẢNG `payments` (Siêu lớp thanh toán kế toán đơn hàng)

### 2.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Validation | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `payment_id` | `BIGINT` | **PK** | NOT NULL | YES | *Identity* | | Mã định danh duy nhất của giao dịch thanh toán |
| `order_id` | `BIGINT` | **FK** | NOT NULL | YES | | Tham chiếu `orders(order_id)` | Đơn hàng phát sinh giao dịch thanh toán |
| `amount` | `DECIMAL(12, 2)` | | NOT NULL | NO | | `>= 0.00` | Tổng số tiền thanh toán thực tế (VNĐ) |
| `payment_method` | `VARCHAR(20)` | | NOT NULL | NO | | `IN ('CASH', 'CARD', 'EWALLET')` | Cờ phân loại siêu lớp (Disjoint discriminator) |
| `payment_status` | `VARCHAR(20)` | | NOT NULL | NO | `'PENDING'` | `IN ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED')` | Trạng thái giao dịch tài chính |
| `paid_at` | `TIMESTAMPTZ` | | NULL | NO | NULL | | Thời điểm giao dịch hoàn tất thành công |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm tạo yêu cầu thanh toán |

### 2.2. Giải thích thiết kế & Ràng buộc [BR05]
* **Quan hệ 1-1 với `orders`**: Theo quy định `BR05` trong `DRS.md`, mỗi đơn hàng tương ứng với một bản ghi thanh toán kế toán chính thức (`order_id` có ràng buộc `UNIQUE`).
* **Hành vi tham chiếu**: `ON DELETE RESTRICT ON UPDATE CASCADE` nhằm bảo vệ dữ liệu kế toán, không cho phép xóa đơn hàng khi đã có giao dịch thanh toán ghi nhận.

---

## 3. BẢNG `cash_payments` (Phân lớp thanh toán tiền mặt - COD)

### 3.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Validation | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `payment_id` | `BIGINT` | **PK, FK** | NOT NULL | YES | | Tham chiếu `payments(payment_id)` | Khóa chính và ngoại tham chiếu siêu lớp |
| `change_amount_for` | `DECIMAL(12, 2)` | | NULL | NO | NULL | `>= 0.00` | Số tiền khách chuẩn bị (để tài xế mang sẵn tiền thối) |

### 3.2. Giải thích thiết kế
* Nếu `change_amount_for IS NULL`, nghĩa là khách trả vừa đúng số tiền đơn hàng. Nếu khách nhập số tiền (ví dụ đơn 160.000đ nhưng khách chọn mang tờ 500.000đ), tài xế sẽ biết trước để chuẩn bị 340.000đ tiền thối.

---

## 4. BẢNG `card_payments` (Phân lớp thanh toán thẻ ngân hàng / quốc tế)

### 4.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Validation | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `payment_id` | `BIGINT` | **PK, FK** | NOT NULL | YES | | Tham chiếu `payments(payment_id)` | Khóa chính và ngoại tham chiếu siêu lớp |
| `card_last4` | `VARCHAR(4)` | | NOT NULL | NO | | `~ '^[0-9]{4}$'` | 4 chữ số cuối cùng của thẻ (In trên hóa đơn) |
| `card_brand` | `VARCHAR(20)` | | NOT NULL | NO | | `IN ('VISA', 'MASTERCARD', 'JCB', 'NAPAS')` | Tổ chức phát hành thẻ |
| `transaction_ref` | `VARCHAR(100)` | | NOT NULL | YES | | `LENGTH(TRIM(transaction_ref)) > 0` | Mã giao dịch từ cổng thanh toán đối tác |

### 4.2. Bảo mật chuẩn PCI DSS
* **Tuyệt đối cấm lưu trữ**: Số thẻ đầy đủ 16 chữ số (`PAN`), ngày hết hạn đầy đủ, và mã số bảo mật `CVV/CVC`. Việc chỉ lưu 4 số cuối (`card_last4`) vừa đảm bảo hiển thị đối soát cho khách, vừa tuân thủ tuyệt đối chuẩn an toàn dữ liệu thanh toán quốc tế.

---

## 5. BẢNG `ewallet_payments` (Phân lớp thanh toán ví điện tử tích hợp)

### 5.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Validation | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `payment_id` | `BIGINT` | **PK, FK** | NOT NULL | YES | | Tham chiếu `payments(payment_id)` | Khóa chính và ngoại tham chiếu siêu lớp |
| `wallet_provider` | `VARCHAR(20)` | | NOT NULL | NO | | `IN ('MOMO', 'ZALOPAY', 'SHOPEEPAY')` | Nhà cung cấp ví trung gian |
| `wallet_transaction_id` | `VARCHAR(100)` | | NOT NULL | YES | | `LENGTH(TRIM(wallet_transaction_id)) > 0` | Mã giao dịch đối soát do đối tác ví cấp |

---

## 6. BẢNG `order_status_logs` (Nhật ký dòng thời gian trạng thái đơn)

### 6.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Validation | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `log_id` | `BIGINT` | **PK** | NOT NULL | YES | *Identity* | | Mã định danh bản ghi nhật ký kiểm toán |
| `order_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `orders(order_id)` | Đơn hàng được cập nhật trạng thái |
| `previous_status` | `VARCHAR(30)` | | NULL | NO | NULL | | Trạng thái trước khi chuyển đổi |
| `new_status` | `VARCHAR(30)` | | NOT NULL | NO | | `IN ('PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'DELIVERED', 'CANCELLED')` | Trạng thái mới sau khi chuyển đổi |
| `changed_by_user_id` | `BIGINT` | **FK** | NULL | NO | NULL | Tham chiếu `users(user_id)` | Người thực hiện thao tác (Quán, Khách, Tài xế, Hệ thống) |
| `note` | `TEXT` | | NULL | NO | NULL | | Ghi chú lý do chuyển đổi hoặc lý do hủy đơn |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Mốc thời gian ghi nhận thay đổi |

### 6.2. Giải thích thiết kế & Ràng buộc [BR04]
* Quản lý máy trạng thái (State Machine): Bảng này cho phép trích xuất lịch sử xử lý đơn hàng chi tiết từng phút, phục vụ đối soát SLA giao hàng và giải quyết khiếu nại.
* Khóa ngoại `changed_by_user_id` dùng `ON DELETE SET NULL` để giữ lại nhật ký đơn hàng ngay cả khi tài khoản nhân viên/người dùng bị xóa.

---

## 7. BẢNG `restaurant_reviews` (Đánh giá nhà hàng từ khách hàng)

### 7.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Validation | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `review_id` | `BIGINT` | **PK** | NOT NULL | YES | *Identity* | | Mã định danh bản ghi đánh giá |
| `order_id` | `BIGINT` | **FK** | NOT NULL | YES | | Tham chiếu `orders(order_id)` | Đơn hàng đã giao thành công được đánh giá |
| `customer_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `customers(customer_id)` | Khách hàng thực hiện viết đánh giá |
| `restaurant_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `restaurants(restaurant_id)` | Thương hiệu nhà hàng được đánh giá |
| `rating` | `SMALLINT` | | NOT NULL | NO | | `BETWEEN 1 AND 5` | Điểm đánh giá số sao từ 1 đến 5 sao |
| `comment` | `TEXT` | | NULL | NO | NULL | | Lời nhận xét chi tiết của khách hàng |
| `reply_from_merchant`| `TEXT` | | NULL | NO | NULL | | Phản hồi của chủ quán gửi đến khách |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm gửi đánh giá |

### 7.2. Ràng buộc nghiệp vụ [BR07]
* Ràng buộc duy nhất `order_id UNIQUE`: Đảm bảo một đơn hàng chỉ được phép đánh giá chất lượng quán **tối đa đúng 1 lần**, ngăn chặn spam đánh giá ảo.

---

## 8. BẢNG `driver_reviews` (Đánh giá tài xế từ khách hàng)

### 8.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Validation | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `review_id` | `BIGINT` | **PK** | NOT NULL | YES | *Identity* | | Mã định danh đánh giá tài xế |
| `order_id` | `BIGINT` | **FK** | NOT NULL | YES | | Tham chiếu `orders(order_id)` | Đơn hàng đã giao thành công |
| `customer_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `customers(customer_id)` | Khách hàng thực hiện viết đánh giá |
| `driver_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `drivers(driver_id)` | Tài xế trực tiếp phụ trách giao đơn |
| `rating` | `SMALLINT` | | NOT NULL | NO | | `BETWEEN 1 AND 5` | Điểm đánh giá số sao thái độ tài xế |
| `comment` | `TEXT` | | NULL | NO | NULL | | Bình luận nhận xét về tài xế |
| `tipping_amount` | `DECIMAL(12, 2)` | | NOT NULL | NO | `0.00` | `>= 0.00` | Tiền boa (Tip) thưởng thêm cho tài xế |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm gửi đánh giá |

### 8.2. Ràng buộc nghiệp vụ [BR07]
* Ràng buộc duy nhất `order_id UNIQUE`: Một đơn hàng chỉ được đánh giá tài xế 1 lần.
* Ràng buộc tiền boa `tipping_amount >= 0.00`: Cho phép khách boa thêm tiền cho tài xế phục vụ nhiệt tình.

---

## 9. BẢNG TỔNG HỢP QUAN HỆ KHÓA NGOẠI (REFERENTIAL INTEGRITY MATRIX)

| Bảng con | Cột khóa ngoại | Bảng cha tham chiếu | Khóa chính cha | ON DELETE | ON UPDATE | Ghi chú nghiệp vụ |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `drivers` | `driver_id` | `users` (SV1) | `user_id` | **CASCADE** | **CASCADE** | Xóa user thì xóa hồ sơ tài xế |
| `payments` | `order_id` | `orders` (SV1) | `order_id` | **RESTRICT** | **CASCADE** | Không cho xóa đơn hàng khi đã có thanh toán |
| `cash_payments` | `payment_id` | `payments` | `payment_id` | **CASCADE** | **CASCADE** | Xóa payment cha thì xóa phân lớp |
| `card_payments` | `payment_id` | `payments` | `payment_id` | **CASCADE** | **CASCADE** | Xóa payment cha thì xóa phân lớp |
| `ewallet_payments` | `payment_id` | `payments` | `payment_id` | **CASCADE** | **CASCADE** | Xóa payment cha thì xóa phân lớp |
| `order_status_logs` | `order_id` | `orders` (SV1) | `order_id` | **CASCADE** | **CASCADE** | Xóa đơn hàng thì dọn dẹp nhật ký trạng thái |
| `order_status_logs` | `changed_by_user_id`| `users` (SV1) | `user_id` | **SET NULL** | **CASCADE** | Giữ lại lịch sử log kể cả khi tài khoản bị xóa |
| `restaurant_reviews`| `order_id` | `orders` (SV1) | `order_id` | **RESTRICT** | **CASCADE** | Bảo vệ dữ liệu đánh giá đơn hàng |
| `restaurant_reviews`| `customer_id` | `customers` (SV1) | `customer_id` | **CASCADE** | **CASCADE** | Liên kết với khách hàng viết bài |
| `restaurant_reviews`| `restaurant_id` | `restaurants` (SV2) | `restaurant_id` | **CASCADE** | **CASCADE** | Liên kết nhà hàng nhận đánh giá |
| `driver_reviews` | `order_id` | `orders` (SV1) | `order_id` | **RESTRICT** | **CASCADE** | Bảo vệ dữ liệu đánh giá đơn hàng |
| `driver_reviews` | `customer_id` | `customers` (SV1) | `customer_id` | **CASCADE** | **CASCADE** | Liên kết với khách hàng viết bài |
| `driver_reviews` | `driver_id` | `drivers` (SV3) | `driver_id` | **CASCADE** | **CASCADE** | Liên kết tài xế nhận đánh giá |
