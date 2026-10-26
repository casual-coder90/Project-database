# TỪ ĐIỂN DỮ LIỆU PHÂN HỆ NHÀ HÀNG & THỰC ĐƠN (DATA DICTIONARY)

* **Dự án**: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
* **Học phần**: Cơ sở dữ liệu
* **Phân hệ**: Nhà hàng, Chi nhánh & Thực đơn phân cấp
* **Sinh viên phụ trách**: SV2 — Phạm Đình Phúc
* **Hệ quản trị CSDL mục tiêu**: PostgreSQL 14+ / 15 / 16
* **Danh mục bảng**:
  1. `restaurants` — Thương hiệu nhà hàng đối tác
  2. `branches` — Chi nhánh thực tế của nhà hàng
  3. `categories` — Danh mục thực đơn món ăn
  4. `items` — Món ăn / đồ uống niêm yết
  5. `option_groups` — Nhóm tùy chọn gắn vào món
  6. `option_items` — Lựa chọn chi tiết kèm phụ thu

---

## 1. BẢNG `restaurants` (Thương hiệu nhà hàng đối tác)

### 1.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `restaurant_id` | `BIGINT` | **PK** | NOT NULL | YES | *Generated Always as Identity* | | Mã định danh duy nhất của thương hiệu nhà hàng |
| `owner_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `merchant_owners(merchant_owner_id)` | Mã định danh chủ quán đã xác thực KYC |
| `restaurant_name` | `VARCHAR(150)` | | NOT NULL | NO | | `LENGTH(TRIM(restaurant_name)) > 0` | Tên thương hiệu hiển thị trên ứng dụng |
| `cuisine_type` | `VARCHAR(100)` | | NOT NULL | NO | | `LENGTH(TRIM(cuisine_type)) > 0` | Thể loại ẩm thực chính (VD: Cơm tấm, Trà sữa, Món Hàn,...) |
| `description` | `TEXT` | | NULL | NO | NULL | | Giới thiệu ngắn về phong cách ẩm thực, câu chuyện thương hiệu |
| `logo_url` | `VARCHAR(500)` | | NULL | NO | NULL | | Đường dẫn URL hình ảnh logo của thương hiệu |
| `banner_url` | `VARCHAR(500)` | | NULL | NO | NULL | | Đường dẫn URL ảnh bìa trang nhà hàng |
| `is_active` | `BOOLEAN` | | NOT NULL | NO | `TRUE` | | Cờ trạng thái hợp tác (`TRUE`: Đang hoạt động, `FALSE`: Ngừng hợp tác/Khóa) |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm nhà hàng đăng ký vào nền tảng |
| `updated_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm cập nhật thông tin thương hiệu gần nhất |

### 1.2. Giải thích quyết định thiết kế
* **Kiểu `BIGINT Identity`**: Phù hợp cho sàn giao dịch quy mô lớn, tránh cạn kiệt giá trị của `INT (2 tỷ)`.
* **Khóa ngoại `owner_id`**: Tham chiếu bảng `merchant_owners(merchant_owner_id)` do SV1 quản lý với hành vi `ON DELETE RESTRICT ON UPDATE CASCADE`. Tránh việc xóa tài khoản chủ quán khi thương hiệu nhà hàng vẫn còn lịch sử giao dịch và đơn hàng.
* **Tách biệt `restaurants` và `branches`**: Thực hiện chuẩn hóa khi một thương hiệu ẩm thực có thể mở nhiều chi nhánh tại các quận khác nhau, cùng chia sẻ chung một bộ danh mục và thực đơn món ăn.

---

## 2. BẢNG `branches` (Chi nhánh thực tế của nhà hàng)

### 2.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `branch_id` | `BIGINT` | **PK** | NOT NULL | YES | *Generated Always as Identity* | | Mã định danh duy nhất của chi nhánh |
| `restaurant_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `restaurants(restaurant_id)` | Thuộc về thương hiệu nhà hàng nào |
| `branch_name` | `VARCHAR(150)` | | NOT NULL | NO | | `LENGTH(TRIM(branch_name)) > 0` | Tên chi nhánh phân biệt (VD: Chi nhánh Bến Nghé Q1) |
| `phone_number` | `VARCHAR(20)` | | NOT NULL | NO | | `phone_number ~* '^[0-9+ ]{8,20}$'` | Số điện thoại liên hệ hotline của chi nhánh |
| `street_address` | `VARCHAR(255)` | | NOT NULL | NO | | `LENGTH(TRIM(street_address)) > 0` | Địa chỉ số nhà và tên đường |
| `ward` | `VARCHAR(100)` | | NULL | NO | NULL | | Phường / Xã trực thuộc |
| `district` | `VARCHAR(100)` | | NOT NULL | NO | | | Quận / Huyện trực thuộc |
| `city` | `VARCHAR(100)` | | NOT NULL | NO | | | Tỉnh / Thành phố |
| `latitude` | `DECIMAL(10, 8)` | | NOT NULL | NO | | `BETWEEN -90.0 AND 90.0` | Tọa độ vĩ độ WGS-84 của chi nhánh |
| `longitude` | `DECIMAL(11, 8)` | | NOT NULL | NO | | `BETWEEN -180.0 AND 180.0` | Tọa độ kinh độ WGS-84 của chi nhánh |
| `opening_time` | `TIME` | | NOT NULL | NO | | | Giờ bắt đầu mở cửa nhận đơn trong ngày |
| `closing_time` | `TIME` | | NOT NULL | NO | | | Giờ đóng cửa ngừng nhận đơn trong ngày |
| `is_active` | `BOOLEAN` | | NOT NULL | NO | `TRUE` | | Cờ trạng thái chi nhánh (`TRUE`: Đang phục vụ, `FALSE`: Tạm đóng) |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm khai trương/tạo chi nhánh |
| `updated_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm cập nhật dữ liệu chi nhánh |

### 2.2. Giải thích quyết định thiết kế
* **Ràng buộc duy nhất tổng hợp**: `UNIQUE (restaurant_id, branch_name)` để ngăn chặn việc một nhà hàng vô tình tạo hai chi nhánh trùng tên.
* **Tọa độ GPS `latitude` & `longitude`**: Dùng `DECIMAL(10, 8)` và `DECIMAL(11, 8)` chuẩn xác tới mức milimet, đồng bộ với bảng `customer_addresses` của SV1 và cung cấp dữ liệu đầu vào cho giải thuật Dispatching tài xế của SV3.
* **Xử lý khung giờ `opening_time` và `closing_time`**: Kiểu `TIME` lưu giờ:phút:giây. **Không** dùng `CHECK (closing_time > opening_time)` vì nhiều quán ăn đêm mở từ 18:00 đến 02:00 sáng hôm sau (`closing_time < opening_time`). Nghiệp vụ kiểm tra mở cửa sẽ được tính bằng logic truy vấn: 
  `IF opening_time <= closing_time THEN now_time BETWEEN opening_time AND closing_time ELSE now_time >= opening_time OR now_time <= closing_time`.

---

## 3. BẢNG `categories` (Danh mục thực đơn)

### 3.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `category_id` | `BIGINT` | **PK** | NOT NULL | YES | *Generated Always as Identity* | | Mã định danh danh mục thực đơn |
| `restaurant_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `restaurants(restaurant_id)` | Thuộc về thương hiệu nhà hàng sở hữu danh mục |
| `category_name` | `VARCHAR(100)` | | NOT NULL | NO | | `LENGTH(TRIM(category_name)) > 0` | Tên nhóm danh mục (VD: Cơm tấm, Trà trái cây, Khai vị) |
| `display_order` | `INTEGER` | | NOT NULL | NO | `0` | `>= 0` | Thứ tự ưu tiên sắp xếp hiển thị trên giao diện thực đơn |
| `is_active` | `BOOLEAN` | | NOT NULL | NO | `TRUE` | | Cờ trạng thái hiển thị danh mục trên ứng dụng |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm tạo danh mục |

### 3.2. Giải thích quyết định thiết kế
* **Gắn `categories` vào `restaurant_id`**: Mỗi nhà hàng có menu đặc thù riêng biệt, danh mục thuộc quyền quản trị của từng nhà hàng.
* **Ràng buộc duy nhất tổng hợp**: `UNIQUE (restaurant_id, category_name)` đảm bảo một quán không thể tạo hai danh mục trùng tên nhau.
* **`display_order`**: Cho phép chủ quán kéo thả, sắp xếp thứ tự hiển thị ưu tiên các danh mục bán chạy lên đầu ứng dụng.

---

## 4. BẢNG `items` (Món ăn / Đồ uống niêm yết)

### 4.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `item_id` | `BIGINT` | **PK** | NOT NULL | YES | *Generated Always as Identity* | | Mã định danh duy nhất của món ăn |
| `category_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `categories(category_id)` | Món ăn thuộc danh mục nào |
| `item_name` | `VARCHAR(150)` | | NOT NULL | NO | | `LENGTH(TRIM(item_name)) > 0` | Tên món ăn hiển thị (VD: Cơm sườn bì chả đặc biệt) |
| `description` | `TEXT` | | NULL | NO | NULL | | Mô tả chi tiết nguyên liệu, hương vị, khẩu phần |
| `base_price` | `DECIMAL(12, 2)` | | NOT NULL | NO | | `>= 0.00` | Giá niêm yết hiện thời của món (VNĐ) |
| `image_url` | `VARCHAR(500)` | | NULL | NO | NULL | | Đường dẫn ảnh chụp thực tế món ăn |
| `is_available` | `BOOLEAN` | | NOT NULL | NO | `TRUE` | | Trạng thái còn hàng (`TRUE`: Còn món, `FALSE`: Tạm hết món) |
| `display_order` | `INTEGER` | | NOT NULL | NO | `0` | `>= 0` | Thứ tự sắp xếp món ăn bên trong danh mục |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm tạo món |
| `updated_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm cập nhật giá hoặc thông tin món |

### 4.2. Giải thích quyết định thiết kế
* **Ràng buộc duy nhất tổng hợp**: `UNIQUE (category_id, item_name)` ngăn chặn tạo trùng tên món trong cùng một danh mục.
* **Giá bán `base_price`**: Kiểu `DECIMAL(12, 2)` cùng `CHECK (base_price >= 0)` loại bỏ hoàn toàn khả năng nhập giá âm hoặc sai số dấu phẩy động (Floating point).
* **Tuân thủ nguyên tắc [BR02]**: Món ăn lưu giá niêm yết hiện thời. Khi khách mua, phân hệ đơn hàng của SV1 bắt buộc lưu ảnh chụp `order_items.unit_price_snapshot` để tránh trôi giá lịch sử.
* **`ON DELETE RESTRICT` tại `category_id`**: Ngăn chặn hành vi xóa nhầm danh mục khi bên trong vẫn còn các món ăn đang kinh doanh.

---

## 5. BẢNG `option_groups` (Nhóm tùy chọn cho món ăn)

### 5.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `group_id` | `BIGINT` | **PK** | NOT NULL | YES | *Generated Always as Identity* | | Mã định danh duy nhất của nhóm tùy chọn |
| `item_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `items(item_id)` | Gắn vào món ăn cụ thể nào |
| `group_name` | `VARCHAR(100)` | | NOT NULL | NO | | `LENGTH(TRIM(group_name)) > 0` | Tên nhóm tùy chọn (VD: Chọn kích cỡ ly, Mức ngọt, Topping) |
| `min_selection` | `INTEGER` | | NOT NULL | NO | `0` | `>= 0` | Số lượng lựa chọn tối thiểu mà khách phải chọn |
| `max_selection` | `INTEGER` | | NOT NULL | NO | `1` | `>= min_selection AND max_selection >= 1` | Số lượng lựa chọn tối đa khách được phép chọn |
| `is_required` | `BOOLEAN` | | NOT NULL | NO | `FALSE` | | Cờ bắt buộc chọn (`TRUE` nếu `min_selection >= 1`) |
| `display_order` | `INTEGER` | | NOT NULL | NO | `0` | `>= 0` | Thứ tự hiển thị nhóm tùy chọn khi mở modal đặt món |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm tạo nhóm tùy chọn |

### 5.2. Giải thích quyết định thiết kế
* **Ràng buộc logic [BR-M02]**:
  `CONSTRAINT chk_option_groups_bounds CHECK (min_selection >= 0 AND max_selection >= min_selection AND max_selection >= 1)`
  Ràng buộc này triệt tiêu các trường hợp lỗi dữ liệu:
  * Không cho phép số lượng âm.
  * `max_selection` không được nhỏ hơn `min_selection`.
  * `max_selection` luôn phải chọn được ít nhất 1 mục (tránh nhóm tùy chọn vô nghĩa `max=0`).
* **Tính toán `is_required`**:
  * Nếu `min_selection = 0`: Tùy chọn không bắt buộc (khách có thể bỏ qua không chọn, ví dụ thêm topping).
  * Nếu `min_selection >= 1`: Bắt buộc phải chọn đủ số lượng tối thiểu (ví dụ chọn Size: `min=1, max=1`).
* **Ràng buộc duy nhất tổng hợp**: `UNIQUE (item_id, group_name)` tránh tạo hai nhóm trùng tên cho cùng một món ăn.

---

## 6. BẢNG `option_items` (Lựa chọn chi tiết kèm phụ thu)

### 6.1. Bảng cấu trúc dữ liệu

| Tên cột | Kiểu dữ liệu | PK/FK | NULL | UNIQUE | DEFAULT | CHECK | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| `option_item_id` | `BIGINT` | **PK** | NOT NULL | YES | *Generated Always as Identity* | | Mã định danh duy nhất của lựa chọn chi tiết |
| `group_id` | `BIGINT` | **FK** | NOT NULL | NO | | Tham chiếu `option_groups(group_id)` | Thuộc về nhóm tùy chọn nào |
| `option_name` | `VARCHAR(100)` | | NOT NULL | NO | | `LENGTH(TRIM(option_name)) > 0` | Tên lựa chọn cụ thể (VD: Size L (+10k), Trân châu đen (+5k)) |
| `extra_price` | `DECIMAL(12, 2)` | | NOT NULL | NO | `0.00` | `>= 0.00` | Đơn giá phụ thu thêm tính bằng VNĐ |
| `is_available` | `BOOLEAN` | | NOT NULL | NO | `TRUE` | | Trạng thái sẵn sàng (`TRUE`: Còn phục vụ, `FALSE`: Tạm hết) |
| `display_order` | `INTEGER` | | NOT NULL | NO | `0` | `>= 0` | Thứ tự hiển thị từng lựa chọn bên trong nhóm |
| `created_at` | `TIMESTAMPTZ` | | NOT NULL | NO | `CURRENT_TIMESTAMP` | | Thời điểm tạo lựa chọn |

### 6.2. Giải thích quyết định thiết kế
* **Ràng buộc phụ thu `extra_price >= 0`**: Cho phép phụ thu bằng `0.00` (như các lựa chọn miễn phí: *Size M chuẩn*, *100% Đường bình thường*, *Không lấy đá*) hoặc phụ thu dương (như *Size L +10.000đ*, *Thêm phô mai +15.000đ*). Tuyệt đối cấm giá âm.
* **Ràng buộc duy nhất**: `UNIQUE (group_id, option_name)` đảm bảo trong một nhóm không xuất hiện 2 lựa chọn trùng tên.
* **Khóa ngoại `ON DELETE CASCADE`**: Khi một nhóm tùy chọn bị xóa, các mục lựa chọn con bên trong tự động bị xóa dọn dẹp để đảm bảo toàn vẹn dữ liệu.
* **Liên kết với SV1**: Khi đơn hàng được tạo, `order_item_options` sẽ lưu khóa ngoại logic tham chiếu `option_item_id` kèm `extra_price_snapshot`.

---

## 7. BẢNG TỔNG HỢP KHÓA NGOẠI VÀ CHÍNH SÁCH THAM CHIẾU (REFERENTIAL INTEGRITY)

| Bảng con | Khóa ngoại (FK) | Bảng cha tham chiếu | Khóa chính cha (PK) | ON DELETE | ON UPDATE | Ý nghĩa nghiệp vụ |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `restaurants` | `owner_id` | `merchant_owners` (SV1) | `merchant_owner_id` | **RESTRICT** | **CASCADE** | Không cho xóa chủ quán nếu còn thương hiệu nhà hàng |
| `branches` | `restaurant_id` | `restaurants` | `restaurant_id` | **CASCADE** | **CASCADE** | Xóa thương hiệu thì tự động xóa chi nhánh con |
| `categories` | `restaurant_id` | `restaurants` | `restaurant_id` | **CASCADE** | **CASCADE** | Xóa thương hiệu thì tự động xóa danh mục menu |
| `items` | `category_id` | `categories` | `category_id` | **RESTRICT** | **CASCADE** | Không cho xóa danh mục nếu bên trong còn món ăn |
| `option_groups` | `item_id` | `items` | `item_id` | **CASCADE** | **CASCADE** | Xóa món ăn thì xóa các nhóm tùy chọn của món đó |
| `option_items` | `group_id` | `option_groups` | `group_id` | **CASCADE** | **CASCADE** | Xóa nhóm tùy chọn thì tự động xóa các mục con |
