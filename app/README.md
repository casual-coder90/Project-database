# Web kiểm thử MySQL — Bếp Nối

Node.js/Express + `mysql2`; mọi dữ liệu đọc/ghi MySQL 8.4/InnoDB. Không dùng localStorage hoặc mảng đơn hardcode.

## Cách chạy khuyến nghị

Từ thư mục gốc:

```powershell
docker compose up --build
```

Mở `http://localhost:3000`. Lần đầu MySQL tự chạy `mysql_schema.sql` và `demo_seed.sql`. Dừng bằng `docker compose down`; volume vẫn giữ dữ liệu.

Nếu cổng bận:

```powershell
$env:WEB_PORT='3300'
$env:DB_PORT='53306'
docker compose up --build
```

Reset toàn bộ **dữ liệu demo**:

```powershell
docker compose down -v
docker compose up --build
```

## Chạy thủ công

Yêu cầu MySQL 8.4 và Node.js 20+. Tạo schema/seed:

```powershell
mysql -u root -p < sql/mysql_schema.sql
mysql -u root -p food_delivery_db < sql/demo_seed.sql
mysql -u root -p food_delivery_db < sql/mysql_tests.sql
```

Trong `app/`, sao chép `.env.example` thành `.env`, chỉnh `DATABASE_URL`, rồi:

```powershell
npm install
npm start
```

Không commit `.env`. `demo_seed.sql` dùng khóa cố định và `ON DUPLICATE KEY UPDATE`, có thể chạy lại mà không tạo trùng.

## Kiểm thử

Khi web đang chạy:

```powershell
npm test
```

Test tạo đơn thật trong MySQL, kiểm tra transaction, số lượng không hợp lệ, máy trạng thái, phân công, vị trí, COD và tra cứu sau giao.

## Lỗi thường gặp

- `ECONNREFUSED`: MySQL chưa sẵn sàng hoặc sai `DATABASE_URL`.
- `Access denied`: kiểm tra user/password và quyền trên `food_delivery_db`.
- `port is already allocated`: đổi `WEB_PORT`/`DB_PORT`.
- Schema chưa cập nhật: init script chỉ chạy với volume mới; dùng `down -v` chỉ khi chấp nhận xóa dữ liệu demo.
- Không thấy nút thao tác: chọn đúng tài khoản mẫu rồi bấm Tải lại từ CSDL.
