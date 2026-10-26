# BIÊN BẢN KIỂM THỬ ĐỘC LẬP KỊCH BẢN SQL PHÂN HỆ THỰC ĐƠN (SV2)
**Dự án**: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)  
**Người thực hiện kiểm thử (Tester)**: SV1 — Bùi Duy Quang (Nhóm trưởng)  
**Tác giả kịch bản (Developer)**: SV2 — Phạm Đình Phúc  
**Đối tượng kiểm thử**:  
- `sql/sv2/menu_ddl.sql` (Kịch bản tạo bảng & ràng buộc)  
- `sql/sv2/menu_dummy_data.sql` (Kịch bản nạp dữ liệu mẫu)  
- `docs/data_dictionary_menu.md` (Từ điển dữ liệu)  
**Môi trường kiểm thử**: PostgreSQL 16.x  
**Ngày kiểm thử**: 26/10/2026  

---

## 1. MỤC TIÊU KIỂM THỬ
Thực hiện quy trình kiểm thử chéo theo đúng thỏa thuận tại Mục 2 trong văn bản phân công nhiệm vụ:
- Kiểm tra tính tương thích cú pháp trên PostgreSQL.
- Kiểm tra thứ tự tạo và xóa bảng (Tuân thủ ràng buộc toàn vẹn khóa ngoại).
- Kiểm tra các ràng buộc nghiệp vụ (CHECK constraint, Unique constraint, Default value).
- Đối soát tính tương thích khóa ngoại `owner_id` kết nối sang bảng `merchant_owners` do SV1 quản lý.

---

## 2. KẾT QUẢ KIỂM THỬ CHI TIẾT (TEST CASES)

| Mã Test | Nội dung kiểm thử | Kỳ vọng | Kết quả thực tế | Trạng thái |
| :---: | :--- | :--- | :--- | :---: |
| **TC-01** | Chạy script dọn dẹp `DROP TABLE ... CASCADE` | Xóa sạch 6 bảng con và cha mà không vướng lỗi FK | Đã dọn dẹp thành công | 🟢 **PASS** |
| **TC-02** | Khởi tạo 6 bảng phân cấp thực đơn (`menu_ddl.sql`) | Tạo bảng thành công theo đúng thứ tự: `restaurants` $\to$ `branches` $\to$ `categories` $\to$ `items` $\to$ `option_groups` $\to$ `option_items` | Toàn bộ 6 bảng và index được tạo chính xác | 🟢 **PASS** |
| **TC-03** | Ràng buộc khóa ngoại `restaurants(owner_id)` | Chỉ chấp nhận `owner_id` hợp lệ từ `merchant_owners` | Khóa ngoại chặn thành công khi chèn owner_id không tồn tại | 🟢 **PASS** |
| **TC-04** | Ràng buộc nghiệp vụ giờ mở/đóng cửa (`branches`) | Chấp nhận cả trường hợp quán hoạt động xuyên đêm (Ví dụ: 18:00 đến 02:00 sáng hôm sau) | Ràng buộc xử lý linh hoạt, chi nhánh 5 chạy tốt | 🟢 **PASS** |
| **TC-05** | Ràng buộc miền giá trị không âm (`base_price >= 0`, `extra_price >= 0`) | Chặn mọi giao dịch thêm món hoặc topping có giá trị âm | PostgreSQL kích hoạt CHECK constraint vi phạm như mong đợi | 🟢 **PASS** |
| **TC-06** | Ràng buộc số lượng chọn option (`min_selection <= max_selection`) | Chặn cấu hình nhóm tùy chọn có số chọn tối thiểu lớn hơn tối đa | Ràng buộc kích hoạt chặn lỗi logic | 🟢 **PASS** |
| **TC-07** | Thực thi kịch bản nạp Dummy Data (`menu_dummy_data.sql`) | Nạp đầy đủ 5 nhà hàng, 7 chi nhánh, 8 danh mục, 22 món, 12 nhóm option và 39 lựa chọn | Dữ liệu nạp mượt mà, đầy đủ, không phát sinh lỗi trùng khóa hay thiếu dữ liệu cha | 🟢 **PASS** |

---

## 3. KẾT LUẬN & ĐÁNH GIÁ CHUNG
* Kịch bản DDL và Dữ liệu mẫu của **SV2 (Phạm Đình Phúc)** đạt chuẩn kỹ thuật cao, viết rõ ràng, có ghi chú chi tiết và tuân thủ nghiêm ngặt chuẩn PostgreSQL.
* Đạt chuẩn tương thích hoàn toàn để tích hợp cùng phân hệ Đơn hàng của SV1.
* **Xác nhận nghiệm thu**: Đạt yêu cầu đưa vào kịch bản CSDL chung của dự án.
