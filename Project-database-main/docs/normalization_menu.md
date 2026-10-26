# BÁO CÁO PHÂN TÍCH PHỤ THUỘC HÀM VÀ CHỨNG MINH CHUẨN HÓA (3NF & BCNF)

* **Dự án**: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
* **Học phần**: Cơ sở dữ liệu
* **Phân hệ**: Nhà hàng & Thực đơn (Menu Subsystem)
* **Sinh viên phụ trách**: SV2 — Phạm Đình Phúc
* **Hệ quản trị CSDL mục tiêu**: PostgreSQL 14+ / 15 / 16

---

## 1. MỤC TIÊU VÀ NGUYÊN TẮC PHÂN TÍCH

Báo cáo này tiến hành hình thức hóa toàn bộ các phụ thuộc hàm (Functional Dependencies - FDs) dựa trên cơ sở quy tắc nghiệp vụ thực tế (Business Rules), xác định các khóa ứng viên (Candidate Keys), và chứng minh tuần tự các dạng chuẩn **1NF, 2NF, 3NF** và **BCNF (Boyce-Codd Normal Form)** cho chuỗi 6 quan hệ:
1. `RESTAURANTS`
2. `BRANCHES`
3. `CATEGORIES`
4. `ITEMS`
5. `OPTION_GROUPS`
6. `OPTION_ITEMS`

---

## 2. PHÂN TÍCH CHI TIẾT TỪNG QUAN HỆ

### 2.1. Quan hệ `RESTAURANTS` (Thương hiệu nhà hàng)

#### A. Lược đồ thuộc tính
$$R_1(\underline{\text{restaurant\_id}}, \text{owner\_id}, \text{restaurant\_name}, \text{cuisine\_type}, \text{description}, \text{logo\_url}, \text{banner\_url}, \text{is\_active}, \text{created\_at}, \text{updated\_at})$$

#### B. Phân tích Phụ thuộc hàm (FDs) và Giả định nghiệp vụ
* **Giả định nghiệp vụ**:
  * Mỗi nhà hàng được hệ thống cấp một mã định danh duy nhất `restaurant_id`. Khi biết `restaurant_id`, xác định chính xác chủ sở hữu (`owner_id`), tên quán, loại ẩm thực, mô tả, ảnh và trạng thái hoạt động.
  * Tên thương hiệu `restaurant_name` có thể trùng nhau trong trường hợp nhượng quyền hoặc chuỗi quán có nhiều đơn vị kinh doanh độc lập, nên `restaurant_name` không thể làm khóa.
* **Tập phụ thuộc hàm $F_1$**:
  $$FD_{1.1}: \text{restaurant\_id} \longrightarrow \{\text{owner\_id}, \text{restaurant\_name}, \text{cuisine\_type}, \text{description}, \text{logo\_url}, \text{banner\_url}, \text{is\_active}, \text{created\_at}, \text{updated\_at}\}$$

#### C. Xác định Khóa và Phân loại thuộc tính
* **Khóa ứng viên ($CK$)**: $CK = \{\text{restaurant\_id}\}$
* **Khóa chính ($PK$)**: $\text{restaurant\_id}$
* **Thuộc tính khóa (Prime Attributes)**: $\{\text{restaurant\_id}\}$
* **Thuộc tính không khóa (Non-prime Attributes)**: Toàn bộ 9 thuộc tính còn lại.

#### D. Chứng minh dạng chuẩn
* **1NF**: Mọi thuộc tính đều chứa giá trị nguyên tố (Atomic), không chứa danh sách hay mảng phức hợp. $\Rightarrow$ **Đạt 1NF**.
* **2NF**: Khóa ứng viên là khóa đơn gồm 1 thuộc tính duy nhất ($\text{restaurant\_id}$). Do đó, không thể tồn tại thuộc tính không khóa nào phụ thuộc vào một bộ phận của khóa. $\Rightarrow$ **Đạt 2NF**.
* **3NF**: Không có phụ thuộc bắc cầu $X \rightarrow Y \rightarrow Z$ giữa các thuộc tính không khóa. Với phụ thuộc hàm duy nhất $FD_{1.1}$, vế trái $X = \text{restaurant\_id}$ là Siêu khóa (Superkey). $\Rightarrow$ **Đạt 3NF**.
* **BCNF**: Với mọi phụ thuộc hàm không tầm thường $X \rightarrow A$, vế trái $X = \{\text{restaurant\_id}\}$ là Siêu khóa. $\Rightarrow$ **Đạt BCNF**.

---

### 2.2. Quan hệ `BRANCHES` (Chi nhánh nhà hàng)

#### A. Lược đồ thuộc tính
$$R_2(\underline{\text{branch\_id}}, \text{restaurant\_id}, \text{branch\_name}, \text{phone\_number}, \text{street\_address}, \text{ward}, \text{district}, \text{city}, \text{latitude}, \text{longitude}, \text{opening\_time}, \text{closing\_time}, \text{is\_active}, \text{created\_at}, \text{updated\_at})$$

#### B. Phân tích Phụ thuộc hàm (FDs) và Giả định nghiệp vụ
* **Giả định nghiệp vụ**:
  * Mã chi nhánh `branch_id` xác định duy nhất toàn bộ thông tin chi nhánh.
  * Trong cùng một thương hiệu nhà hàng (`restaurant_id`), tên chi nhánh không được phép trùng nhau để khách hàng và tài xế phân biệt (quy tắc `UNIQUE (restaurant_id, branch_name)`).
  * *Về địa chỉ*: Ở Việt Nam, tên phường/xã có thể trùng giữa các quận (ví dụ: Phường 1, Phường 2, Tân Phú...), do đó $\text{ward} \not\rightarrow \text{district}$. Tọa độ GPS (`latitude`, `longitude`) là thuộc tính đo lường của địa chỉ vật lý, không tạo thành khóa thay thế vì độ nhiễu số học.
* **Tập phụ thuộc hàm $F_2$**:
  $$FD_{2.1}: \text{branch\_id} \longrightarrow \{\text{restaurant\_id}, \text{branch\_name}, \text{phone\_number}, \text{street\_address}, \text{ward}, \text{district}, \text{city}, \text{latitude}, \text{longitude}, \text{opening\_time}, \text{closing\_time}, \text{is\_active}, \text{created\_at}, \text{updated\_at}\}$$
  $$FD_{2.2}: \{\text{restaurant\_id}, \text{branch\_name}\} \longrightarrow \{\text{branch\_id}, \text{phone\_number}, \text{street\_address}, \text{ward}, \text{district}, \text{city}, \text{latitude}, \text{longitude}, \text{opening\_time}, \text{closing\_time}, \text{is\_active}, \text{created\_at}, \text{updated\_at}\}$$

#### C. Xác định Khóa và Phân loại thuộc tính
* **Khóa ứng viên ($CK$)**:
  * $CK_1 = \{\text{branch\_id}\}$
  * $CK_2 = \{\text{restaurant\_id}, \text{branch\_name}\}$
* **Khóa chính ($PK$)**: $\text{branch\_id}$
* **Thuộc tính khóa**: $\{\text{branch\_id}, \text{restaurant\_id}, \text{branch\_name}\}$
* **Thuộc tính không khóa**: $\{\text{phone\_number}, \text{street\_address}, \text{ward}, \text{district}, \text{city}, \text{latitude}, \text{longitude}, \text{opening\_time}, \text{closing\_time}, \text{is\_active}, \text{created\_at}, \text{updated\_at}\}$

#### D. Chứng minh dạng chuẩn
* **1NF**: Các trường lưu dữ liệu đơn lẻ, tọa độ số thực chuẩn WGS-84 nguyên tố. $\Rightarrow$ **Đạt 1NF**.
* **2NF**: Không có thuộc tính không khóa nào phụ thuộc vào chỉ riêng `restaurant_id` hay chỉ riêng `branch_name` (chỉ có sự kết hợp của cả hai mới xác định địa chỉ và hotline cụ thể). Do đó không có phụ thuộc bộ phận. $\Rightarrow$ **Đạt 2NF**.
* **3NF**: Không có phụ thuộc bắc cầu giữa các thuộc tính không khóa. Trong cả hai phụ thuộc hàm $FD_{2.1}$ và $FD_{2.2}$, vế trái đều là Siêu khóa. $\Rightarrow$ **Đạt 3NF**.
* **BCNF**: Cả hai tập thuộc tính ở vế trái $(\{\text{branch\_id}\}$ và $\{\text{restaurant\_id}, \text{branch\_name}\})$ đều là Siêu khóa. $\Rightarrow$ **Đạt BCNF**.

---

### 2.3. Quan hệ `CATEGORIES` (Danh mục thực đơn)

#### A. Lược đồ thuộc tính
$$R_3(\underline{\text{category\_id}}, \text{restaurant\_id}, \text{category\_name}, \text{display\_order}, \text{is\_active}, \text{created\_at})$$

#### B. Phân tích Phụ thuộc hàm (FDs) và Giả định nghiệp vụ
* **Giả định nghiệp vụ**:
  * Mỗi danh mục được định danh bởi `category_id`.
  * Một nhà hàng không thể tạo hai danh mục trùng tên nhau (`UNIQUE(restaurant_id, category_name)`).
* **Tập phụ thuộc hàm $F_3$**:
  $$FD_{3.1}: \text{category\_id} \longrightarrow \{\text{restaurant\_id}, \text{category\_name}, \text{display\_order}, \text{is\_active}, \text{created\_at}\}$$
  $$FD_{3.2}: \{\text{restaurant\_id}, \text{category\_name}\} \longrightarrow \{\text{category\_id}, \text{display\_order}, \text{is\_active}, \text{created\_at}\}$$

#### C. Xác định Khóa và Phân loại thuộc tính
* **Khóa ứng viên ($CK$)**:
  * $CK_1 = \{\text{category\_id}\}$
  * $CK_2 = \{\text{restaurant\_id}, \text{category\_name}\}$
* **Khóa chính ($PK$)**: $\text{category\_id}$
* **Thuộc tính khóa**: $\{\text{category\_id}, \text{restaurant\_id}, \text{category\_name}\}$
* **Thuộc tính không khóa**: $\{\text{display\_order}, \text{is\_active}, \text{created\_at}\}$

#### D. Chứng minh dạng chuẩn
* **1NF**: Dữ liệu nguyên tố $\Rightarrow$ **Đạt 1NF**.
* **2NF**: Thuộc tính không khóa phụ thuộc đầy đủ vào toàn bộ khóa ứng viên $\Rightarrow$ **Đạt 2NF**.
* **3NF**: Vế trái của mọi FD đều là Siêu khóa $\Rightarrow$ **Đạt 3NF**.
* **BCNF**: Không tồn tại FD nào có vế trái không phải siêu khóa $\Rightarrow$ **Đạt BCNF**.

---

### 2.4. Quan hệ `ITEMS` (Món ăn / Đồ uống niêm yết)

#### A. Lược đồ thuộc tính
$$R_4(\underline{\text{item\_id}}, \text{category\_id}, \text{item\_name}, \text{description}, \text{base\_price}, \text{image\_url}, \text{is\_available}, \text{display\_order}, \text{created\_at}, \text{updated\_at})$$

#### B. Phân tích Phụ thuộc hàm (FDs) và Quyết định thiết kế cốt lõi
* **Quyết định thiết kế chống vi phạm chuẩn hóa**:
  * Trong thiết kế ban đầu, có thể một số người sẽ thêm thuộc tính `restaurant_id` vào bảng `ITEMS`. Nếu làm như vậy, ta sẽ có chuỗi phụ thuộc:
    $$\text{item\_id} \longrightarrow \text{category\_id} \quad \text{và} \quad \text{category\_id} \longrightarrow \text{restaurant\_id}$$
    Dẫn đến phụ thuộc bắc cầu: $\text{item\_id} \longrightarrow \text{restaurant\_id}$ (Vi phạm nghiêm trọng 3NF và BCNF do dư thừa dữ liệu!).
  * Thiết kế hiện tại của SV2 đã **loại bỏ hoàn toàn** thuộc tính `restaurant_id` khỏi `ITEMS`, chỉ lưu `category_id`. Để biết món ăn thuộc nhà hàng nào, ta thực hiện phép kết tự nhiên (Natural Join) qua `categories(category_id)`, bảo đảm triệt tiêu dị thường cập nhật (Update Anomaly).
* **Tập phụ thuộc hàm $F_4$**:
  $$FD_{4.1}: \text{item\_id} \longrightarrow \{\text{category\_id}, \text{item\_name}, \text{description}, \text{base\_price}, \text{image\_url}, \text{is\_available}, \text{display\_order}, \text{created\_at}, \text{updated\_at}\}$$
  $$FD_{4.2}: \{\text{category\_id}, \text{item\_name}\} \longrightarrow \{\text{item\_id}, \text{description}, \text{base\_price}, \text{image\_url}, \text{is\_available}, \text{display\_order}, \text{created\_at}, \text{updated\_at}\}$$

#### C. Xác định Khóa và Phân loại thuộc tính
* **Khóa ứng viên ($CK$)**:
  * $CK_1 = \{\text{item\_id}\}$
  * $CK_2 = \{\text{category\_id}, \text{item\_name}\}$
* **Khóa chính ($PK$)**: $\text{item\_id}$
* **Thuộc tính khóa**: $\{\text{item\_id}, \text{category\_id}, \text{item\_name}\}$
* **Thuộc tính không khóa**: $\{\text{description}, \text{base\_price}, \text{image\_url}, \text{is\_available}, \text{display\_order}, \text{created\_at}, \text{updated\_at}\}$

#### D. Chứng minh dạng chuẩn
* **1NF**: Các cột chứa giá trị nguyên tố, `base_price` là số thập phân độc lập $\Rightarrow$ **Đạt 1NF**.
* **2NF**: Không có thuộc tính không khóa nào phụ thuộc vào chỉ riêng `category_id` hay chỉ riêng `item_name` $\Rightarrow$ **Đạt 2NF**.
* **3NF**: Không có phụ thuộc bắc cầu giữa các thuộc tính không khóa. Vế trái của mọi FD là Siêu khóa $\Rightarrow$ **Đạt 3NF**.
* **BCNF**: Vế trái của cả $FD_{4.1}$ và $FD_{4.2}$ đều là Siêu khóa $\Rightarrow$ **Đạt BCNF**.

---

### 2.5. Quan hệ `OPTION_GROUPS` (Nhóm tùy chọn của món)

#### A. Lược đồ thuộc tính
$$R_5(\underline{\text{group\_id}}, \text{item\_id}, \text{group\_name}, \text{min\_selection}, \text{max\_selection}, \text{is\_required}, \text{display\_order}, \text{created\_at})$$

#### B. Phân tích Phụ thuộc hàm (FDs) và Giả định nghiệp vụ
* **Giả định nghiệp vụ**:
  * Mỗi nhóm tùy chọn gắn vào 1 món ăn xác định (`item_id`).
  * Trong cùng một món ăn, tên nhóm tùy chọn không được trùng nhau (`UNIQUE(item_id, group_name)`).
  * Về trường `is_required`: Về mặt logic, `is_required` phản ánh `min_selection >= 1`. Tuy nhiên, trong mô hình quan hệ, đây là cờ chỉ báo trạng thái (flag) để client xử lý nhanh không cần parse biểu thức, phụ thuộc đầy đủ vào nhóm tùy chọn.
* **Tập phụ thuộc hàm $F_5$**:
  $$FD_{5.1}: \text{group\_id} \longrightarrow \{\text{item\_id}, \text{group\_name}, \text{min\_selection}, \text{max\_selection}, \text{is\_required}, \text{display\_order}, \text{created\_at}\}$$
  $$FD_{5.2}: \{\text{item\_id}, \text{group\_name}\} \longrightarrow \{\text{group\_id}, \text{min\_selection}, \text{max\_selection}, \text{is\_required}, \text{display\_order}, \text{created\_at}\}$$

#### C. Xác định Khóa và Phân loại thuộc tính
* **Khóa ứng viên ($CK$)**:
  * $CK_1 = \{\text{group\_id}\}$
  * $CK_2 = \{\text{item\_id}, \text{group\_name}\}$
* **Khóa chính ($PK$)**: $\text{group\_id}$
* **Thuộc tính khóa**: $\{\text{group\_id}, \text{item\_id}, \text{group\_name}\}$
* **Thuộc tính không khóa**: $\{\text{min\_selection}, \text{max\_selection}, \text{is\_required}, \text{display\_order}, \text{created\_at}\}$

#### D. Chứng minh dạng chuẩn
* **1NF**: Dữ liệu nguyên tố $\Rightarrow$ **Đạt 1NF**.
* **2NF**: Không có phụ thuộc bộ phận vào tập con của khóa $\Rightarrow$ **Đạt 2NF**.
* **3NF**: Vế trái của mọi FD là Siêu khóa $\Rightarrow$ **Đạt 3NF**.
* **BCNF**: Vế trái của mọi FD đều là Siêu khóa $\Rightarrow$ **Đạt BCNF**.

---

### 2.6. Quan hệ `OPTION_ITEMS` (Chi tiết lựa chọn kèm phụ thu)

#### A. Lược đồ thuộc tính
$$R_6(\underline{\text{option\_item\_id}}, \text{group\_id}, \text{option\_name}, \text{extra\_price}, \text{is\_available}, \text{display\_order}, \text{created\_at})$$

#### B. Phân tích Phụ thuộc hàm (FDs) và Giả định nghiệp vụ
* **Giả định nghiệp vụ**:
  * Mỗi lựa chọn có định danh `option_item_id`.
  * Trong cùng một nhóm tùy chọn, tên lựa chọn không được phép trùng nhau (`UNIQUE(group_id, option_name)`).
* **Tập phụ thuộc hàm $F_6$**:
  $$FD_{6.1}: \text{option\_item\_id} \longrightarrow \{\text{group\_id}, \text{option\_name}, \text{extra\_price}, \text{is\_available}, \text{display\_order}, \text{created\_at}\}$$
  $$FD_{6.2}: \{\text{group\_id}, \text{option\_name}\} \longrightarrow \{\text{option\_item\_id}, \text{extra\_price}, \text{is\_available}, \text{display\_order}, \text{created\_at}\}$$

#### C. Xác định Khóa và Phân loại thuộc tính
* **Khóa ứng viên ($CK$)**:
  * $CK_1 = \{\text{option\_item\_id}\}$
  * $CK_2 = \{\text{group\_id}, \text{option\_name}\}$
* **Khóa chính ($PK$)**: $\text{option\_item\_id}$
* **Thuộc tính khóa**: $\{\text{option\_item\_id}, \text{group\_id}, \text{option\_name}\}$
* **Thuộc tính không khóa**: $\{\text{extra\_price}, \text{is\_available}, \text{display\_order}, \text{created\_at}\}$

#### D. Chứng minh dạng chuẩn
* **1NF**: Các trường phụ thu `extra_price` mang giá trị số học nguyên tố $\Rightarrow$ **Đạt 1NF**.
* **2NF**: Không có phụ thuộc hàm bộ phận $\Rightarrow$ **Đạt 2NF**.
* **3NF**: Vế trái của mọi FD đều là Siêu khóa $\Rightarrow$ **Đạt 3NF**.
* **BCNF**: Mọi vế trái đều là Siêu khóa $\Rightarrow$ **Đạt BCNF**.

---

## 3. BẢNG TỔNG HỢP ĐÁNH GIÁ CHUẨN HÓA TOÀN BỘ 6 QUAN HỆ

| STT | Tên bảng | Khóa ứng viên (CK) | Khóa chính (PK) | 1NF | 2NF | 3NF | BCNF | Lý do kết luận BCNF |
| :---: | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **1** | `RESTAURANTS` | $\{\text{restaurant\_id}\}$ | `restaurant_id` | **Thỏa** | **Thỏa** | **Thỏa** | **Thỏa** | Vế trái duy nhất là siêu khóa |
| **2** | `BRANCHES` | $\{\text{branch\_id}\}$, $\{\text{restaurant\_id}, \text{branch\_name}\}$ | `branch_id` | **Thỏa** | **Thỏa** | **Thỏa** | **Thỏa** | Vế trái của cả 2 FDs đều là siêu khóa |
| **3** | `CATEGORIES` | $\{\text{category\_id}\}$, $\{\text{restaurant\_id}, \text{category\_name}\}$ | `category_id` | **Thỏa** | **Thỏa** | **Thỏa** | **Thỏa** | Vế trái của cả 2 FDs đều là siêu khóa |
| **4** | `ITEMS` | $\{\text{item\_id}\}$, $\{\text{category\_id}, \text{item\_name}\}$ | `item_id` | **Thỏa** | **Thỏa** | **Thỏa** | **Thỏa** | Không lưu dư thừa `restaurant_id`, vế trái FDs là siêu khóa |
| **5** | `OPTION_GROUPS` | $\{\text{group\_id}\}$, $\{\text{item\_id}, \text{group\_name}\}$ | `group_id` | **Thỏa** | **Thỏa** | **Thỏa** | **Thỏa** | Vế trái của cả 2 FDs đều là siêu khóa |
| **6** | `OPTION_ITEMS` | $\{\text{option\_item\_id}\}$, $\{\text{group\_id}, \text{option\_name}\}$ | `option_item_id` | **Thỏa** | **Thỏa** | **Thỏa** | **Thỏa** | Vế trái của cả 2 FDs đều là siêu khóa |

---

## 4. KẾT LUẬN VỀ THIẾT KẾ CSDL PHÂN HỆ THỰC ĐƠN

1. **Tính bảo toàn thông tin (Lossless Join)**:
   Chuỗi quan hệ phân cấp từ `RESTAURANTS` $\rightarrow$ `BRANCHES` và `RESTAURANTS` $\rightarrow$ `CATEGORIES` $\rightarrow$ `ITEMS` $\rightarrow$ `OPTION_GROUPS` $\rightarrow$ `OPTION_ITEMS` liên kết thông qua các Khóa chính - Khóa ngoại đối ứng. Phép kết tự nhiên đảm bảo tái tạo chính xác 100% dữ liệu gốc mà không sinh ra bộ giả (Spurious Tuples).
2. **Tính bảo toàn phụ thuộc hàm (Dependency Preservation)**:
   Toàn bộ các phụ thuộc hàm nghiệp vụ được bảo toàn trọn vẹn trong phạm vi từng bảng thông qua các ràng buộc `PRIMARY KEY` và `UNIQUE INDEX`.
3. **Không phát sinh dư thừa dữ liệu**:
   Việc thiết kế chặt chẽ, loại bỏ thuộc tính trôi nổi và tách bạch thực đơn theo từng tầng đã giúp hệ thống đạt chuẩn cao nhất (**BCNF**), ngăn ngừa hoàn toàn các bất thường thêm, xóa, sửa (Insert, Delete, Update Anomalies).
