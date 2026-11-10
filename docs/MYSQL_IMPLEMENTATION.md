# TRIỂN KHAI MYSQL HIỆN HÀNH

Phiên bản đã kiểm tra: **MySQL 8.4.11 Community Server**, `@@default_storage_engine = InnoDB`. Đây là tài liệu triển khai chính thức; mô tả PostgreSQL cũ chỉ là lịch sử trước khi đổi yêu cầu.

- Identity → `BIGINT AUTO_INCREMENT`; `TIMESTAMPTZ` → `DATETIME(6)`.
- Partial unique index → generated guard column + `UNIQUE`.
- PL/pgSQL → trigger MySQL với `SIGNAL SQLSTATE '45000'`; regex → `REGEXP_LIKE`.
- Mọi bảng dùng InnoDB, FK và transaction.
- Tọa độ dùng hai cột DECIMAL và Haversine, không dùng spatial extension.

CHECK được MySQL thực thi từ 8.0.16; các tính năng trên đều có trong 8.4.11 đã kiểm tra. Backend dùng `mysql2/promise`, `DATABASE_URL`, prepared placeholders và transaction. Không có SQLite, PostgreSQL runtime hoặc localStorage.
