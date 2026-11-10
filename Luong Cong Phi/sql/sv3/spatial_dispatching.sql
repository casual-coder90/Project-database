-- ==============================================================================
-- TRUY VẤN SPATIAL DISPATCHING: ĐIỀU PHỐI TOP 5 TÀI XẾ GẦN NHÀ HÀNG NHẤT
-- Dự án: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
-- Phụ trách: SV3 - Kỹ sư CSDL & Vận hành GIS (Lương Công Phi)
-- Hệ quản trị CSDL mục tiêu: PostgreSQL 14+ / 15 / 16
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. BỘ DỮ LIỆU THỬ NGHIỆM ĐỘC LẬP (MÔ PHỎNG TỌA ĐỘ TÀI XẾ TẠI TP.HCM)
-- Lưu ý: Kịch bản này tạo dữ liệu mẫu để có thể chạy kiểm thử ngay lập tức.
-- Vị trí nhà hàng mẫu: Chi nhánh Quận 1 (45 Nguyễn Huệ) có tọa độ:
--   Latitude  = 10.77420000
--   Longitude = 106.70300000
-- ------------------------------------------------------------------------------

-- 1.1. Thêm tài khoản người dùng loại DRIVER vào bảng USERS (nếu chưa có)
INSERT INTO users (user_id, email, phone_number, password_hash, full_name, user_type, status)
OVERRIDING SYSTEM VALUE VALUES
    (101, 'driver101@food.vn', '0931111101', 'hash_pass_101', 'Tài xế 1 - Nguyễn Văn Hải', 'DRIVER', 'ACTIVE'),
    (102, 'driver102@food.vn', '0931111102', 'hash_pass_102', 'Tài xế 2 - Trần Minh Tuấn', 'DRIVER', 'ACTIVE'),
    (103, 'driver103@food.vn', '0931111103', 'hash_pass_103', 'Tài xế 3 - Lê Hữu Phước', 'DRIVER', 'ACTIVE'),
    (104, 'driver104@food.vn', '0931111104', 'hash_pass_104', 'Tài xế 4 - Phạm Quốc Bảo', 'DRIVER', 'ACTIVE'),
    (105, 'driver105@food.vn', '0931111105', 'hash_pass_105', 'Tài xế 5 - Đỗ Trọng Nghĩa', 'DRIVER', 'ACTIVE'),
    (106, 'driver106@food.vn', '0931111106', 'hash_pass_106', 'Tài xế 6 - Hoàng Văn Long', 'DRIVER', 'ACTIVE'),
    (107, 'driver107@food.vn', '0931111107', 'hash_pass_107', 'Tài xế 7 - Vũ Thành Đạt', 'DRIVER', 'ACTIVE'),
    (108, 'driver108@food.vn', '0931111108', 'hash_pass_108', 'Tài xế 8 - Ngô Gia Khiêm', 'DRIVER', 'ACTIVE')
ON CONFLICT (user_id) DO NOTHING;

-- 1.2. Thêm thông tin chi tiết vào bảng phân lớp DRIVERS
-- Đa dạng trạng thái: AVAILABLE, OFFLINE, DELIVERING và tọa độ NULL để kiểm tra bộ lọc
INSERT INTO drivers (driver_id, license_number, vehicle_type, vehicle_plate, current_lat, current_long, driver_status, is_active, rating_average, total_trips)
VALUES
    -- [Tài xế 1]: Cách 45 Nguyễn Huệ ~0.35 km (Rất gần - Phố đi bộ)
    (101, 'GPLX-7901', 'MOTORBIKE', '59-A1 111.11', 10.77150000, 106.70420000, 'AVAILABLE', TRUE, 4.95, 340),

    -- [Tài xế 2]: Cách 45 Nguyễn Huệ ~0.85 km (Chợ Bến Thành)
    (102, 'GPLX-7902', 'MOTORBIKE', '59-A1 222.22', 10.77210000, 106.69830000, 'AVAILABLE', TRUE, 4.88, 510),

    -- [Tài xế 3]: Cách 45 Nguyễn Huệ ~1.20 km (Nhà thờ Đức Bà)
    (103, 'GPLX-7903', 'MOTORBIKE', '59-A1 333.33', 10.77980000, 106.69900000, 'AVAILABLE', TRUE, 4.90, 180),

    -- [Tài xế 4]: Cách 45 Nguyễn Huệ ~1.65 km (Hồ Con Rùa Quận 3)
    (104, 'GPLX-7904', 'ELECTRIC_BIKE', '59-MD 444.44', 10.78270000, 106.69580000, 'AVAILABLE', TRUE, 5.00, 95),

    -- [Tài xế 5]: Cách 45 Nguyễn Huệ ~2.30 km (Cầu Thị Nghè)
    (105, 'GPLX-7905', 'MOTORBIKE', '59-A1 555.55', 10.79050000, 106.70800000, 'AVAILABLE', TRUE, 4.75, 620),

    -- [Tài xế 6]: Cách 45 Nguyễn Huệ ~3.80 km (Hàng Xanh Bình Thạnh) - Xa hơn
    (106, 'GPLX-7906', 'MOTORBIKE', '59-A1 666.66', 10.80150000, 106.71150000, 'AVAILABLE', TRUE, 4.85, 410),

    -- [Tài xế 7]: ĐANG ĐI GIAO ĐƠN (DELIVERING) -> BẮT BUỘC PHẢI BỊ BỎ QUA dù ở rất gần (0.4 km)
    (107, 'GPLX-7907', 'MOTORBIKE', '59-A1 777.77', 10.77350000, 106.70100000, 'DELIVERING', TRUE, 4.92, 850),

    -- [Tài xế 8]: ĐANG NGHỈ (OFFLINE) hoặc TỌA ĐỘ NULL -> BẮT BUỘC BỊ BỎ QUA
    (108, 'GPLX-7908', 'MOTORBIKE', '59-A1 888.88', NULL, NULL, 'OFFLINE', TRUE, 4.60, 120)
ON CONFLICT (driver_id) DO UPDATE 
SET current_lat = EXCLUDED.current_lat,
    current_long = EXCLUDED.current_long,
    driver_status = EXCLUDED.driver_status;

-- ==============================================================================
-- 2. CÂU TRUY VẤN CHÍNH THỨC: TÌM TOP 5 TÀI XẾ AVAILABLE GẦN NHẤT
-- ==============================================================================

WITH restaurant_target AS (
    -- Khai báo vị trí nhà hàng cần điều phối (Ví dụ: Chi nhánh 1 tại Quận 1)
    SELECT 
        10.77420000::DECIMAL(10, 8) AS rest_lat,
        106.70300000::DECIMAL(11, 8) AS rest_long,
        'Chi nhánh Quận 1 (45 Nguyễn Huệ)' AS restaurant_name
),
candidate_drivers AS (
    SELECT 
        d.driver_id,
        u.full_name,
        u.phone_number,
        d.vehicle_type,
        d.vehicle_plate,
        d.rating_average,
        d.total_trips,
        d.current_lat,
        d.current_long,
        
        -- ÁP DỤNG CÔNG THỨC HAVERSINE CHUẨN POSTGRESQL:
        ROUND(
            (
                6371.0 * 2.0 * ASIN(
                    SQRT(
                        LEAST(1.0, GREATEST(0.0,
                            POWER(SIN(RADIANS(d.current_lat - r.rest_lat) / 2.0), 2) +
                            COS(RADIANS(r.rest_lat)) * COS(RADIANS(d.current_lat)) *
                            POWER(SIN(RADIANS(d.current_long - r.rest_long) / 2.0), 2)
                        ))
                    )
                )
            )::numeric, 3
        ) AS distance_km

    FROM drivers d
    JOIN users u ON d.driver_id = u.user_id
    CROSS JOIN restaurant_target r
    WHERE 
        -- 1. Lọc tài xế đang sẵn sàng nhận cuốc
        d.driver_status = 'AVAILABLE'
        AND d.is_active = TRUE
        
        -- 2. Loại bỏ tọa độ rác/NULL
        AND d.current_lat IS NOT NULL 
        AND d.current_long IS NOT NULL
        
        -- 3. Ràng buộc miền tọa độ WGS-84 hợp lệ
        AND d.current_lat BETWEEN -90.0 AND 90.0
        AND d.current_long BETWEEN -180.0 AND 180.0
)
SELECT 
    driver_id,
    full_name,
    phone_number,
    vehicle_type,
    vehicle_plate,
    rating_average,
    total_trips,
    distance_km,
    
    -- Ước tính thời gian tài xế di chuyển đến quán (vận tốc nội đô trung bình 25 km/h):
    ROUND((distance_km / 25.0 * 60.0)::numeric, 1) AS estimated_pickup_minutes
FROM candidate_drivers
ORDER BY 
    distance_km ASC,    -- Tiêu chí 1: Khoảng cách gần nhất
    rating_average DESC,-- Tiêu chí 2: Ưu tiên tài xế sao cao hơn nếu cự ly tương đương
    driver_id ASC       -- Tiêu chí 3: Ổn định thứ tự kết quả (Tie-breaker)
LIMIT 5;

-- ==============================================================================
-- 3. PHÂN TÍCH KẾ HOẠCH THỰC THI (EXECUTION PLAN ANALYSIS)
-- ==============================================================================
-- Khi hệ thống có hàng chục nghìn tài xế, Partial Index đã tạo ở DDL:
--   idx_drivers_available_dispatch ON drivers (current_lat, current_long) 
--   WHERE (driver_status = 'AVAILABLE' AND is_active = TRUE ...)
-- Sẽ giúp PostgreSQL thực hiện Bitmap Index Scan trên tập tài xế đang online thay vì quét toàn bảng.
EXPLAIN ANALYZE
SELECT 
    d.driver_id,
    ROUND(
        (6371.0 * 2.0 * ASIN(SQRT(
            POWER(SIN(RADIANS(d.current_lat - 10.7742) / 2.0), 2) +
            COS(RADIANS(10.7742)) * COS(RADIANS(d.current_lat)) *
            POWER(SIN(RADIANS(d.current_long - 106.7030) / 2.0), 2)
        )))::numeric, 3
    ) AS distance_km
FROM drivers d
WHERE d.driver_status = 'AVAILABLE' 
  AND d.is_active = TRUE
  AND d.current_lat IS NOT NULL 
  AND d.current_long IS NOT NULL
ORDER BY distance_km ASC
LIMIT 5;
