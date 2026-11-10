# TÀI LIỆU ĐẶC TẢ YÊU CẦU CƠ SỞ DỮ LIỆU (DATABASE REQUIREMENT SPECIFICATION - DRS)

* **Tên đề tài**: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
* **Học phần**: Cơ sở dữ liệu
* **Nhóm thực hiện**: Nhóm 3 sinh viên
* **Sinh viên 1 (Lead & Phân hệ Người dùng)**: Bùi Duy Quang
* **Sinh viên 2 (Phân hệ Thực đơn & Chuẩn hóa)**: Phạm Đình Phúc
* **Sinh viên 3 (Phân hệ Vận hành & Thanh toán GIS)**: Lương Công Phi
* **Hệ quản trị CSDL mục tiêu**: PostgreSQL 14+ / 15 / 16

---

## 1. TỔNG QUAN DỰ ÁN & BỐI CẢNH NGHIỆP VỤ

### 1.1. Bối cảnh đề tài
Thương mại điện tử trong lĩnh vực ẩm thực (Food Delivery) là mô hình thị trường đa giác (Multi-sided Marketplace), kết nối trực tiếp ba chủ thể cốt lõi:
1. **Khách hàng (Customers)** có nhu cầu tìm kiếm, đặt món ăn và nhận hàng tận nơi.
2. **Đối tác nhà hàng (Merchants/Restaurants)** cung cấp các món ăn qua thực đơn số hóa và chế biến khi có đơn.
3. **Đối tác tài xế (Drivers/Dashers)** nhận nhiệm vụ vận chuyển từ quán đến tay người tiêu dùng.
4. **Đơn vị vận hành nền tảng (Platform Operator)** đóng vai trò trung gian công nghệ, điều phối đơn hàng, tính toán cước phí, định tuyến không gian (GIS) và xử lý luồng thanh toán.

### 1.2. Vấn đề nghiệp vụ thực tế (Problem Statement)
Mô hình DoorDash đặt ra các thách thức kỹ thuật nghiêm ngặt về quản lý dữ liệu:
* **Tính bất đối xứng thông tin và xung đột trạng thái**: Cùng một đơn hàng chịu sự tác động đồng thời của 3 tác nhân (Quán xác nhận làm món, Tài xế nhận đơn giao, Khách hàng theo dõi vị trí). CSDL phải đảm bảo kiểm soát đồng thời (Concurrency Control) và tính toàn vẹn giao dịch (ACID).
* **Hiện tượng trôi giá (Price Drift)**: Giá bán, phụ thu topping, phí giao hàng thay đổi liên tục theo thời gian thực và chính sách khuyến mãi. CSDL phải lưu trữ được ảnh chụp giá lịch sử (Historical Price Snapshot) để đảm bảo doanh thu, hóa đơn kế toán và đối soát không bị sai lệch khi menu cập nhật giá mới.
* **Mô hình định danh đa vai trò**: Cần cơ chế phân tách và quản lý tài khoản người dùng rõ ràng giữa khách hàng, chủ nhà hàng và tài xế nhưng vẫn dùng chung hệ thống xác thực.
* **Quản lý địa chỉ giao hàng và tọa độ địa lý**: Khách hàng lưu nhiều địa chỉ (nhà, cơ quan, bạn bè), hệ thống cần tính khoảng cách từ nhà hàng đến vị trí khách để tính phí ship và chỉ định tài xế gần nhất.

### 1.3. Mục tiêu của hệ thống CSDL
* Thiết kế mô hình dữ liệu quan hệ chuẩn hóa (tối thiểu đạt 3NF và BCNF).
* Đảm bảo tính toàn vẹn tham chiếu (Referential Integrity), toàn vẹn thực thể (Entity Integrity) và toàn vẹn miền giá trị (Domain Integrity).
* Đảm bảo khả năng mở rộng (Scalability) và tối ưu truy vấn thông qua lập chỉ mục (B-Tree, Partial Index, GiST Index cho dữ liệu không gian).

---

## 2. PHẠM VI HỆ THỐNG & CÁC TÁC NHÂN (SCOPE & ACTORS)

### 2.1. Phân định phạm vi hệ thống (System Boundaries)
* **Trong phạm vi (In-Scope)**:
  * Quản lý định danh tài khoản, phân quyền vai trò (Khách hàng, Chủ quán, Tài xế).
  * Quản lý sổ địa chỉ giao hàng của khách hàng kèm tọa độ địa lý.
  * Quản lý mạng lưới nhà hàng, chi nhánh, danh mục món và cấu trúc thực đơn đa tầng kèm topping tùy chọn.
  * Quản lý vòng đời đơn hàng, chi tiết đơn hàng và snapshot giá lịch sử.
  * Quản lý thông tin tài xế và trạng thái giao vận.
  * Quản lý đa hình các phương thức thanh toán (Tiền mặt, Thẻ ngân hàng, Ví điện tử).
  * Quản lý nhật ký trạng thái đơn hàng (Audit Logging) và đánh giá dịch vụ 2 chiều.
* **Ngoài phạm vi (Out-of-Scope)**:
  * Xử lý cổng thanh toán trực tiếp qua API ngân hàng (chỉ lưu trữ thông tin giao dịch kế toán).
  * Giao diện người dùng Web/Mobile App (chỉ tập trung lớp dữ liệu CSDL).

### 2.2. Các tác nhân tham gia hệ thống
1. **Khách hàng (Customer)**: Đăng ký tài khoản, quản lý địa chỉ giao hàng, tìm kiếm món, đặt đơn hàng, thanh toán và đánh giá tài xế/quán.
2. **Chủ đối tác nhà hàng (Merchant Owner)**: Đăng ký xác minh danh tính (KYC/Mã số thuế), quản lý thông tin nhà hàng, thiết lập thực đơn, quản lý chi nhánh, nhận đơn và cập nhật món ăn.
3. **Đối tác tài xế (Driver)**: Đăng ký hồ sơ giấy phép lái xe, phương tiện, bật/tắt trạng thái sẵn sàng nhận đơn, nhận cuốc xe, cập nhật lộ trình giao hàng.
4. **Quản trị viên nền tảng (Admin / Operator)**: Duyệt hồ sơ đối tác, giám sát đơn hàng, xử lý khiếu nại và trích xuất báo cáo doanh số.

---

## 3. YÊU CẦU DỮ LIỆU & CHỨC NĂNG THEO 3 PHÂN HỆ

### 3.1. Phân hệ 1: Người dùng, Sổ địa chỉ & Đơn hàng (SV1 phụ trách)
* **Định danh & Tài khoản (`USERS`)**:
  * Lưu trữ thông tin đăng nhập tập trung: `user_id` (PK), `email` (Unique, Not Null), `phone_number` (Unique, Not Null), `password_hash` (Chuỗi mã hóa mật khẩu, tuyệt đối không lưu plaintext), `full_name`, `user_type` ('CUSTOMER', 'MERCHANT_OWNER', 'DRIVER'), `status` ('ACTIVE', 'SUSPENDED', 'DELETED'), `created_at`, `updated_at`.
* **Hồ sơ Khách hàng (`CUSTOMERS`)**:
  * Kế thừa từ `USERS`: `customer_id` (PK, FK tham chiếu `USERS.user_id`).
  * Lưu trữ điểm tích lũy thành viên (`loyalty_points >= 0`), ngày sinh (`birth_date`), ảnh đại diện (`avatar_url`).
* **Sổ địa chỉ giao hàng (`CUSTOMER_ADDRESSES`)**:
  * Quan hệ 1 - N với `CUSTOMERS`: một khách hàng có thể lưu nhiều địa chỉ.
  * Lưu trữ: `address_id` (PK), `customer_id` (FK), `recipient_name`, `recipient_phone`, `street_address`, `ward`, `district`, `city`, `latitude` (Vĩ độ: -90 đến +90), `longitude` (Kinh độ: -180 đến +180), `address_label` (VD: 'Nhà riêng', 'Cơ quan', 'Khác'), cờ `is_default` (BOOLEAN).
  * Quy tắc: Mỗi khách hàng chỉ có tối đa 1 địa chỉ mặc định (`is_default = TRUE`).
* **Hồ sơ Chủ nhà hàng (`MERCHANT_OWNERS`)**:
  * Kế thừa từ `USERS`: `merchant_owner_id` (PK, FK tham chiếu `USERS.user_id`).
  * Lưu trữ: `tax_code` (Mã số thuế doanh nghiệp/hộ kinh doanh, Unique), `identity_card_number` (CCCD/Hộ chiếu đại diện, Unique), `business_license_url`, `kyc_status` ('PENDING', 'VERIFIED', 'REJECTED').
* **Đơn hàng trung tâm (`ORDERS`, `ORDER_ITEMS`, `ORDER_ITEM_OPTIONS`)**:
  * `ORDERS`: `order_id` (PK), `order_code` (Unique), `customer_id` (FK), `branch_id` (FK), `driver_id` (FK, cho phép NULL khi chưa gán tài xế), `delivery_address_id` (FK), `order_status`, `subtotal_amount`, `delivery_fee`, `service_fee`, `discount_amount`, `total_amount`, `created_at`.
  * `ORDER_ITEMS`: `order_item_id` (PK), `order_id` (FK), `item_id` (FK logic), `item_name_snapshot`, `unit_price_snapshot`, `quantity`, `subtotal`.
  * `ORDER_ITEM_OPTIONS`: `order_item_option_id` (PK), `order_item_id` (FK), `option_item_id` (FK logic), `option_name_snapshot`, `extra_price_snapshot`.

### 3.2. Phân hệ 2: Nhà hàng, Chi nhánh & Thực đơn phân cấp (SV2 phụ trách)
* **Thương hiệu & Chi nhánh (`RESTAURANTS`, `BRANCHES`)**:
  * `RESTAURANTS`: `restaurant_id` (PK), `owner_id` (FK tham chiếu `MERCHANT_OWNERS`), `restaurant_name`, `cuisine_type`, `logo_url`.
  * `BRANCHES`: `branch_id` (PK), `restaurant_id` (FK), `branch_name`, `address`, `latitude`, `longitude`, `opening_time`, `closing_time`, `is_active`.
* **Cấu trúc thực đơn đa tầng (`CATEGORIES`, `ITEMS`, `OPTION_GROUPS`, `OPTION_ITEMS`)**:
  * `CATEGORIES`: Danh mục món ăn (VD: Cơm, Mì, Nước ép).
  * `ITEMS`: Món ăn chính, đơn giá gốc (`base_price >= 0`), mô tả, trạng thái phục vụ (`is_available`).
  * `OPTION_GROUPS`: Nhóm tùy chọn gắn vào món (VD: Size ly, Độ ngọt, Topping kèm) với quy tắc lựa chọn: `min_selectable` và `max_selectable`.
  * `OPTION_ITEMS`: Từng lựa chọn cụ thể (VD: Trân châu trắng, Size L) kèm đơn giá phụ thu (`extra_price >= 0`).

### 3.3. Phân hệ 3: Tài xế, Thanh toán, Nhật ký & Đánh giá (SV3 phụ trách)
* **Hồ sơ Tài xế (`DRIVERS`)**:
  * Kế thừa từ `USERS`: `driver_id` (PK, FK tham chiếu `USERS.user_id`).
  * `license_number` (GPLX, Unique), `vehicle_type` ('MOTORBIKE', 'ELECTRIC_BIKE', 'CAR'), `vehicle_plate` (Biển số xe, Unique), `current_lat`, `current_long`, `driver_status` ('OFFLINE', 'AVAILABLE', 'DELIVERING'), `is_active`.
* **Siêu lớp & Phân lớp Thanh toán (`PAYMENTS`, `CASH_PAYMENTS`, `CARD_PAYMENTS`, `EWALLET_PAYMENTS`)**:
  * Siêu lớp `PAYMENTS`: `payment_id` (PK), `order_id` (FK, Unique - 1 đơn hàng ứng với 1 giao dịch thanh toán), `amount`, `payment_method` ('CASH', 'CARD', 'EWALLET'), `payment_status` ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED'), `paid_at`.
  * Phân lớp `CASH_PAYMENTS`: `change_amount_for` (tiền khách chuẩn bị để thối).
  * Phân lớp `CARD_PAYMENTS`: `card_last4`, `card_brand`, `transaction_ref`.
  * Phân lớp `EWALLET_PAYMENTS`: `wallet_provider` ('MOMO', 'ZALOPAY', 'SHOPEEPAY'), `wallet_transaction_id`.
* **Theo dõi & Đánh giá (`ORDER_STATUS_LOGS`, `RESTAURANT_REVIEWS`, `DRIVER_REVIEWS`)**:
  * `ORDER_STATUS_LOGS`: Ghi vết dòng thời gian trạng thái đơn: `log_id` (PK), `order_id` (FK), `previous_status`, `new_status`, `changed_by_user_id` (FK), `timestamp`, `note`.
  * `RESTAURANT_REVIEWS`: Khách đánh giá món ăn và quán (1 - 5 sao, bình luận).
  * `DRIVER_REVIEWS`: Khách đánh giá thái độ giao hàng của tài xế (1 - 5 sao, bình luận).

---

## 4. TẬP QUY TẮC NGHIỆP VỤ CỐT LÕI (CORE BUSINESS RULES - BR)

* **[BR01 - Chuyên biệt hóa Người dùng (User Specialization)]**:
  * Mối quan hệ giữa siêu lớp `USERS` và các phân lớp (`CUSTOMERS`, `MERCHANT_OWNERS`, `DRIVERS`) là **Rời rạc (Disjoint - $\{d\}$)** và **Toàn phần (Total - $\{t\}$)**.
  * *Disjoint*: Một tài khoản đăng nhập tại một thời điểm chỉ đóng chính xác một vai trò trong hệ thống.
  * *Total*: Không tồn tại người dùng nào trong bảng `USERS` mà không thuộc về một trong ba phân lớp con.
  * Các bảng phân lớp sử dụng chính `user_id` làm Khóa chính (PK) và đồng thời là Khóa ngoại (FK) tham chiếu đến `USERS(user_id)`.

* **[BR02 - Bảo toàn giá trị lịch sử (Historical Price Snapshot)]**:
  * Giá của món ăn (`base_price`) và giá tùy chọn (`extra_price`) trong menu có thể thay đổi bất kỳ lúc nào theo quyết định của nhà hàng.
  * Khi đơn hàng được tạo, toàn bộ tên món, tên topping và đơn giá tại thời điểm đặt **bắt buộc phải được sao chép nguyên vẹn (snapshot)** vào `ORDER_ITEMS.unit_price_snapshot` và `ORDER_ITEM_OPTIONS.extra_price_snapshot`. Cấm tính toán tổng tiền đơn hàng quá khứ bằng cách Join trực tiếp với bảng `ITEMS` của thực đơn hiện tại.

* **[BR03 - Sổ địa chỉ & Địa chỉ mặc định duy nhất (Unique Default Address)]**:
  * Một khách hàng có quyền lưu trữ $N$ địa chỉ giao nhận ($N \ge 0$).
  * Tại một thời điểm, một khách hàng chỉ được phép có **tối đa một địa chỉ mặc định** (`is_default = TRUE`). Ràng buộc này được bảo đảm bằng Partial Unique Index trong CSDL.

* **[BR04 - Máy trạng thái vòng đời đơn hàng (Order State Transition)]**:
  * Đơn hàng bắt buộc phải tuân theo luồng tuần tự nghiêm ngặt:
    $$\text{PENDING} \longrightarrow \text{CONFIRMED} \longrightarrow \text{PREPARING} \longrightarrow \text{READY\_FOR\_PICKUP} \longrightarrow \text{PICKED\_UP} \longrightarrow \text{DELIVERED}$$
  * Đơn hàng chỉ có thể bị hủy (`CANCELLED`) khi đang ở trạng thái `PENDING` hoặc `CONFIRMED`.
  * Mọi bước chuyển trạng thái phải tự động tạo một bản ghi kiểm toán trong bảng `ORDER_STATUS_LOGS`.

* **[BR05 - Chuyên biệt hóa Thanh toán (Payment Polymorphism)]**:
  * Siêu lớp `PAYMENTS` và các phân lớp (`CASH_PAYMENTS`, `CARD_PAYMENTS`, `EWALLET_PAYMENTS`) thỏa mãn ràng buộc **Disjoint $\{d\}$** và **Total $\{t\}$**.
  * Mỗi đơn hàng chỉ có một giao dịch thanh toán duy nhất (`order_id` trong `PAYMENTS` là UNIQUE).

* **[BR06 - Tọa độ không gian & Tính toàn vẹn vị trí (Spatial Coordinates Integrity)]**:
  * Toàn bộ tọa độ vĩ độ (`latitude`) phải nằm trong đoạn $[-90.0, +90.0]$.
  * Toàn bộ tọa độ kinh độ (`longitude`) phải nằm trong đoạn $[-180.0, +180.0]$.
  * Định dạng số thực chuẩn `DECIMAL(10, 8)` cho Latitude và `DECIMAL(11, 8)` cho Longitude để đảm bảo độ phân giải chính xác tới milimet.

* **[BR07 - Đánh giá có điều kiện xác thực (Verified Conditional Review)]**:
  * Khách hàng chỉ được quyền gửi đánh giá (`RESTAURANT_REVIEWS` hoặc `DRIVER_REVIEWS`) khi đơn hàng tương ứng đã có trạng thái `DELIVERED`.
  * Mỗi đơn hàng chỉ được phép đánh giá tối đa 1 lần cho nhà hàng và 1 lần cho tài xế (`order_id` là UNIQUE trong bảng review). Điểm đánh giá `rating` bắt buộc nằm trong đoạn $[1, 5]$.

---

## 5. MA TRẬN ÁNH XẠ THỰC THỂ HỆ THỐNG (SYSTEM ENTITY MATRIX)

| STT | Tên bảng / Thực thể | Phân hệ | Thành viên phụ trách | Mô tả ngắn gọn & Vai trò |
| :---: | :--- | :---: | :---: | :--- |
| **1** | `USERS` | Người dùng | **SV1** | Siêu lớp người dùng chung (Xác thực, email, SĐT, loại tài khoản) |
| **2** | `CUSTOMERS` | Người dùng | **SV1** | Phân lớp khách hàng (Điểm thưởng, hồ sơ cá nhân) |
| **3** | `CUSTOMER_ADDRESSES`| Người dùng | **SV1** | Danh sách địa chỉ giao hàng của khách hàng (Tọa độ, mặc định) |
| **4** | `MERCHANT_OWNERS` | Người dùng | **SV1** | Phân lớp chủ quán ăn (Mã số thuế, CCCD, thông tin xác minh KYC) |
| **5** | `ORDERS` | Đơn hàng | **SV1** | Bảng trung tâm lưu vết thông tin đơn hàng, tổng tiền, cước ship |
| **6** | `ORDER_ITEMS` | Đơn hàng | **SV1** | Chi tiết món đặt kèm giá snapshot tại thời điểm mua |
| **7** | `ORDER_ITEM_OPTIONS`| Đơn hàng | **SV1** | Tùy chọn topping/size kèm theo món với giá snapshot |
| **8** | `RESTAURANTS` | Thực đơn | **SV2** | Hồ sơ thương hiệu nhà hàng đối tác |
| **9** | `BRANCHES` | Thực đơn | **SV2** | Chi nhánh thực tế của nhà hàng (Tọa độ, giờ hoạt động) |
| **10**| `CATEGORIES` | Thực đơn | **SV2** | Phân loại ẩm thực trong menu (Cơm, Đồ uống, Khai vị,...) |
| **11**| `ITEMS` | Thực đơn | **SV2** | Danh mục món ăn cụ thể, giá niêm yết hiện thời |
| **12**| `OPTION_GROUPS` | Thực đơn | **SV2** | Nhóm tùy chọn bổ sung cho món (Size, Độ ngọt, Topping) |
| **13**| `OPTION_ITEMS` | Thực đơn | **SV2** | Từng mục lựa chọn trong nhóm option kèm phụ thu niêm yết |
| **14**| `DRIVERS` | Vận hành | **SV3** | Phân lớp tài xế (Bằng lái, biển số, tọa độ trực tiếp, trạng thái cuốc) |
| **15**| `PAYMENTS` | Thanh toán | **SV3** | Siêu lớp thanh toán kế toán của đơn hàng |
| **16**| `CASH_PAYMENTS` | Thanh toán | **SV3** | Phân lớp trả tiền mặt cho tài xế |
| **17**| `CARD_PAYMENTS` | Thanh toán | **SV3** | Phân lớp quẹt thẻ tín dụng/ghi nợ |
| **18**| `EWALLET_PAYMENTS` | Thanh toán | **SV3** | Phân lớp thanh toán ví điện tử tích hợp |
| **19**| `ORDER_STATUS_LOGS` | Vận hành | **SV3** | Nhật ký dòng thời gian thay đổi trạng thái đơn hàng |
| **20**| `RESTAURANT_REVIEWS`| Đánh giá | **SV3** | Phản hồi sao và nhận xét của khách cho nhà hàng |
| **21**| `DRIVER_REVIEWS` | Đánh giá | **SV3** | Phản hồi sao và nhận xét của khách cho tài xế |
