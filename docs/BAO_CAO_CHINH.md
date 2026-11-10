# BÁO CÁO ĐỒ ÁN CƠ SỞ DỮ LIỆU

## Nền tảng tổng hợp giao đồ ăn (mô hình tương tự DoorDash)

**Nhóm:** Bùi Duy Quang, Phạm Đình Phúc, Lương Công Phi  
**DBMS mục tiêu:** MySQL 8.4 (kiểm thử 8.4.11), InnoDB  
**Phạm vi:** thiết kế/triển khai CSDL và ứng dụng demo nghiệp vụ; không tích hợp cổng thanh toán hoặc GPS thật.

> Chưa tìm thấy đề bài, rubric hoặc mẫu báo cáo chính thức của giảng viên trong workspace. Tài liệu này dùng cấu trúc kỹ thuật tạm thời; nhóm phải chuyển nội dung sang mẫu chính thức khi nhận được mẫu.

## 1. Nguồn và phương pháp khảo sát

Nguồn thực sự có trong workspace gồm DRS cũ, bản phân công Word, các sơ đồ Mermaid, SQL phân hệ, SQL tích hợp và tài liệu GIS. Không có biên bản phỏng vấn, bảng hỏi đã thu thập, dữ liệu DoorDash nội bộ hay kết quả khảo sát người dùng. Vì vậy các quy tắc dưới đây là **giả định thiết kế cần xác nhận**, không phải kết quả khảo sát thực địa.

Phương pháp đề xuất cho vòng xác nhận tiếp theo: phỏng vấn bán cấu trúc một khách hàng, một người vận hành nhà hàng và một tài xế; walkthrough vòng đời đơn; rà soát ngoại lệ bằng các câu hỏi: một đơn có được chứa món từ nhiều chi nhánh không, khi nào được hủy, có bao nhiêu lần thử thanh toán, ai được tái phân công tài xế, vị trí đến trễ xử lý thế nào, điều kiện được đánh giá là gì. Không ghi các hoạt động này là “đã thực hiện” cho đến khi có biên bản.

## 2. Phạm vi và giả định chốt

- Một đơn thuộc đúng một khách hàng và một chi nhánh; mọi món trong đơn phải thuộc nhà hàng của chi nhánh đó.
- Một đơn có một lần giao; lần giao có nhiều bản ghi phân công theo thời gian nhưng tối đa một phân công đang hiệu lực.
- Trạng thái đơn, trạng thái giao và trạng thái thanh toán là ba khái niệm độc lập.
- Một đơn có thể có nhiều lần thử thanh toán; tối đa một lần ở trạng thái `SUCCESS`.
- Giá, tên món, tùy chọn và địa chỉ nhận được chụp tại thời điểm đặt; sửa menu hoặc sổ địa chỉ không làm đổi đơn cũ.
- Tiền dùng `DECIMAL(12,2)`, không âm; tổng đơn bằng tạm tính + phí giao + phí dịch vụ − giảm giá. Chính sách làm tròn chi tiết cần giảng viên/nhóm xác nhận.
- Tọa độ theo WGS-84, thứ tự trình bày là latitude rồi longitude; Haversine là khoảng cách đường chim bay, không phải quãng đường bộ.

## 3. Quy trình nghiệp vụ

Luồng thuận: `PENDING → CONFIRMED → PREPARING → READY_FOR_PICKUP → PICKED_UP → DELIVERED`. Chỉ `PENDING` hoặc `CONFIRMED` được chuyển sang `CANCELLED`. Giao hàng dùng luồng riêng: `WAITING_ASSIGNMENT → ASSIGNED/TO_PICKUP → PICKED_UP → DELIVERING → DELIVERED`; có nhánh `FAILED` và `CANCELLED`. Thanh toán có thể `PENDING`, `SUCCESS`, `FAILED`, `REFUNDED`.

Ngoại lệ: thanh toán thất bại tạo lần thử khác; phân công bị từ chối/thất bại được đóng bằng `ended_at` và tạo phân công mới; giao thất bại phải có lý do và thời điểm; dữ liệu vị trí đến trễ vẫn lưu theo `captured_at`, còn `recorded_at` phản ánh lúc máy chủ nhận.

## 4. Mô hình ER/EER và quan hệ

File nguồn tổng thể là `diagrams/eer_full.mmd`. Hai specialization có ý nghĩa nghiệp vụ:

1. `USERS → CUSTOMERS | MERCHANT_OWNERS | DRIVERS`: disjoint, total theo giả định tài khoản một vai trò. SQL dùng PK đồng thời FK; tính total/disjoint cần transaction/trigger hoặc tầng ứng dụng khi tạo tài khoản.
2. `PAYMENTS → CASH_PAYMENTS | CARD_PAYMENTS | EWALLET_PAYMENTS`: disjoint, total theo `payment_method`. SQL dùng PK đồng thời FK; transaction tạo payment và đúng một subtype là cơ chế triển khai.

Cardinality và participation chính: CUSTOMER 0..N ORDERS; BRANCH 0..N ORDERS; ORDER 1..N ORDER_ITEMS; ORDER 0..N PAYMENTS; ORDER 0..1 DELIVERY; DELIVERY 0..N ASSIGNMENTS; DRIVER 0..N ASSIGNMENTS và LOCATION samples.

## 5. Lược đồ, từ điển và chuẩn hóa

Từ điển hiện có ở `docs/data_dictionary_sv3.md`; phần bổ sung xem `docs/PHU_LUC_KY_THUAT.md`. Lược đồ chạy chính thức là `sql/mysql_schema.sql`, seed là `sql/demo_seed.sql`; các script PostgreSQL cũ chỉ là lịch sử.

Các quan hệ thực thể có khóa thay thế và các determinant nghiệp vụ được đặt UNIQUE. Thuộc tính nguyên tử nên đạt 1NF. Quan hệ N–N được tách qua `ORDER_ITEMS`, `ORDER_ITEM_OPTIONS`, `DELIVERY_ASSIGNMENTS`. Thuộc tính không khóa phụ thuộc đầy đủ vào khóa của từng bảng và không có phụ thuộc bắc cầu đã biết, nên đạt 3NF; đa số bảng đạt BCNF vì mọi determinant đã biết là siêu khóa. Snapshot trong đơn là dư thừa có chủ đích để bảo toàn lịch sử, không được đồng bộ ngược theo menu/sổ địa chỉ.

## 6. Toàn vẹn, bảo mật và xóa dữ liệu

PK/FK/UNIQUE/CHECK bảo đảm miền và tham chiếu. Partial unique index bảo đảm một địa chỉ mặc định, một phân công hiệu lực và một thanh toán thành công. Trigger kiểm tra món đúng nhà hàng của chi nhánh, máy trạng thái đơn và quyền đánh giá. Dữ liệu lịch sử dùng `RESTRICT`/soft-delete; cascade chỉ áp dụng chi tiết phụ thuộc vòng đời cha. Mật khẩu chỉ lưu hash; không lưu số thẻ đầy đủ; quyền production nên tách role đọc báo cáo, vận hành và migration.

## 7. Dữ liệu không gian

Thiết kế dùng hai cột `DECIMAL` latitude/longitude với CHECK và Haversine thuần MySQL; chưa cần bản đồ hoặc spatial extension. `current_lat/current_long` là cache hiện tại, còn lịch sử chuẩn nằm ở `DRIVER_LOCATION_HISTORY`.

## 8. Kiểm chứng và giới hạn

Đã chạy thực nghiệm ngày 10/11/2026 bằng MySQL 8.4.11 (`mysql:8.4`). Schema tạo 24 bảng InnoDB; seed chạy lặp không trùng và test E2E web PASS. Script kiểm tra là `sql/mysql_tests.sql`, test API ở `app/test/api.test.js`.

## 9. Kết luận

Thiết kế đáp ứng trọng tâm môn CSDL cho nhóm ba người: DRS, ER/EER có specialization/generalization, lược đồ quan hệ, 3NF, DDL/ràng buộc, dữ liệu minh họa, truy vấn nghiệp vụ và kiểm chứng MySQL. Việc còn thiếu là mẫu/rubric chính thức và bằng chứng khảo sát thật.

## 10. Ứng dụng minh họa

Ứng dụng “Bếp Nối” dùng Node.js/Express, `mysql2` và MySQL 8.4/InnoDB. Khách chọn chi nhánh/món và tạo đơn COD trong một transaction; nhà hàng chuyển `CONFIRMED → PREPARING → READY_FOR_PICKUP`; điều phối gán tài xế; tài xế cập nhật `PICKED_UP → DELIVERED`. Trigger MySQL ghi lịch sử, COD chuyển thành công khi giao xong. Vị trí là tọa độ mô phỏng trong `DRIVER_LOCATION_HISTORY`.

Tài khoản mẫu chỉ dùng đổi vai trò lúc demo, không phải đăng nhập thật. Source nằm trong `app/`, cách chạy ở `app/README.md`, kịch bản ở `docs/KICH_BAN_DEMO_UNG_DUNG.md`.
