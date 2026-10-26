# NỀN TẢNG TỔNG HỢP GIAO ĐỒ ĂN (DOORDASH MODEL PLATFORM)
## DỰ ÁN MÔN HỌC CƠ SỞ DỮ LIỆU - NHÓM 3 SINH VIÊN

---

### 1. PHÂN CÔNG TRÁCH NHIỆM

* **SV1 - Bùi Duy Quang (Nhóm trưởng & Phân hệ Người dùng + Đơn hàng)**:
  * Xây dựng tài liệu Đặc tả yêu cầu CSDL tổng thể ([docs/DRS.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/DRS.md)).
  * Thiết kế sơ đồ EER phân hệ Người dùng ([diagrams/eer_users.mmd](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/diagrams/eer_users.mmd)) & Sơ đồ EER phân hệ Đơn hàng ([diagrams/eer_orders.mmd](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/diagrams/eer_orders.mmd)).
  * Xây dựng Data Dictionary phân hệ Đơn hàng ([docs/data_dictionary_orders.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/data_dictionary_orders.md)).
  * Viết kịch bản DDL phân hệ Người dùng ([sql/sv1/users_ddl.sql](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/sql/sv1/users_ddl.sql)) & DDL Đơn hàng ([sql/sv1/orders_ddl.sql](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/sql/sv1/orders_ddl.sql)).
  * Viết kịch bản nạp dữ liệu mẫu Đơn hàng ([sql/sv1/orders_dummy_data.sql](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/sql/sv1/orders_dummy_data.sql)).
  * Viết câu truy vấn trọng tâm Join 4 bên chi tiết đơn hàng ([sql/sv1/query_order_join_4_parties.sql](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/sql/sv1/query_order_join_4_parties.sql)).
  * Thực hiện kiểm thử chéo phân hệ Thực đơn của SV2 ([docs/test_report_sv1_cross_sv2.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/test_report_sv1_cross_sv2.md)).

* **SV2 - Phạm Đình Phúc (Phân hệ Thực đơn, Chuẩn hóa & Dữ liệu mẫu)**:
  * Thiết kế chuỗi 6 bảng Thực đơn ([diagrams/eer_menu.mmd](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/diagrams/eer_menu.mmd)).
  * Xây dựng Từ điển dữ liệu phân hệ Thực đơn ([docs/data_dictionary_menu.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/data_dictionary_menu.md)).
  * Phân tích phụ thuộc hàm (FDs) và chứng minh chuẩn hóa 3NF/BCNF ([docs/normalization_menu.md](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/docs/normalization_menu.md)).
  * Xây dựng kịch bản DDL Thực đơn ([sql/sv2/menu_ddl.sql](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/sql/sv2/menu_ddl.sql)) và nạp dữ liệu mẫu ([sql/sv2/menu_dummy_data.sql](file:///c:/Users/ASUS/Downloads/Project-database-main/Project-database-main/sql/sv2/menu_dummy_data.sql)).

* **SV3 - Lương Công Phi (Kỹ sư CSDL, Vận hành & Xử lý không gian GIS)**:
  * Phân hệ Tài xế (`DRIVERS`), Siêu lớp thanh toán EER (`PAYMENTS` và các phân lớp con).
  * Xử lý không gian GIS (Haversine / PostGIS GiST) và giải thuật Dispatching top 5 tài xế lân cận.
  * Ghép nối script tổng hợp và kiểm thử tích hợp.

---

### 2. CẤU TRÚC THƯ MỤC DỰ ÁN

```text
Project-database-main/
├── docs/
│   ├── DRS.md                          # Tài liệu đặc tả yêu cầu CSDL (P1)
│   ├── data_dictionary_orders.md       # Từ điển dữ liệu phân hệ Đơn hàng (SV1)
│   ├── data_dictionary_menu.md         # Từ điển dữ liệu phân hệ Thực đơn (SV2)
│   ├── normalization_menu.md           # Báo cáo chuẩn hóa 3NF & BCNF (SV2)
│   └── test_report_sv1_cross_sv2.md    # Biên bản kiểm thử chéo SV1 test SV2
├── diagrams/
│   ├── eer_users.mmd                   # Sơ đồ EER phân hệ Người dùng (SV1)
│   ├── eer_orders.mmd                  # Sơ đồ EER phân hệ Đơn hàng trung tâm (SV1)
│   └── eer_menu.mmd                    # Sơ đồ EER phân hệ Thực đơn (SV2)
├── sql/
│   ├── sv1/
│   │   ├── users_ddl.sql               # DDL và dữ liệu mẫu Người dùng (SV1)
│   │   ├── orders_ddl.sql              # DDL phân hệ Đơn hàng trung tâm (SV1)
│   │   ├── orders_dummy_data.sql       # Kịch bản nạp dữ liệu mẫu Đơn hàng (SV1)
│   │   └── query_order_join_4_parties.sql # Truy vấn Join 4 bên chi tiết đơn (SV1)
│   └── sv2/
│       ├── menu_ddl.sql                # DDL phân hệ Thực đơn & Nhà hàng (SV2)
│       └── menu_dummy_data.sql         # Kịch bản nạp dữ liệu mẫu Thực đơn (SV2)
├── BANG_PHAN_CHIA_CONG_VIEC_NHOM_3_NGUOI_UPDATED.docx
├── BAO_CAO_TIEN_DO_CONG_VIEC_NHOM.md
└── README.md
```

---

### 3. THỨ TỰ THỰC THI SCRIPT SQL (POSTGRESQL 14+ / 15 / 16)

Để đảm bảo không bị lỗi vi phạm khóa ngoại (Foreign Key), hãy thực thi tuần tự các file theo thứ tự sau:

1. **Khởi tạo cơ sở dữ liệu:**
   ```sql
   CREATE DATABASE food_delivery_db;
   \c food_delivery_db;
   ```

2. **Khởi tạo bảng & dữ liệu Người dùng (SV1):**
   * Chạy: `sql/sv1/users_ddl.sql`

3. **Khởi tạo bảng & dữ liệu Thực đơn / Nhà hàng (SV2):**
   * Chạy DDL: `sql/sv2/menu_ddl.sql`
   * Nạp dữ liệu: `sql/sv2/menu_dummy_data.sql`

4. **Khởi tạo bảng & dữ liệu Đơn hàng (SV1):**
   * Chạy DDL: `sql/sv1/orders_ddl.sql`
   * Nạp dữ liệu: `sql/sv1/orders_dummy_data.sql`

5. **Thực thi câu truy vấn trọng tâm Join 4 bên (SV1):**
   * Chạy file: `sql/sv1/query_order_join_4_parties.sql`
