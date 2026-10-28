-- ==============================================================================
-- KỊCH BẢN DDL VÀ DỮ LIỆU KIỂM THỬ: PHÂN HỆ NGƯỜI DÙNG (USER SUBSYSTEM)
-- Dự án: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
-- Phụ trách: SV1 - Nhóm trưởng (Bùi Duy Quang)
-- Hệ quản trị CSDL mục tiêu: PostgreSQL 14+ / 15 / 16
-- 
-- Danh mục bảng phụ trách:
--   1. USERS                : Siêu lớp lưu trữ thông tin định danh dùng chung
--   2. CUSTOMERS            : Phân lớp khách hàng đặt đồ ăn
--   3. CUSTOMER_ADDRESSES   : Sổ địa chỉ giao hàng của khách hàng (1-N)
--   4. MERCHANT_OWNERS      : Phân lớp chủ đối tác nhà hàng (xác minh KYC)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. DỌN DẸP DỮ LIỆU CŨ (CLEANUP / ROLLBACK SCRIPT)
-- Xóa theo thứ tự: Bảng con trước, Bảng cha sau để không vi phạm ràng buộc FK
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS customer_addresses CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS merchant_owners CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ------------------------------------------------------------------------------
-- 1. BẢNG SIÊU LỚP: USERS (Tài khoản người dùng toàn hệ thống)
-- Chứa thông tin đăng nhập, phân loại vai trò và bảo mật mật khẩu
-- ------------------------------------------------------------------------------
CREATE TABLE users (
    user_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email           VARCHAR(255) NOT NULL,
    phone_number    VARCHAR(20) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    user_type       VARCHAR(20) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Ràng buộc tính duy nhất cho Email và SĐT
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT uq_users_phone UNIQUE (phone_number),

    -- Ràng buộc miền giá trị cho vai trò (Disjoint Subclasses)
    CONSTRAINT chk_users_user_type CHECK (
        user_type IN ('CUSTOMER', 'MERCHANT_OWNER', 'DRIVER')
    ),

    -- Ràng buộc trạng thái tài khoản
    CONSTRAINT chk_users_status CHECK (
        status IN ('ACTIVE', 'SUSPENDED', 'DELETED')
    ),

    -- Kiểm tra định dạng cơ bản: không được rỗng và email có ký tự @
    CONSTRAINT chk_users_email_format CHECK (
        email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
);

COMMENT ON TABLE users IS 'Siêu lớp lưu trữ tài khoản định danh người dùng trong hệ thống';
COMMENT ON COLUMN users.password_hash IS 'Mật khẩu đã được băm bảo mật (Bcrypt/Argon2), tuyệt đối không lưu plaintext';
COMMENT ON COLUMN users.user_type IS 'Cờ phân loại phục vụ chuyên biệt hóa: CUSTOMER, MERCHANT_OWNER, DRIVER';

-- ------------------------------------------------------------------------------
-- 2. BẢNG PHÂN LỚP: CUSTOMERS (Khách hàng đặt món)
-- Kế thừa từ USERS: customer_id vừa là PK vừa là FK tham chiếu users(user_id)
-- ------------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id     BIGINT PRIMARY KEY,
    loyalty_points  INTEGER NOT NULL DEFAULT 0,
    birth_date      DATE,
    avatar_url      VARCHAR(500),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Khóa ngoại tham chiếu bảng cha USERS
    CONSTRAINT fk_customers_users FOREIGN KEY (customer_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Ràng buộc điểm tích lũy không âm
    CONSTRAINT chk_customers_loyalty_points CHECK (loyalty_points >= 0)
);

COMMENT ON TABLE customers IS 'Phân lớp khách hàng với quyền đặt đơn, tích lũy điểm thưởng';

-- ------------------------------------------------------------------------------
-- 3. BẢNG: CUSTOMER_ADDRESSES (Sổ địa chỉ giao hàng)
-- Quan hệ 1-N với CUSTOMERS. Lưu tọa độ địa lý để tính cước vận chuyển và điều phối
-- ------------------------------------------------------------------------------
CREATE TABLE customer_addresses (
    address_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id     BIGINT NOT NULL,
    recipient_name  VARCHAR(100) NOT NULL,
    recipient_phone VARCHAR(20) NOT NULL,
    street_address  VARCHAR(255) NOT NULL,
    ward            VARCHAR(100),
    district        VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    latitude        DECIMAL(10, 8) NOT NULL,
    longitude       DECIMAL(11, 8) NOT NULL,
    address_label   VARCHAR(50) DEFAULT 'Home',
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Khóa ngoại tham chiếu CUSTOMERS
    CONSTRAINT fk_addresses_customers FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Ràng buộc kiểm tra phạm vi tọa độ GPS hợp lệ trên địa cầu
    CONSTRAINT chk_addresses_latitude CHECK (latitude BETWEEN -90.0 AND 90.0),
    CONSTRAINT chk_addresses_longitude CHECK (longitude BETWEEN -180.0 AND 180.0)
);

-- RÀNG BUỘC NGHIỆP VỤ ĐẶC BIỆT [BR03]:
-- Mỗi khách hàng chỉ được phép có TỐI ĐA 1 địa chỉ mặc định (is_default = TRUE).
-- Sử dụng Partial Unique Index chuẩn hóa của PostgreSQL:
CREATE UNIQUE INDEX uq_customer_single_default_address
    ON customer_addresses (customer_id)
    WHERE (is_default = TRUE);

COMMENT ON TABLE customer_addresses IS 'Sổ danh bạ địa chỉ giao nhận của khách hàng kèm tọa độ GPS';
COMMENT ON INDEX uq_customer_single_default_address IS 'Đảm bảo mỗi khách hàng chỉ có duy nhất 1 địa chỉ mặc định';

-- ------------------------------------------------------------------------------
-- 4. BẢNG PHÂN LỚP: MERCHANT_OWNERS (Chủ nhà hàng / Quán ăn)
-- Kế thừa từ USERS: merchant_owner_id vừa là PK vừa là FK tham chiếu users(user_id)
-- ------------------------------------------------------------------------------
CREATE TABLE merchant_owners (
    merchant_owner_id       BIGINT PRIMARY KEY,
    tax_code                VARCHAR(50) NOT NULL,
    identity_card_number    VARCHAR(50) NOT NULL,
    business_license_url    VARCHAR(500),
    kyc_status              VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    verified_at             TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Khóa ngoại tham chiếu bảng cha USERS
    CONSTRAINT fk_merchants_users FOREIGN KEY (merchant_owner_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Mã số thuế và CCCD phải là duy nhất trên toàn sàn
    CONSTRAINT uq_merchants_tax_code UNIQUE (tax_code),
    CONSTRAINT uq_merchants_id_card UNIQUE (identity_card_number),

    -- Trạng thái duyệt hồ sơ pháp lý
    CONSTRAINT chk_merchants_kyc_status CHECK (
        kyc_status IN ('PENDING', 'VERIFIED', 'REJECTED')
    )
);

COMMENT ON TABLE merchant_owners IS 'Phân lớp chủ đối tác ẩm thực có đầy đủ thông tin pháp lý KYC';

-- ==============================================================================
-- 5. DỮ LIỆU MẪU KIỂM THỬ (SEED DATA FOR INTEGRATION TESTING)
-- Đảm bảo dữ liệu mẫu chuẩn chỉ, đúng thứ tự cha -> con
-- ==============================================================================

-- 5.1. Thêm tài khoản người dùng mẫu vào USERS
INSERT INTO users (email, phone_number, password_hash, full_name, user_type, status)
VALUES 
    -- User 1: Khách hàng Nguyễn Văn An
    ('nguyenvanan@gmail.com', '0901234567', '$2a$12$eX8mE/f7H5rF0oZ9...hashAn', 'Nguyễn Văn An', 'CUSTOMER', 'ACTIVE'),
    -- User 2: Khách hàng Trần Thị Bích
    ('tranthibich@gmail.com', '0912345678', '$2a$12$kL9wP/q1A2bC3dE4...hashBich', 'Trần Thị Bích', 'CUSTOMER', 'ACTIVE'),
    -- User 3: Chủ quán Cơm Tấm Sài Gòn
    ('comtamsaigon.owner@gmail.com', '0988889999', '$2a$12$xY7zM/m8N9oP0qR1...hashComTam', 'Lê Hoàng Nam', 'MERCHANT_OWNER', 'ACTIVE'),
    -- User 4: Tài xế giao hàng (SV3 sẽ quản lý phân lớp DRIVERS)
    ('taixe.nguyen@gmail.com', '0933445566', '$2a$12$aB3cD/e5F6g7H8i9...hashDriver', 'Võ Quốc Hưng', 'DRIVER', 'ACTIVE');

-- 5.2. Thêm dữ liệu phân lớp CUSTOMERS (user_id = 1 và 2)
INSERT INTO customers (customer_id, loyalty_points, birth_date, avatar_url)
VALUES 
    (1, 150, '1998-05-12', 'https://storage.fooddelivery.vn/avatars/u1.jpg'),
    (2, 50,  '2001-11-20', 'https://storage.fooddelivery.vn/avatars/u2.jpg');

-- 5.3. Thêm sổ địa chỉ giao hàng cho CUSTOMERS
INSERT INTO customer_addresses (customer_id, recipient_name, recipient_phone, street_address, ward, district, city, latitude, longitude, address_label, is_default)
VALUES 
    -- Khách hàng 1: Địa chỉ mặc định (Nhà riêng)
    (1, 'Nguyễn Văn An', '0901234567', 'Số 123 Đường Nguyễn Huệ', 'Bến Nghé', 'Quận 1', 'TP. Hồ Chí Minh', 10.77450000, 106.70320000, 'Nhà riêng', TRUE),
    -- Khách hàng 1: Địa chỉ phụ (Công ty)
    (1, 'Nguyễn Văn An', '0901234567', 'Tầng 8, Tòa nhà Landmark 81, 720A Điện Biên Phủ', 'Phường 22', 'Bình Thạnh', 'TP. Hồ Chí Minh', 10.79500000, 106.72180000, 'Công ty', FALSE),
    -- Khách hàng 2: Địa chỉ mặc định (Căn hộ)
    (2, 'Trần Thị Bích', '0912345678', 'Chung cư Masteri Thảo Điền, 159 Xa lộ Hà Nội', 'Thảo Điền', 'Thủ Đức', 'TP. Hồ Chí Minh', 10.80380000, 106.74100000, 'Căn hộ', TRUE);

-- 5.4. Thêm dữ liệu phân lớp MERCHANT_OWNERS (user_id = 3)
INSERT INTO merchant_owners (merchant_owner_id, tax_code, identity_card_number, business_license_url, kyc_status, verified_at)
VALUES 
    (3, '0315894123', '079098001234', 'https://storage.fooddelivery.vn/licenses/comtam_license.pdf', 'VERIFIED', CURRENT_TIMESTAMP);

-- ==============================================================================
-- 6. CÂU TRUY VẤN KIỂM CHỨNG & THỬ NGHIỆM TÍNH TOÀN VẸN
-- ==============================================================================

-- 6.1. Kiểm chứng dữ liệu Khách hàng kèm sổ địa chỉ
SELECT 
    u.user_id,
    u.full_name,
    u.email,
    u.phone_number,
    c.loyalty_points,
    ca.address_label,
    ca.street_address,
    ca.district,
    ca.city,
    ca.is_default
FROM users u
JOIN customers c ON u.user_id = c.customer_id
LEFT JOIN customer_addresses ca ON c.customer_id = ca.customer_id
ORDER BY u.user_id, ca.is_default DESC;

-- 6.2. Kiểm chứng dữ liệu Chủ nhà hàng đã được KYC
SELECT 
    u.user_id,
    u.full_name,
    u.phone_number,
    mo.tax_code,
    mo.identity_card_number,
    mo.kyc_status,
    mo.verified_at
FROM users u
JOIN merchant_owners mo ON u.user_id = mo.merchant_owner_id;

-- ------------------------------------------------------------------------------
-- 6.3. TEST BẪY LỖI RÀNG BUỘC (KIỂM CHỨNG TÍNH TOÀN VẸN CSDL)
-- Các câu lệnh dưới đây nếu chạy sẽ phát sinh lỗi đúng như mong muốn thiết kế:
-- ------------------------------------------------------------------------------

-- [TEST LỖI 1]: Cố tình thêm địa chỉ mặc định thứ 2 cho cùng 1 khách hàng (Vi phạm Partial Unique Index)
-- Kỳ vọng: Lỗi duplicate key value violates unique constraint "uq_customer_single_default_address"
/*
INSERT INTO customer_addresses (customer_id, recipient_name, recipient_phone, street_address, district, city, latitude, longitude, is_default)
VALUES (1, 'Nguyễn Văn An', '0901234567', '456 Lê Lợi', 'Quận 1', 'TP. Hồ Chí Minh', 10.7712, 106.7001, TRUE);
*/

-- [TEST LỖI 2]: Cố tình gán điểm tích lũy âm (Vi phạm CHECK constraint)
-- Kỳ vọng: Lỗi violates check constraint "chk_customers_loyalty_points"
/*
UPDATE customers SET loyalty_points = -10 WHERE customer_id = 1;
*/
