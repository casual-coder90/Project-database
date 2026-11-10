# BÁO CÁO TIẾN ĐỘ THỰC HIỆN DỰ ÁN & RÀ SOÁT CÔNG VIỆC CÁC THÀNH VIÊN
**Đề tài**: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)  
**Học phần**: Cơ sở dữ liệu  
**Căn cứ đối soát**: Kế hoạch phân công tại [BANG_PHAN_CHIA_CONG_VIEC_NHOM_3_NGUOI_UPDATED.docx](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/BANG_PHAN_CHIA_CONG_VIEC_NHOM_3_NGUOI_UPDATED.docx)  
**Ngày báo cáo**: 26/10/2026  

---

## I. TỔNG QUAN TIẾN ĐỘ CHUNG TOÀN NHÓM

| Thành viên | Vai trò & Phân hệ | Tỉ lệ hoàn thành (Ước tính) | Đánh giá tổng quan |
| :--- | :--- | :---: | :--- |
| **Bùi Duy Quang (SV1)** | Nhóm trưởng, Phân hệ Người dùng & Đơn hàng trung tâm | **~50%** | Đã hoàn thành toàn diện phân hệ Người dùng (DRS, EER, DDL). **Chưa triển khai** phân hệ Đơn hàng (`ORDERS`), câu truy vấn Join 4 bên và Báo cáo tuần. |
| **Phạm Đình Phúc (SV2)** | Chuyên viên Thực đơn, Chuẩn hóa & Dữ liệu mẫu | **~100%** | Đã hoàn thành xuất sắc toàn bộ 6 bảng thực đơn, Data Dictionary, chứng minh 3NF/BCNF, DDL PostgreSQL và kịch bản nạp dữ liệu mẫu (Dummy data). |
| **Lương Công Phi (SV3)** | Kỹ sư CSDL, Vận hành & Xử lý không gian (GIS) | **~5%** | **Chưa triển khai hầu hết các đầu việc**: Chưa có sơ đồ EER Thanh toán, chưa có DDL Vận hành/Thanh toán/Tài xế, chưa có script GIS Spatial Dispatching và chưa ghép nối tích hợp DDL. |

---

## II. BÁO CÁO CHI TIẾT TỪNG THÀNH VIÊN

### 1. Sinh viên 1: Bùi Duy Quang (Lead & Phân hệ Người dùng + Đơn hàng)

#### A. Những công việc ĐÃ LÀM ĐƯỢC:
* **[SV1-01] Khảo sát & Tổng hợp tài liệu DRS**:
  * Đã biên soạn hoàn chỉnh tài liệu [docs/DRS.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/DRS.md) dài 167 dòng, bao gồm: Bối cảnh, Problem Statement (trôi giá, bất đối xứng thông tin), phạm vi hệ thống In-Scope/Out-of-Scope, 4 tác nhân, danh mục 21 bảng toàn hệ thống, 7 quy tắc nghiệp vụ cốt lõi (BR01 - BR07).
* **[SV1-02] Mô hình EER phân hệ Người dùng**:
  * Đã thiết kế hoàn thiện file sơ đồ Mermaid [diagrams/eer_users.mmd](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/diagrams/eer_users.mmd) thể hiện siêu lớp `USERS` và 3 phân lớp `CUSTOMERS`, `MERCHANT_OWNERS`, `DRIVERS` với ràng buộc Disjoint $\{d\}$ và Total $\{t\}$, cùng thực thể con `CUSTOMER_ADDRESSES`.
* **[SV1-03 (Một phần)] Data Dictionary & DDL Phân hệ Người dùng**:
  * Đã viết hoàn chỉnh kịch bản SQL chuẩn PostgreSQL tại [sql/sv1/users_ddl.sql](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/sql/sv1/users_ddl.sql) với 4 bảng: `users`, `customers`, `merchant_owners`, `customer_addresses`.
  * Có đầy đủ các ràng buộc nâng cao: Regex kiểm tra định dạng email/SĐT, kiểm tra tọa độ GPS, Partial Unique Index đảm bảo duy nhất 1 địa chỉ mặc định/khách hàng (`idx_unique_default_address`), kịch bản kiểm thử pass/fail và dữ liệu mẫu 5 user.

#### B. Những công việc CHƯA LÀM (Tồn đọng):
* **[SV1-03 (Phần còn lại)] DDL & Data Dictionary cho Phân hệ Đơn hàng**:
  * Chưa viết DDL và Data Dictionary cho chuỗi bảng đơn hàng trung tâm: `ORDERS`, `ORDER_ITEMS`, `ORDER_ITEM_OPTIONS`.
  * Chưa hiện thực hóa ràng buộc snapshot đơn giá lịch sử (`unit_price_snapshot`, `extra_price_snapshot`) trên CSDL.
* **[SV1-04] Viết truy vấn Join 4 bên chi tiết đơn hàng**:
  * Chưa có kịch bản truy vấn Join 4 bên (Khách hàng - Đơn hàng - Nhà hàng - Món ăn/Topping) xử lý trường hợp một đơn hàng có nhiều món và nhiều topping trả về nhiều dòng.
* **[SV1-05] Kiểm thử chéo & Báo cáo tuần**:
  * Chưa có biên bản kiểm thử độc lập kịch bản SQL phân hệ Thực đơn của SV2.
  * Chưa tổng hợp báo cáo kỹ thuật theo mẫu giảng viên và báo cáo tiến độ tuần.

---

### 2. Sinh viên 2: Phạm Đình Phúc (Thực đơn, Chuẩn hóa & Dữ liệu mẫu)

#### A. Những công việc ĐÃ LÀM ĐƯỢC:
* **[SV2-01] Khảo sát & Thiết kế cấu trúc Thực đơn**:
  * Đã khảo sát mô hình DoorDash/ShopeeFood và mô hình hóa thành công chuỗi 6 bảng phân cấp: `RESTAURANTS`, `BRANCHES`, `CATEGORIES`, `ITEMS`, `OPTION_GROUPS`, `OPTION_ITEMS`.
  * Đã vẽ sơ đồ quan hệ chi tiết tại [diagrams/eer_menu.mmd](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/diagrams/eer_menu.mmd).
* **[SV2-02] Data Dictionary & Kịch bản DDL Thực đơn**:
  * Đã biên soạn hoàn chỉnh Từ điển dữ liệu tại [docs/data_dictionary_menu.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/data_dictionary_menu.md).
  * Đã viết kịch bản DDL chuẩn chỉnh tại [sql/sv2/menu_ddl.sql](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/sql/sv2/menu_ddl.sql) với đầy đủ ràng buộc miền giá trị: giá $\ge 0$, min/max selection của option group, logic chi nhánh mở cửa qua đêm (cross-midnight), ràng buộc toàn vẹn khóa ngoại.
* **[SV2-03] Phân tích Phụ thuộc hàm & Chứng minh Chuẩn hóa**:
  * Đã viết báo cáo kỹ thuật chi tiết tại [docs/normalization_menu.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/normalization_menu.md), liệt kê chi tiết các FDs, xác định khóa ứng viên, và chứng minh toán học đạt chuẩn 1NF, 2NF, 3NF và BCNF cho toàn bộ 6 quan hệ.
* **[SV2-04] Xây dựng Dummy Data Script hoàn chỉnh**:
  * Đã xây dựng file [sql/sv2/menu_dummy_data.sql](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/sql/sv2/menu_dummy_data.sql) nạp dữ liệu mẫu chất lượng cao: 5 thương hiệu nhà hàng, 7 chi nhánh tại TP.HCM kèm tọa độ GPS thực tế, 8 danh mục thực đơn, 22 món ăn (vượt chỉ tiêu 20), 12 nhóm option và 39 tùy chọn chi tiết (vượt chỉ tiêu 30), hoàn toàn khớp với khóa ngoại của SV1.

#### B. Những công việc CHƯA LÀM (Tồn đọng):
* **[SV2-05] Kiểm thử chéo DDL của SV3**:
  * Chưa thực hiện được do SV3 **chưa nộp / chưa viết** kịch bản DDL phân hệ Vận hành & Thanh toán.

---

### 3. Sinh viên 3: Lương Công Phi (Kỹ sư CSDL, Vận hành & Xử lý GIS)

#### A. Những công việc ĐÃ LÀM ĐƯỢC:
* Đã phối hợp thảo luận phân chia danh mục bảng trong phân hệ tại tài liệu [docs/DRS.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/DRS.md) (đóng góp ý tưởng nghiệp vụ tài xế, thanh toán đa hình, log trạng thái).

#### B. Những công việc CHƯA LÀM (Tồn đọng - Cần đẩy nhanh tiến độ gấp):
* **[SV3-01] Nghiên cứu kỹ thuật Spatial GIS**:
  * Chưa có tài liệu/ghi chú kỹ thuật về công thức Haversine hoặc định dạng PostGIS geometry/geography và chỉ mục GiST.
* **[SV3-02] Mô hình EER Thanh toán**:
  * Chưa vẽ sơ đồ EER cho siêu lớp `PAYMENTS` và các phân lớp con (`CASH_PAYMENTS`, `CARD_PAYMENTS`, `EWALLET_PAYMENTS`) theo mô hình chuyên biệt hóa $\{d, t\}$.
* **[SV3-03] Data Dictionary & Kịch bản DDL Vận hành**:
  * Chưa có file Data Dictionary và script DDL cho 8 bảng thuộc trách nhiệm: `DRIVERS`, `PAYMENTS`, `CASH_PAYMENTS`, `CARD_PAYMENTS`, `EWALLET_PAYMENTS`, `ORDER_STATUS_LOGS`, `RESTAURANT_REVIEWS`, `DRIVER_REVIEWS`.
* **[SV3-04] Viết truy vấn Spatial Dispatching**:
  * Chưa viết câu truy vấn mẫu tính khoảng cách và lọc Top 5 tài xế ở trạng thái `AVAILABLE` gần nhà hàng nhất.
* **[SV3-05] Tích hợp kịch bản DDL tổng thể & Kiểm thử chéo**:
  * Chưa tạo file `schema_ddl_and_queries.sql` tổng hợp toàn bộ CSDL dự án.
  * Chưa kiểm thử chéo phần SQL phân hệ Người dùng của SV1.

---

## III. BẢNG THEO DÕI SẢN PHẨM BÀN GIAO THỰC TẾ (DELIVERABLES TRACKER)

Đối chiếu với Bảng mục số 4 trong kế hoạch phân công:

| STT | Sản phẩm bàn giao | Người phụ trách chính | Sản phẩm dự kiến | Trạng thái thực tế hiện tại | Ghi chú & Tệp tin liên quan |
| :---: | :--- | :--- | :--- | :---: | :--- |
| **1** | Bản DRS hoàn chỉnh & Data Dictionary | SV1 tổng hợp, nhóm đóng góp | File `.md` | 🟡 **Đạt 70%** | Đã có [docs/DRS.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/DRS.md) và Data Dictionary của SV2. Thiếu Data Dictionary của SV1 (phần Orders) và SV3. |
| **2** | Sơ đồ ER/EER & Giải thích Specialization | Cả 3 SV theo phân hệ | Mermaid / PDF | 🟡 **Đạt 65%** | Đã có [diagrams/eer_users.mmd](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/diagrams/eer_users.mmd) (SV1) và [diagrams/eer_menu.mmd](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/diagrams/eer_menu.mmd) (SV2). **Chưa có EER Payment** (SV3). |
| **3** | Mô hình quan hệ & Chứng minh chuẩn hóa (FDs) | SV2 chủ trì | Báo cáo 3NF/BCNF | 🟢 **Đạt 100%** | Đã hoàn thành xuất sắc tại [docs/normalization_menu.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/normalization_menu.md). |
| **4** | Kịch bản SQL DDL & 2 Truy vấn trọng tâm | Cả 3 người cùng làm, SV3 ghép | File `.sql` | 🔴 **Đạt 40%** | Đã có DDL Users (SV1) và DDL Menu (SV2). **Thiếu**: DDL Orders (SV1), DDL Drivers/Payments/Logs/Reviews (SV3), Query Join 4 bên (SV1), Query Spatial Dispatching (SV3), File SQL tổng hợp (SV3). |
| **5** | Script Dữ liệu mẫu (Dummy Data phù hợp FK) | SV2 chủ trì | File INSERT `.sql` | 🟢 **Đạt 100% (Phần Thực đơn)** | Đã hoàn thành xuất sắc tại [sql/sv2/menu_dummy_data.sql](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/sql/sv2/menu_dummy_data.sql). |
| **6** | Báo cáo kỹ thuật theo mẫu giảng viên | SV1 tổng hợp | File `.docx` / `.pdf` | ⚪ **Chưa làm (0%)** | Chưa bắt đầu tổng hợp bản Word/PDF hoàn chỉnh. |
| **7** | Slide thuyết trình & Kịch bản demo | Cả 3 SV | File `.pptx` | ⚪ **Chưa làm (0%)** | Dự kiến làm ở tuần cuối trước ngày bảo vệ. |

---

## IV. ĐỀ XUẤT HÀNH ĐỘNG TIẾP THEO (ACTION ITEMS)

1. **Ưu tiên số 1 - Thúc đẩy SV3**:
   * SV3 cần hoàn thành kịch bản DDL cho phân hệ Tài xế & Thanh toán (`DRIVERS`, `PAYMENTS`, `ORDER_STATUS_LOGS`, `REVIEWS`).
   * Viết câu truy vấn tính khoảng cách không gian (Haversine Formula) để tìm Top 5 tài xế gần chi nhánh.
2. **Ưu tiên số 2 - SV1 hoàn thiện phân hệ Đơn hàng**:
   * Bổ sung bảng `ORDERS`, `ORDER_ITEMS`, `ORDER_ITEM_OPTIONS` kèm cơ chế lưu snapshot đơn giá vào thư mục `sql/sv1/`.
   * Viết câu truy vấn Join 4 bên chi tiết đơn hàng.
3. **Ưu tiên số 3 - Ghép nối & Kiểm thử tích hợp toàn bộ CSDL**:
   * SV3 thu thập các file SQL từ SV1 và SV2 để ghép thành file `schema_ddl_and_queries.sql` duy nhất, chạy kiểm thử thứ tự tạo bảng từ bảng cha đến bảng con trên PostgreSQL để đảm bảo không lỗi khóa ngoại (Foreign Key).
