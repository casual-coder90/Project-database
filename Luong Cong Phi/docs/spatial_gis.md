# NGHIÊN CỨU KỸ THUẬT XỬ LÝ KHÔNG GIAN (SPATIAL GIS) & THUẬT TOÁN ĐIỀU PHỐI TÀI XẾ

* **Dự án**: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
* **Học phần**: Cơ sở dữ liệu
* **Phân hệ**: Vận hành & Kỹ thuật GIS (Operations & Spatial Dispatching Subsystem)
* **Sinh viên phụ trách**: SV3 — Lương Công Phi
* **Hệ quản trị CSDL mục tiêu**: PostgreSQL 14+ / 15 / 16

---

## 1. BỐI CẢNH BÀI TOÁN ĐIỀU PHỐI (DISPATCHING PROBLEM)

Trong nền tảng giao đồ ăn như DoorDash hay GrabFood, khi một đơn hàng được nhà hàng xác nhận chế biến (`PREPARING`), hệ thống cần ngay lập tức tìm kiếm và chỉ định các đối tác tài xế (Dashers/Drivers) phù hợp nhất để giao cuốc xe. 

Bài toán cốt lõi:
> **Tìm Top 5 tài xế đang ở trạng thái sẵn sàng (`driver_status = 'AVAILABLE'`) có khoảng cách địa lý gần nhất tới vị trí nhà hàng/chi nhánh (`branches`).**

Để giải quyết bài toán trên lớp CSDL, kỹ sư dữ liệu cần lựa chọn phương pháp tính toán khoảng cách trên bề mặt cong của Trái Đất và cấu hình chỉ mục tối ưu hiệu năng truy vấn.

---

## 2. CƠ SỞ TOÁN HỌC: CÔNG THỨC HAVERSINE

### 2.1. Bản chất hình học
Trái Đất là một khối phỏng cầu (Ellipsoid/Geoid), tuy nhiên ở quy mô giao hàng nội đô (bán kính dưới $30\text{ km}$), Trái Đất có thể được xấp xỉ chính xác bằng hình cầu với bán kính trung bình:
$$R \approx 6.371\text{ km} \quad (6.371.000\text{ m})$$

Giả sử hai điểm trên bề mặt Trái Đất có tọa độ địa lý:
* Điểm 1 (Nhà hàng): Vĩ độ $\varphi_1$, Kinh độ $\lambda_1$
* Điểm 2 (Tài xế): Vĩ độ $\varphi_2$, Kinh độ $\lambda_2$

Khoảng cách góc trên cung tròn lớn (Great-Circle Distance) giữa hai điểm được xác định bởi công thức Haversine:

$$a = \sin^2\left(\frac{\Delta \varphi}{2}\right) + \cos(\varphi_1) \cdot \cos(\varphi_2) \cdot \sin^2\left(\frac{\Delta \lambda}{2}\right)$$

$$c = 2 \cdot \arcsin\left(\min(1, \sqrt{a})\right) = 2 \cdot \operatorname{atan2}\left(\sqrt{a}, \sqrt{1-a}\right)$$

$$d = R \cdot c$$

Trong đó:
* $\Delta \varphi = \varphi_2 - \varphi_1$ (chênh lệch vĩ độ tính theo Radians).
* $\Delta \lambda = \lambda_2 - \lambda_1$ (chênh lệch kinh độ tính theo Radians).
* Hàm $\min(1, \sqrt{a})$ là bước kẹp an toàn số học (Numerical Clamping) nhằm loại bỏ lỗi làm tròn số thực dấu phẩy động (Floating-point roundoff error) khi hai điểm nằm sát nhau hoặc đối đỉnh.

### 2.2. Chuyển đổi đơn vị và cài đặt trong PostgreSQL
Trong SQL, các hàm lượng giác chuẩn (`SIN`, `COS`) nhận tham số đầu vào là **Radian**, trong khi tọa độ GPS lưu trên CSDL là **Độ thập phân (Decimal Degrees)**:
$$\text{Radian} = \text{Degrees} \times \frac{\pi}{180} = \operatorname{RADIANS}(\text{Degrees})$$

Biểu thức SQL Haversine chuẩn tính ra khoảng cách Kilomet (km) trong PostgreSQL:
```sql
6371.0 * 2.0 * ASIN(
    SQRT(
        POWER(SIN(RADIANS(d.current_lat - b.latitude) / 2.0), 2) +
        COS(RADIANS(b.latitude)) * COS(RADIANS(d.current_lat)) *
        POWER(SIN(RADIANS(d.current_long - b.longitude) / 2.0), 2)
    )
) AS distance_km
```

---

## 3. SO SÁNH CÁC PHƯƠNG PHÁP XỬ LÝ KHÔNG GIAN TRÊN POSTGRESQL

| Tiêu chí | Phương án 1: Haversine thuần SQL | Phương án 2: PostgreSQL mở rộng PostGIS |
| :--- | :--- | :--- |
| **Bản chất lưu trữ** | Lưu 2 cột riêng biệt `latitude` và `longitude` kiểu số thực `DECIMAL(10, 8)` / `DECIMAL(11, 8)` | Lưu 1 cột không gian kiểu `GEOGRAPHY(Point, 4326)` hoặc `GEOMETRY(Point, 4326)` |
| **Phụ thuộc môi trường** | **Không cần Extension**. Chạy được trên 100% các phiên bản PostgreSQL tiêu chuẩn, Docker, pgAdmin, DBeaver | **Bắt buộc cài đặt Extension PostGIS** (`CREATE EXTENSION postgis;`), đòi hỏi quyền Superuser/DBA |
| **Hàm tính khoảng cách** | Biểu thức toán học lượng giác trực tiếp | Hàm tối ưu sẵn: `ST_Distance(geom1, geom2)` |
| **Cơ chế lập chỉ mục** | B-Tree Index (đơn cột, đa cột, hoặc Partial Index lọc theo trạng thái) | **GiST Index (Generalized Search Tree)** hoặc **SP-GiST** hỗ trợ tìm kiếm lân cận $k$-NN (`<->`) |
| **Độ chính xác** | Rất cao ở cự ly nội thành ($\Delta < 0.3\%$). Đơn vị tính ra km/m rõ ràng | Cực cao, hỗ trợ tính toán trên Ellipsoid WGS-84 chính xác đến từng milimet |
| **Độ phức tạp triển khai** | Đơn giản, dễ giải thích trong đồ án, không bị lỗi thiếu thư viện khi chấm bài | Nâng cao, yêu cầu cấu hình thêm extension trên máy giáo viên/chấm thi |

---

## 4. PHÂN TÍCH CHUYÊN SÂU CHỈ MỤC: B-TREE VÀ GIST

### 4.1. Bản chất chỉ mục B-Tree (Balanced Tree)
* **Nguyên lý hoạt động**: B-Tree tổ chức dữ liệu theo cây tìm kiếm nhị phân/đa phân tự cân bằng trên **không gian 1 chiều (1D)** với thứ tự tuyến tính sắp xếp ($<, =, >$).
* **Khả năng**:
  * Cực kỳ xuất sắc với các điều kiện so sánh bằng (`=`), so sánh đoạn (`BETWEEN`, `<`, `>`), và lọc tiền tố.
  * Phù hợp để đánh chỉ mục trên cột trạng thái: `driver_status = 'AVAILABLE'` và cờ `is_active = TRUE`.
* **Hạn chế đối với dữ liệu không gian**:
  * B-Tree **không thể** tự động tìm kiếm lân cận 2 chiều (2D Spatial Nearest Neighbors) một cách trực tiếp. Nếu đánh B-Tree riêng lẻ trên `latitude` và `longitude`, CSDL chỉ có thể quét theo hình hộp chữ nhật (Bounding Box) 1 chiều trước rồi mới lọc chiều còn lại.

### 4.2. Bản chất chỉ mục GiST (Generalized Search Tree)
* **Nguyên lý hoạt động**: GiST là một khung sườn chỉ mục tổng quát, cho phép triển khai cấu trúc cây $R$-Tree (Bounding Boxes đa chiều). 
* **Khả năng với PostGIS**:
  * Gom nhóm các tọa độ thành các hình chữ nhật bao quanh nhỏ nhất (Minimum Bounding Boxes - MBR).
  * Hỗ trợ toán tử tìm kiếm $k$-hàng xóm gần nhất ($k$-Nearest Neighbors / $k$-NN) thông qua toán tử `<->`.
  * Truy vấn tìm top $k$ tài xế gần nhất không cần phải quét tuần tự (Sequential Scan) toàn bộ bảng, mà duyệt trực tiếp từ gốc cây $R$-Tree đến các lá gần tâm nhất.
* **Hạn chế**: Chi phí ghi (Write/Update) cao hơn B-Tree khi tọa độ tài xế nhảy liên tục theo thời gian thực (Ping GPS mỗi 3 - 5 giây).

### 4.3. Phân biệt `geometry` và `geography` trong PostGIS
* `GEOMETRY`: Mô hình hóa trên mặt phẳng Descartes (Cartesian 2D/3D). Đơn vị khoảng cách là đơn vị của hệ quy chiếu (ví dụ: mét với UTM, hoặc độ với EPSG:4326). Nếu dùng EPSG:4326 mà tính khoảng cách trực tiếp, kết quả trả về là **độ** (Degrees), không phải mét!
* `GEOGRAPHY`: Mô hình hóa trực tiếp trên mặt phỏng cầu địa lý WGS-84 (EPSG:4326). Các phép tính khoảng cách luôn tự động tính theo **Mét (meters)**. Phù hợp cho GPS giao vận toàn cầu nhưng chi phí tính toán CPU cao hơn `geometry`.

---

## 5. ĐỀ XUẤT THIẾT KẾ THỰC DỤNG CHO DỰ ÁN

Để đảm bảo **tính khả quan, thực dụng và khả năng vận hành 100% thành công** trong môi trường học thuật của môn học Cơ sở dữ liệu:

### Phương án được lựa chọn chính thức: Haversine SQL kết hợp Partial B-Tree Index
1. **Lý do lựa chọn**:
   * **Tính tương thích tuyệt đối**: Không làm phát sinh lỗi `ERROR: extension "postgis" is not available` khi giảng viên hoặc thành viên nhóm chạy script trên môi trường PostgreSQL sạch không có quyền cài extension.
   * **Tính tự chứa (Self-contained)**: Toàn bộ công thức toán học và logic lọc nằm gọn gàng trong câu lệnh SQL tiêu chuẩn.
   * **Hiệu năng thực tế**: Với quy mô bài toán sinh viên (vài nghìn tài xế), việc lọc trước bằng trạng thái và cờ hoạt động sẽ thu hẹp tập xét xuống chỉ còn vài chục tài xế, thời gian thực thi của phép tính Haversine chỉ mất dưới $1\text{ ms}$.

2. **Giải pháp tối ưu hóa hiệu năng (Index Optimization)**:
   Xây dựng **Partial B-Tree Index** chuyên biệt cho tác vụ dispatching:
   ```sql
   -- Chỉ lập chỉ mục trên những tài xế ĐANG SẴN SÀNG NHẬN ĐƠN và CÓ TỌA ĐỘ HỢP LỆ
   CREATE INDEX idx_drivers_available_dispatch
       ON drivers (current_lat, current_long)
       WHERE (driver_status = 'AVAILABLE' AND is_active = TRUE AND current_lat IS NOT NULL AND current_long IS NOT NULL);
   ```
   *Lợi ích*: Loại bỏ 90% các tài xế đang `OFFLINE` hoặc `DELIVERING` ra khỏi cây chỉ mục, giúp kích thước chỉ mục cực kỳ nhỏ gọn, nằm trọn trong RAM (Buffer Cache).

---

## 6. KẾT LUẬN

Báo cáo đã làm rõ bản chất toán học của Haversine, phân định rõ ranh giới kỹ thuật giữa chỉ mục B-Tree và GiST, đồng thời lựa chọn phương án tối ưu cân bằng giữa độ chính xác, hiệu năng và tính thực dụng trong triển khai thực tế.
