# ĐỒ ÁN CƠ SỞ DỮ LIỆU GIAO ĐỒ ĂN — MySQL

**DBMS bắt buộc:** MySQL 8.4; đã kiểm thử trên MySQL 8.4.11 Community Server, engine InnoDB.

## Chạy web và CSDL

```powershell
docker compose up --build
```

Mở `http://localhost:3000`. Web gồm ba tab: Đặt đơn, Quản lý đơn, Kiểm tra dữ liệu. Hướng dẫn chi tiết ở [app/README.md](app/README.md).

## File SQL chính thức

1. `sql/mysql_schema.sql`: tạo 24 bảng InnoDB, FK, CHECK, generated unique guards và trigger.
2. `sql/demo_seed.sql`: dữ liệu mẫu nạp ban đầu.
3. `sql/mysql_queries.sql`: truy vấn nghiệp vụ/Haversine.
4. `sql/mysql_tests.sql`: kiểm tra version, engine và metadata.

## Tài liệu

- [Báo cáo chính](docs/BAO_CAO_CHINH.md)
- [DRS](docs/DRS.md)
- [Kịch bản demo](docs/KICH_BAN_DEMO_UNG_DUNG.md)
- [Kết quả kiểm chứng](docs/KET_QUA_KIEM_CHUNG.md)

Dữ liệu SQL là dữ liệu minh họa, không phải kết quả khảo sát thực tế.
