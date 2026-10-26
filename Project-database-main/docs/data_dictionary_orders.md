# TỪ ĐIỂN DỮ LIỆU PHÂN HỆ ĐƠN HÀNG TRUNG TÂM (DATA DICTIONARY)

* **Dự án**: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
* **Học phần**: Cơ sở dữ liệu
* **Phân hệ**: Đơn hàng trung tâm & Chi tiết món ăn (Order Subsystem)
* **Sinh viên phụ trách**: SV1 — Bùi Duy Quang (Nhóm trưởng)
* **Hệ quản trị CSDL mục tiêu**: PostgreSQL 14+ / 15 / 16
* **Danh mục bảng**:
  1. `orders` — Bảng đơn hàng trung tâm kết nối các tác nhân
  2. `order_items` — Chi tiết từng món ăn trong đơn kèm snapshot giá lịch sử
  3. `order_item_options` — Tùy chọn topping, kích cỡ kèm phụ thu snapshot

---

## 1. BẢNG `orders` (Đơn hàng trung tâm)

### 1.1. Bảng cấu trúc thuộc tính

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Ràng buộc | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `order_id` | `BIGINT` | **PK** | NOT NULL | YES | *Generated Always as Identity* | | Mã định danh duy nhất của đơn hàng toàn sàn |
| `order_code` | `VARCHAR(32)` | | NOT NULL | YES | | | Mã đơn hiển thị cho khách và shipper (VD: `ORD-20261026-0001`) |
| `customer_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `customers(customer_id)` | Mã khách hàng đặt đơn (SV1) |
| `branch_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `branches(branch_id)` | Chi nhánh quán nhận nấu món (SV2) |
| `driver_id` | `BIGINT` | **FK** | NULL | NO | NULL | Tham chiếu `drivers(driver_id)` | Mã tài xế nhận cuốc (SV3), cho phép NULL khi đơn mới tạo |
| `delivery_address_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `customer_addresses(address_id)` | Địa chỉ giao hàng cụ thể của khách |
| `order_status` | `VARCHAR(30)` | | NOT NULL | NO | `'PENDING'` | `IN ('PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'DELIVERED', 'CANCELLED')` | [BR04] Trạng thái theo máy trạng thái DoorDash |
| `payment_status` | `VARCHAR(20)` | | NOT NULL | NO | `'UNPAID'` | `IN ('UNPAID', 'AUTHORIZED', 'PAID', 'REFUNDED')` | Trạng thái thanh toán của đơn |
| `subtotal_amount` | `DECIMAL(12, 2)` | | NOT NULL | NO | `0.00` | `>= 0` | Tổng giá trị các món ăn trước phụ phí và giảm giá |
| `delivery_fee` | `DECIMAL(10, 2)` | | NOT NULL | NO | `0.00` | `>= 0` | Phí vận chuyển tính theo khoảng cách địa lý (GIS) |
| `service_fee` | `DECIMAL(10, 2)` | | NOT NULL | NO | `0.00` | `>= 0` | Phí dịch vụ nền tảng sàn thu |
| `discount_amount` | `DECIMAL(10, 2)` | | NOT NULL | NO | `0.00` | `>= 0` | Giá trị mã voucher khuyến mãi giảm giá |
| `total_amount` | `DECIMAL(12, 2)` | | NOT NULL | NO | `0.00` | `>= 0` | Số tiền thực tế khách cần thanh toán |
| `delivery_distance_km` | `DECIMAL(6, 2)` | | NULL | NO | NULL | | Khoảng cách từ chi nhánh đến nhà khách (km) |
| `driver_rating` | `SMALLINT` | | NULL | NO | NULL | `BETWEEN 1 AND 5` | Đánh giá thái độ tài xế (1 - 5 sao) |
| `restaurant_rating` | `SMALLINT` | | NULL | NO | NULL | `BETWEEN 1 AND 5` | Đánh giá chất lượng quán (1 - 5 sao) |
| `customer_note` | `TEXT` | | NULL | NO | NULL | | Ghi chú dặn dò của khách hàng khi đặt đơn |
| `cancel_reason` | `VARCHAR(255)` | | NULL | NO | NULL | | Lý do hủy đơn nếu đơn ở trạng thái `CANCELLED` |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm khách gửi đơn lên hệ thống |
| `updated_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm cập nhật trạng thái đơn gần nhất |

### 1.2. Quyết định thiết kế & Ràng buộc toàn vẹn
* **Kiểm soát đồng thời (ACID & Concurrency)**: Cột `order_status` tuân thủ quy tắc nghiệp vụ `BR04`. Đơn hàng chuyển tuần tự qua từng giai đoạn nhằm tránh xung đột giữa quán và tài xế.
* **Cơ chế tài chính độc lập**: Toàn bộ các trường tiền (`subtotal`, `delivery_fee`, `total_amount`) được lưu trữ dưới dạng `DECIMAL(12, 2)` cố định, không dùng `FLOAT` để tránh sai số dấu phẩy động trong kế toán.

---

## 2. BẢNG `order_items` (Chi tiết món ăn đặt hàng)

### 2.1. Bảng cấu trúc thuộc tính

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Ràng buộc | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `order_item_id` | `BIGINT` | **PK** | NOT NULL | YES | *Generated Always as Identity* | | Mã định danh bản ghi chi tiết món đặt |
| `order_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `orders(order_id)` ON DELETE CASCADE | Thuộc về đơn hàng nào |
| `item_id` | `BIGINT` | **FK** | NULL | NO | NULL | Tham chiếu `items(item_id)` ON DELETE SET NULL | Mã món gốc trong thực đơn của SV2 |
| `item_name_snapshot` | `VARCHAR(150)` | | NOT NULL | NO | | `LENGTH(TRIM(item_name_snapshot)) > 0` | [BR02] Tên món tại đúng thời điểm đặt hàng |
| `unit_price_snapshot` | `DECIMAL(10, 2)` | | NOT NULL | NO | | `>= 0` | [BR02] Đơn giá gốc của món tại thời điểm đặt |
| `quantity` | `INTEGER` | | NOT NULL | NO | `1` | `> 0` | Số lượng suất ăn khách đặt |
| `subtotal` | `DECIMAL(12, 2)` | | NOT NULL | NO | | `>= 0` | Thành tiền trước topping (`unit_price * quantity`) |
| `item_note` | `VARCHAR(255)` | | NULL | NO | NULL | | Ghi chú khẩu vị riêng cho món (VD: Ít cay, nhiều sốt) |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm thêm món vào đơn |

### 2.2. Quyết định thiết kế & Ràng buộc Snapshot
* **Hiện tượng trôi giá (Price Drift Protection - BR02)**: Nếu quán ăn tăng giá món `base_price` từ 50.000đ lên 60.000đ vào tuần sau, các đơn hàng quá khứ vẫn giữ nguyên giá mua là 50.000đ nhờ trường `unit_price_snapshot`. Cấm tuyệt đối việc join trực tiếp bảng `items` để tính lại tổng tiền đơn cũ.

---

## 3. BẢNG `order_item_options` (Tùy chọn Topping / Kích cỡ đính kèm món)

### 3.1. Bảng cấu trúc thuộc tính

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK / Ràng buộc | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `order_item_option_id` | `BIGINT` | **PK** | NOT NULL | YES | *Generated Always as Identity* | | Mã định danh duy nhất của tùy chọn đính kèm |
| `order_item_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `order_items(order_item_id)` ON DELETE CASCADE | Thuộc món ăn nào trong đơn hàng |
| `option_item_id` | `BIGINT` | **FK** | NULL | NO | NULL | Tham chiếu `option_items(option_item_id)` ON DELETE SET NULL | Mã tùy chọn gốc của SV2 |
| `option_name_snapshot` | `VARCHAR(100)` | | NOT NULL | NO | | `LENGTH(TRIM(option_name_snapshot)) > 0` | [BR02] Tên topping/kích cỡ tại thời điểm đặt |
| `extra_price_snapshot` | `DECIMAL(10, 2)` | | NOT NULL | NO | `0.00` | `>= 0` | [BR02] Phụ thu của topping tại thời điểm đặt |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm ghi nhận tùy chọn |

### 3.2. Quyết định thiết kế
* Quan hệ giữa `order_items` và `order_item_options` là quan hệ thành phần (Composition / Cascade Delete): Khi một món trong đơn bị hủy/xóa, toàn bộ danh sách topping gắn kèm món đó tự động bị xóa theo, đảm bảo không có bản ghi mồ côi (Orphan Records).
