# NỀN TẢNG TỔNG HỢP GIAO ĐỒ ĂN (DOORDASH MODEL PLATFORM)
## DỰ ÁN MÔN HỌC CƠ SỞ DỮ LIỆU - NHÓM 3 SINH VIÊN

---

### 1. PHÂN CÔNG TRÁCH NHIỆM
* **SV1 - Bùi Duy Quang (Nhóm trưởng & Phân hệ Người dùng + Đơn hàng)**:
  * Xây dựng tài liệu Đặc tả yêu cầu CSDL ([docs/DRS.md](file:///c:/Users/ASUS/Documents/School/New%20folder/database/docs/DRS.md)).
  * Thiết kế sơ đồ EER phân hệ Người dùng ([diagrams/eer_users.mmd](file:///c:/Users/ASUS/Documents/School/New%20folder/database/diagrams/eer_users.mmd)).
  * Xây dựng Data Dictionary và kịch bản DDL phân hệ Người dùng ([sql/sv1/users_ddl.sql](file:///c:/Users/ASUS/Documents/School/New%20folder/database/sql/sv1/users_ddl.sql)).
  * Đơn hàng trung tâm và câu truy vấn Join 4 bên chi tiết đơn hàng (giai đoạn tiếp theo).
* **SV2 - Phạm Đình Phúc (Phân hệ Thực đơn, Chuẩn hóa & Dữ liệu mẫu)**:
  * Thiết kế chuỗi 6 bảng Thực đơn (`RESTAURANTS`, `BRANCHES`, `CATEGORIES`, `ITEMS`, `OPTION_GROUPS`, `OPTION_ITEMS`).
  * Phân tích phụ thuộc hàm (FDs) và chứng minh chuẩn hóa 3NF/BCNF.
  * Xây dựng kịch bản nạp dữ liệu mẫu (Dummy data).
* **SV3 - Lương Công Phi (Kỹ sư CSDL, Vận hành & Xử lý không gian GIS)**:
  * Phân hệ Tài xế (`DRIVERS`), Siêu lớp thanh toán EER (`PAYMENTS` và các phân lớp con).
  * Xử lý không gian GIS (Haversine / PostGIS GiST) và giải thuật Dispatching top 5 tài xế lân cận.
  * Ghép nối script tổng hợp và kiểm thử tích hợp.

---

### 2. CẤU TRÚC THƯ MỤC DỰ ÁN
```text
database/
├── docs/
│   └── DRS.md                   # Tài liệu đặc tả yêu cầu CSDL (P1)
├── diagrams/
│   └── eer_users.mmd            # Sơ đồ EER phân hệ người dùng Mermaid (P2)
├── sql/
│   └── sv1/
│       └── users_ddl.sql        # Script DDL, ràng buộc và dữ liệu mẫu kiểm thử
├── BANG_PHAN_CHIA_CONG_VIEC_NHOM_3_NGUOI_UPDATED.docx
├── task.md
└── README.md
```

---

### 3. HƯỚNG DẪN CÀI ĐẶT & KIỂM THỬ SCRIPT SQL
Hệ quản trị CSDL: **PostgreSQL 14+ / 15 / 16**

1. Khởi động PostgreSQL (pgAdmin 4, DBeaver, hoặc terminal `psql`).
2. Tạo CSDL mới:
   ```sql
   CREATE DATABASE food_delivery_db;
   \c food_delivery_db;
   ```
3. Mở và thực thi file `sql/sv1/users_ddl.sql`.
4. Xem kết quả truy vấn kiểm chứng và kiểm tra các ràng buộc toàn vẹn dữ liệu.
