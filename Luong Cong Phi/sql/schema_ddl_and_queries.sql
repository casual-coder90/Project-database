-- ==============================================================================
-- KỊCH BẢN DDL TÍCH HỢP TOÀN DIỆN & TRUY VẤN HỆ THỐNG (MASTER INTEGRATED SCRIPT)
-- Dự án môn học: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
-- Học phần: Cơ sở dữ liệu
-- Hệ quản trị CSDL mục tiêu: PostgreSQL 14+ / 15 / 16 / 18
-- Kỹ sư phụ trách tích hợp CSDL: SV3 - Lương Công Phi
-- 
-- Danh mục 21 bảng toàn hệ thống:
--   [SV1 - Bùi Duy Quang]:
--     1. users               2. customers             3. customer_addresses
--     4. merchant_owners     5. orders                6. order_items
--     7. order_item_options
--   [SV2 - Phạm Đình Phúc]:
--     8. restaurants         9. branches             10. categories
--    11. items              12. option_groups        13. option_items
--   [SV3 - Lương Công Phi]:
--    14. drivers            15. payments             16. cash_payments
--    17. card_payments      18. ewallet_payments     19. order_status_logs
--    20. restaurant_reviews 21. driver_reviews
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. DỌN SẠCH CƠ SỞ DỮ LIỆU CŨ (CLEANUP / ROLLBACK THEO THỨ TỰ CON TRƯỚC - CHA SAU)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS driver_reviews CASCADE;
DROP TABLE IF EXISTS restaurant_reviews CASCADE;
DROP TABLE IF EXISTS order_status_logs CASCADE;
DROP TABLE IF EXISTS ewallet_payments CASCADE;
DROP TABLE IF EXISTS card_payments CASCADE;
DROP TABLE IF EXISTS cash_payments CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_item_options CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS option_items CASCADE;
DROP TABLE IF EXISTS option_groups CASCADE;
DROP TABLE IF EXISTS items CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS branches CASCADE;
DROP TABLE IF EXISTS restaurants CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;
DROP TABLE IF EXISTS merchant_owners CASCADE;
DROP TABLE IF EXISTS customer_addresses CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ==============================================================================
-- PHẦN 1: DDL PHÂN HỆ NGƯỜI DÙNG (USER SUBSYSTEM - PHỤ TRÁCH: SV1)
-- ==============================================================================

-- 1.1. Siêu lớp: USERS (Tài khoản người dùng toàn hệ thống)
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

    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT uq_users_phone UNIQUE (phone_number),
    CONSTRAINT chk_users_user_type CHECK (user_type IN ('CUSTOMER', 'MERCHANT_OWNER', 'DRIVER')),
    CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'DELETED')),
    CONSTRAINT chk_users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- 1.2. Phân lớp: CUSTOMERS (Khách hàng)
CREATE TABLE customers (
    customer_id     BIGINT PRIMARY KEY,
    loyalty_points  INTEGER NOT NULL DEFAULT 0,
    birth_date      DATE,
    avatar_url      VARCHAR(500),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_customers_users FOREIGN KEY (customer_id)
        REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_customers_loyalty CHECK (loyalty_points >= 0)
);

-- 1.3. Sổ địa chỉ giao hàng: CUSTOMER_ADDRESSES
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

    CONSTRAINT fk_addresses_customers FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_addresses_latitude CHECK (latitude BETWEEN -90.0 AND 90.0),
    CONSTRAINT chk_addresses_longitude CHECK (longitude BETWEEN -180.0 AND 180.0)
);

CREATE UNIQUE INDEX uq_customer_single_default_address
    ON customer_addresses (customer_id)
    WHERE (is_default = TRUE);

-- 1.4. Phân lớp: MERCHANT_OWNERS (Chủ nhà hàng KYC)
CREATE TABLE merchant_owners (
    merchant_owner_id       BIGINT PRIMARY KEY,
    tax_code                VARCHAR(50) NOT NULL,
    identity_card_number    VARCHAR(50) NOT NULL,
    business_license_url    VARCHAR(500),
    kyc_status              VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    verified_at             TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_merchants_users FOREIGN KEY (merchant_owner_id)
        REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_merchants_tax_code UNIQUE (tax_code),
    CONSTRAINT uq_merchants_id_card UNIQUE (identity_card_number),
    CONSTRAINT chk_merchants_kyc_status CHECK (kyc_status IN ('PENDING', 'VERIFIED', 'REJECTED'))
);

-- ==============================================================================
-- PHẦN 2: DDL PHÂN HỆ NHÀ HÀNG & THỰC ĐƠN (MENU SUBSYSTEM - PHỤ TRÁCH: SV2)
-- ==============================================================================

-- 2.1. Bảng: RESTAURANTS (Thương hiệu nhà hàng)
CREATE TABLE restaurants (
    restaurant_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id        BIGINT NOT NULL,
    restaurant_name VARCHAR(150) NOT NULL,
    cuisine_type    VARCHAR(100) NOT NULL,
    description     TEXT,
    logo_url        VARCHAR(500),
    banner_url      VARCHAR(500),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_restaurants_merchant_owners FOREIGN KEY (owner_id)
        REFERENCES merchant_owners (merchant_owner_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_restaurants_name CHECK (LENGTH(TRIM(restaurant_name)) > 0),
    CONSTRAINT chk_restaurants_cuisine CHECK (LENGTH(TRIM(cuisine_type)) > 0)
);

-- 2.2. Bảng: BRANCHES (Chi nhánh phục vụ thực tế)
CREATE TABLE branches (
    branch_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    restaurant_id   BIGINT NOT NULL,
    branch_name     VARCHAR(150) NOT NULL,
    phone_number    VARCHAR(20) NOT NULL,
    street_address  VARCHAR(255) NOT NULL,
    ward            VARCHAR(100),
    district        VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    latitude        DECIMAL(10, 8) NOT NULL,
    longitude       DECIMAL(11, 8) NOT NULL,
    opening_time    TIME NOT NULL,
    closing_time    TIME NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_branches_restaurants FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_branches_restaurant_name UNIQUE (restaurant_id, branch_name),
    CONSTRAINT chk_branches_latitude CHECK (latitude BETWEEN -90.0 AND 90.0),
    CONSTRAINT chk_branches_longitude CHECK (longitude BETWEEN -180.0 AND 180.0),
    CONSTRAINT chk_branches_phone CHECK (phone_number ~* '^[0-9+ ]{8,20}$')
);

-- 2.3. Bảng: CATEGORIES (Danh mục thực đơn)
CREATE TABLE categories (
    category_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    restaurant_id   BIGINT NOT NULL,
    category_name   VARCHAR(100) NOT NULL,
    display_order   INTEGER NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_categories_restaurants FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_categories_restaurant_name UNIQUE (restaurant_id, category_name),
    CONSTRAINT chk_categories_display_order CHECK (display_order >= 0)
);

-- 2.4. Bảng: ITEMS (Món ăn / Đồ uống niêm yết)
CREATE TABLE items (
    item_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id     BIGINT NOT NULL,
    item_name       VARCHAR(150) NOT NULL,
    description     TEXT,
    base_price      DECIMAL(12, 2) NOT NULL,
    image_url       VARCHAR(500),
    is_available    BOOLEAN NOT NULL DEFAULT TRUE,
    display_order   INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_items_categories FOREIGN KEY (category_id)
        REFERENCES categories (category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_items_category_name UNIQUE (category_id, item_name),
    CONSTRAINT chk_items_base_price CHECK (base_price >= 0.00),
    CONSTRAINT chk_items_display_order CHECK (display_order >= 0)
);

-- 2.5. Bảng: OPTION_GROUPS (Nhóm tùy chọn của món)
CREATE TABLE option_groups (
    group_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item_id         BIGINT NOT NULL,
    group_name      VARCHAR(100) NOT NULL,
    min_selection   INTEGER NOT NULL DEFAULT 0,
    max_selection   INTEGER NOT NULL DEFAULT 1,
    is_required     BOOLEAN NOT NULL DEFAULT FALSE,
    display_order   INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_option_groups_items FOREIGN KEY (item_id)
        REFERENCES items (item_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_option_groups_item_name UNIQUE (item_id, group_name),
    CONSTRAINT chk_option_groups_bounds CHECK (
        min_selection >= 0 AND 
        max_selection >= min_selection AND 
        max_selection >= 1
    ),
    CONSTRAINT chk_option_groups_display_order CHECK (display_order >= 0)
);

-- 2.6. Bảng: OPTION_ITEMS (Chi tiết lựa chọn kèm phụ thu)
CREATE TABLE option_items (
    option_item_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id        BIGINT NOT NULL,
    option_name     VARCHAR(100) NOT NULL,
    extra_price     DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    is_available    BOOLEAN NOT NULL DEFAULT TRUE,
    display_order   INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_option_items_groups FOREIGN KEY (group_id)
        REFERENCES option_groups (group_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_option_items_group_name UNIQUE (group_id, option_name),
    CONSTRAINT chk_option_items_extra_price CHECK (extra_price >= 0.00),
    CONSTRAINT chk_option_items_display_order CHECK (display_order >= 0)
);

-- ==============================================================================
-- PHẦN 3: DDL PHÂN HỆ TÀI XẾ (DRIVER SUBSYSTEM - PHỤ TRÁCH: SV3)
-- ==============================================================================

-- 3.1. Phân lớp: DRIVERS (Tài xế giao vận)
CREATE TABLE drivers (
    driver_id           BIGINT PRIMARY KEY,
    license_number      VARCHAR(50) NOT NULL,
    vehicle_type        VARCHAR(20) NOT NULL,
    vehicle_plate       VARCHAR(20) NOT NULL,
    current_lat         DECIMAL(10, 8),
    current_long        DECIMAL(11, 8),
    driver_status       VARCHAR(20) NOT NULL DEFAULT 'OFFLINE',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    rating_average      DECIMAL(3, 2) NOT NULL DEFAULT 5.00,
    total_trips         INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_drivers_users FOREIGN KEY (driver_id)
        REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_drivers_license UNIQUE (license_number),
    CONSTRAINT uq_drivers_plate UNIQUE (vehicle_plate),
    CONSTRAINT chk_drivers_vehicle_type CHECK (vehicle_type IN ('MOTORBIKE', 'ELECTRIC_BIKE', 'CAR')),
    CONSTRAINT chk_drivers_status CHECK (driver_status IN ('OFFLINE', 'AVAILABLE', 'DELIVERING')),
    CONSTRAINT chk_drivers_latitude CHECK (current_lat IS NULL OR (current_lat BETWEEN -90.0 AND 90.0)),
    CONSTRAINT chk_drivers_longitude CHECK (current_long IS NULL OR (current_long BETWEEN -180.0 AND 180.0)),
    CONSTRAINT chk_drivers_rating CHECK (rating_average BETWEEN 1.00 AND 5.00),
    CONSTRAINT chk_drivers_trips CHECK (total_trips >= 0)
);

-- CHỈ MỤC TỐI ƯU HÓA SPATIAL DISPATCHING (HAVERSINE / K-NN)
CREATE INDEX idx_drivers_available_dispatch
    ON drivers (current_lat, current_long)
    WHERE (driver_status = 'AVAILABLE' AND is_active = TRUE AND current_lat IS NOT NULL AND current_long IS NOT NULL);

-- ==============================================================================
-- PHẦN 4: DDL PHÂN HỆ ĐƠN HÀNG TRUNG TÂM (ORDER SUBSYSTEM - PHỤ TRÁCH: SV1)
-- ==============================================================================

-- 4.1. Bảng: ORDERS (Đơn hàng trung tâm)
CREATE TABLE orders (
    order_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_code          VARCHAR(50) NOT NULL,
    customer_id         BIGINT NOT NULL,
    branch_id           BIGINT NOT NULL,
    driver_id           BIGINT,
    delivery_address_id BIGINT NOT NULL,
    order_status        VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    subtotal_amount     DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    delivery_fee        DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    service_fee         DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount     DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total_amount        DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_orders_code UNIQUE (order_code),
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_orders_branches FOREIGN KEY (branch_id)
        REFERENCES branches (branch_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_orders_drivers FOREIGN KEY (driver_id)
        REFERENCES drivers (driver_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_orders_address FOREIGN KEY (delivery_address_id)
        REFERENCES customer_addresses (address_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_orders_status CHECK (
        order_status IN ('PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'DELIVERED', 'CANCELLED')
    ),
    CONSTRAINT chk_orders_amounts CHECK (
        subtotal_amount >= 0.00 AND delivery_fee >= 0.00 AND service_fee >= 0.00 AND total_amount >= 0.00
    )
);

-- 4.2. Bảng: ORDER_ITEMS (Chi tiết món ăn kèm Snapshot giá lịch sử [BR02])
CREATE TABLE order_items (
    order_item_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id            BIGINT NOT NULL,
    item_id             BIGINT,
    item_name_snapshot  VARCHAR(150) NOT NULL,
    unit_price_snapshot DECIMAL(12, 2) NOT NULL,
    quantity            INTEGER NOT NULL,
    subtotal            DECIMAL(12, 2) NOT NULL,

    CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_items FOREIGN KEY (item_id)
        REFERENCES items (item_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_order_items_qty CHECK (quantity > 0),
    CONSTRAINT chk_order_items_prices CHECK (unit_price_snapshot >= 0.00 AND subtotal >= 0.00)
);

-- 4.3. Bảng: ORDER_ITEM_OPTIONS (Tùy chọn kèm theo món có Snapshot giá [BR02])
CREATE TABLE order_item_options (
    order_item_option_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_item_id        BIGINT NOT NULL,
    option_item_id       BIGINT,
    option_name_snapshot VARCHAR(100) NOT NULL,
    extra_price_snapshot DECIMAL(12, 2) NOT NULL,

    CONSTRAINT fk_options_order_items FOREIGN KEY (order_item_id)
        REFERENCES order_items (order_item_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_options_option_items FOREIGN KEY (option_item_id)
        REFERENCES option_items (option_item_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_options_extra_price CHECK (extra_price_snapshot >= 0.00)
);

-- ==============================================================================
-- PHẦN 5: DDL PHÂN HỆ THANH TOÁN, NHẬT KÝ & ĐÁNH GIÁ (SV3 PHỤ TRÁCH)
-- ==============================================================================

-- 5.1. Siêu lớp: PAYMENTS (Giao dịch kế toán)
CREATE TABLE payments (
    payment_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id        BIGINT NOT NULL,
    amount          DECIMAL(12, 2) NOT NULL,
    payment_method  VARCHAR(20) NOT NULL,
    payment_status  VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    paid_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payments_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_payments_order UNIQUE (order_id),
    CONSTRAINT chk_payments_amount CHECK (amount >= 0.00),
    CONSTRAINT chk_payments_method CHECK (payment_method IN ('CASH', 'CARD', 'EWALLET')),
    CONSTRAINT chk_payments_status CHECK (payment_status IN ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED'))
);

-- 5.2. Phân lớp: CASH_PAYMENTS
CREATE TABLE cash_payments (
    payment_id          BIGINT PRIMARY KEY,
    change_amount_for   DECIMAL(12, 2),

    CONSTRAINT fk_cash_payments FOREIGN KEY (payment_id)
        REFERENCES payments (payment_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_cash_change CHECK (change_amount_for IS NULL OR change_amount_for >= 0.00)
);

-- 5.3. Phân lớp: CARD_PAYMENTS (Tuân thủ chuẩn bảo mật PCI DSS)
CREATE TABLE card_payments (
    payment_id      BIGINT PRIMARY KEY,
    card_last4      VARCHAR(4) NOT NULL,
    card_brand      VARCHAR(20) NOT NULL,
    transaction_ref VARCHAR(100) NOT NULL,

    CONSTRAINT fk_card_payments FOREIGN KEY (payment_id)
        REFERENCES payments (payment_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_card_transaction_ref UNIQUE (transaction_ref),
    CONSTRAINT chk_card_last4 CHECK (card_last4 ~ '^[0-9]{4}$'),
    CONSTRAINT chk_card_brand CHECK (card_brand IN ('VISA', 'MASTERCARD', 'JCB', 'NAPAS'))
);

-- 5.4. Phân lớp: EWALLET_PAYMENTS
CREATE TABLE ewallet_payments (
    payment_id              BIGINT PRIMARY KEY,
    wallet_provider         VARCHAR(20) NOT NULL,
    wallet_transaction_id   VARCHAR(100) NOT NULL,

    CONSTRAINT fk_ewallet_payments FOREIGN KEY (payment_id)
        REFERENCES payments (payment_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_ewallet_transaction_id UNIQUE (wallet_transaction_id),
    CONSTRAINT chk_ewallet_provider CHECK (wallet_provider IN ('MOMO', 'ZALOPAY', 'SHOPEEPAY'))
);

-- 5.5. Bảng: ORDER_STATUS_LOGS (Nhật ký dòng thời gian [BR04])
CREATE TABLE order_status_logs (
    log_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id            BIGINT NOT NULL,
    previous_status     VARCHAR(30),
    new_status          VARCHAR(30) NOT NULL,
    changed_by_user_id  BIGINT,
    note                TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_logs_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_logs_users FOREIGN KEY (changed_by_user_id)
        REFERENCES users (user_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_logs_status CHECK (
        new_status IN ('PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'DELIVERED', 'CANCELLED')
    )
);

CREATE INDEX idx_logs_order_id ON order_status_logs (order_id);

-- 5.6. Bảng: RESTAURANT_REVIEWS (Đánh giá nhà hàng [BR07])
CREATE TABLE restaurant_reviews (
    review_id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id                BIGINT NOT NULL,
    customer_id             BIGINT NOT NULL,
    restaurant_id           BIGINT NOT NULL,
    rating                  SMALLINT NOT NULL,
    comment                 TEXT,
    reply_from_merchant     TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reviews_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_customers FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_restaurants FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_restaurant_reviews_order UNIQUE (order_id),
    CONSTRAINT chk_restaurant_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE INDEX idx_reviews_restaurant_id ON restaurant_reviews (restaurant_id);

-- 5.7. Bảng: DRIVER_REVIEWS (Đánh giá tài xế [BR07])
CREATE TABLE driver_reviews (
    review_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id            BIGINT NOT NULL,
    customer_id         BIGINT NOT NULL,
    driver_id           BIGINT NOT NULL,
    rating              SMALLINT NOT NULL,
    comment             TEXT,
    tipping_amount      DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_driver_reviews_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_driver_reviews_customers FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_driver_reviews_drivers FOREIGN KEY (driver_id)
        REFERENCES drivers (driver_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_driver_reviews_order UNIQUE (order_id),
    CONSTRAINT chk_driver_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT chk_driver_tipping CHECK (tipping_amount >= 0.00)
);

CREATE INDEX idx_reviews_driver_id ON driver_reviews (driver_id);

-- ==============================================================================
-- PHẦN 6: DỮ LIỆU MẪU KIỂM THỬ LIÊN THÔNG TOÀN SÀN (END-TO-END SEED DATA)
-- ==============================================================================

-- 6.1. Users
INSERT INTO users (user_id, email, phone_number, password_hash, full_name, user_type, status)
OVERRIDING SYSTEM VALUE VALUES
    (1, 'an.nguyen@gmail.com', '0901234567', '$2a$12$hashAn', 'Nguyễn Văn An', 'CUSTOMER', 'ACTIVE'),
    (2, 'bich.tran@gmail.com', '0912345678', '$2a$12$hashBich', 'Trần Thị Bích', 'CUSTOMER', 'ACTIVE'),
    (3, 'nam.le@gmail.com',     '0988889999', '$2a$12$hashNam', 'Lê Hoàng Nam', 'MERCHANT_OWNER', 'ACTIVE'),
    (4, 'hung.vo@gmail.com',    '0933445566', '$2a$12$hashHung', 'Võ Quốc Hưng', 'DRIVER', 'ACTIVE'),
    (5, 'hai.nguyen@gmail.com', '0931111101', '$2a$12$hashHai', 'Nguyễn Văn Hải', 'DRIVER', 'ACTIVE'),
    (6, 'tuan.tran@gmail.com',  '0931111102', '$2a$12$hashTuan', 'Trần Minh Tuấn', 'DRIVER', 'ACTIVE');

-- 6.2. Customers
INSERT INTO customers (customer_id, loyalty_points, birth_date, avatar_url)
VALUES 
    (1, 150, '1998-05-12', 'https://storage.food.vn/avatars/u1.jpg'),
    (2, 50,  '2001-11-20', 'https://storage.food.vn/avatars/u2.jpg');

-- 6.3. Customer Addresses
INSERT INTO customer_addresses (address_id, customer_id, recipient_name, recipient_phone, street_address, ward, district, city, latitude, longitude, address_label, is_default)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 'Nguyễn Văn An', '0901234567', 'Số 123 Đường Nguyễn Huệ', 'Bến Nghé', 'Quận 1', 'TP. Hồ Chí Minh', 10.77450000, 106.70320000, 'Nhà riêng', TRUE),
    (2, 2, 'Trần Thị Bích', '0912345678', 'Masteri Thảo Điền', 'Thảo Điền', 'Thủ Đức', 'TP. Hồ Chí Minh', 10.80380000, 106.74100000, 'Căn hộ', TRUE);

-- 6.4. Merchant Owners
INSERT INTO merchant_owners (merchant_owner_id, tax_code, identity_card_number, business_license_url, kyc_status, verified_at)
VALUES 
    (3, '0315894123', '079098001234', 'https://storage.food.vn/licenses/comtam.pdf', 'VERIFIED', CURRENT_TIMESTAMP);

-- 6.5. Restaurants
INSERT INTO restaurants (restaurant_id, owner_id, restaurant_name, cuisine_type, description, is_active)
OVERRIDING SYSTEM VALUE VALUES
    (1, 3, 'Cơm Tấm Sài Gòn Xưa', 'Cơm Tấm & Món Việt', 'Hương vị cơm tấm sườn nướng than hoa', TRUE),
    (2, 3, 'Boba House - Trà Sữa Đài Loan', 'Trà Sữa & Đồ Uống', 'Trà sữa đậm vị lá trà tươi', TRUE);

-- 6.6. Branches
INSERT INTO branches (branch_id, restaurant_id, branch_name, phone_number, street_address, ward, district, city, latitude, longitude, opening_time, closing_time, is_active)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 'Chi nhánh Bến Nghé Quận 1', '02838221144', 'Số 45 Nguyễn Huệ', 'Bến Nghé', 'Quận 1', 'TP. Hồ Chí Minh', 10.77420000, 106.70300000, '06:30:00', '22:00:00', TRUE),
    (2, 2, 'Chi nhánh Sư Vạn Hạnh Quận 10', '02838663366', 'Số 780 Sư Vạn Hạnh', 'Phường 12', 'Quận 10', 'TP. Hồ Chí Minh', 10.77600000, 106.66750000, '08:30:00', '22:30:00', TRUE);

-- 6.7. Categories
INSERT INTO categories (category_id, restaurant_id, category_name, display_order, is_active)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 'Cơm Tấm Truyền Thống', 1, TRUE),
    (2, 2, 'Trà Sữa Đậm Vị', 1, TRUE);

-- 6.8. Items
INSERT INTO items (item_id, category_id, item_name, description, base_price, is_available)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 'Cơm Sườn Bì Chả Đặc Biệt', 'Sườn cọng nướng kèm bì và chả trứng', 65000.00, TRUE),
    (2, 2, 'Trà Sữa Trân Châu Đường Đen', 'Trà đen Ceylon sữa tươi trân châu đường đen', 42000.00, TRUE);

-- 6.9. Option Groups
INSERT INTO option_groups (group_id, item_id, group_name, min_selection, max_selection, is_required)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 'Món Gọi Thêm', 0, 3, FALSE),
    (2, 2, 'Chọn Kích Cỡ Ly', 1, 1, TRUE);

-- 6.10. Option Items
INSERT INTO option_items (option_item_id, group_id, option_name, extra_price, is_available)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 'Trứng ốp la lòng đào', 10000.00, TRUE),
    (2, 1, 'Tóp mỡ béo ngậy', 5000.00, TRUE),
    (3, 2, 'Size M (500ml)', 0.00, TRUE),
    (4, 2, 'Size L (700ml)', 10000.00, TRUE);

-- 6.11. Drivers
INSERT INTO drivers (driver_id, license_number, vehicle_type, vehicle_plate, current_lat, current_long, driver_status, is_active, rating_average, total_trips)
VALUES
    (4, 'GPLX-7900', 'MOTORBIKE', '59-X1 999.99', 10.77350000, 106.70100000, 'DELIVERING', TRUE, 4.95, 320),
    (5, 'GPLX-7901', 'MOTORBIKE', '59-A1 111.11', 10.77150000, 106.70420000, 'AVAILABLE', TRUE, 4.90, 150),
    (6, 'GPLX-7902', 'MOTORBIKE', '59-A1 222.22', 10.77210000, 106.69830000, 'AVAILABLE', TRUE, 4.80, 210);

-- 6.12. Orders
INSERT INTO orders (order_id, order_code, customer_id, branch_id, driver_id, delivery_address_id, order_status, subtotal_amount, delivery_fee, service_fee, discount_amount, total_amount)
OVERRIDING SYSTEM VALUE VALUES
    (1, 'ORD-20261021-001', 1, 1, 4, 1, 'DELIVERED', 80000.00, 16000.00, 4000.00, 0.00, 100000.00);

-- 6.13. Order Items & Options
INSERT INTO order_items (order_item_id, order_id, item_id, item_name_snapshot, unit_price_snapshot, quantity, subtotal)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 1, 'Cơm Sườn Bì Chả Đặc Biệt', 65000.00, 1, 65000.00);

INSERT INTO order_item_options (order_item_option_id, order_item_id, option_item_id, option_name_snapshot, extra_price_snapshot)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 1, 'Trứng ốp la lòng đào', 10000.00),
    (2, 1, 2, 'Tóp mỡ béo ngậy', 5000.00);

-- 6.14. Payments
INSERT INTO payments (payment_id, order_id, amount, payment_method, payment_status, paid_at)
OVERRIDING SYSTEM VALUE VALUES
    (1, 1, 100000.00, 'CARD', 'SUCCESS', CURRENT_TIMESTAMP);

INSERT INTO card_payments (payment_id, card_last4, card_brand, transaction_ref)
VALUES
    (1, '9876', 'VISA', 'TXN_VNPAY_20261021_0001');

-- 6.15. Order Status Logs
INSERT INTO order_status_logs (order_id, previous_status, new_status, changed_by_user_id, note)
VALUES
    (1, NULL, 'PENDING', 1, 'Khách đặt đơn qua ứng dụng'),
    (1, 'PENDING', 'CONFIRMED', 3, 'Nhà hàng xác nhận đơn'),
    (1, 'CONFIRMED', 'PREPARING', 3, 'Bếp đang chế biến'),
    (1, 'PREPARING', 'READY_FOR_PICKUP', 3, 'Món đã đóng gói xong'),
    (1, 'READY_FOR_PICKUP', 'PICKED_UP', 4, 'Tài xế đã lấy món'),
    (1, 'PICKED_UP', 'DELIVERED', 4, 'Giao hàng thành công');

-- 6.16. Reviews
INSERT INTO restaurant_reviews (order_id, customer_id, restaurant_id, rating, comment, reply_from_merchant)
VALUES
    (1, 1, 1, 5, 'Cơm sườn nướng rất mềm thơm, đóng gói cẩn thận 5 sao!', 'Cảm ơn bạn đã ủng hộ quán ạ!');

INSERT INTO driver_reviews (order_id, customer_id, driver_id, rating, comment, tipping_amount)
VALUES
    (1, 1, 4, 5, 'Tài xế giao hàng siêu nhanh, thân thiện!', 10000.00);

-- Đồng bộ lại sequence tự sinh
SELECT setval(pg_get_serial_sequence('users', 'user_id'), (SELECT MAX(user_id) FROM users));
SELECT setval(pg_get_serial_sequence('customer_addresses', 'address_id'), (SELECT MAX(address_id) FROM customer_addresses));
SELECT setval(pg_get_serial_sequence('restaurants', 'restaurant_id'), (SELECT MAX(restaurant_id) FROM restaurants));
SELECT setval(pg_get_serial_sequence('branches', 'branch_id'), (SELECT MAX(branch_id) FROM branches));
SELECT setval(pg_get_serial_sequence('categories', 'category_id'), (SELECT MAX(category_id) FROM categories));
SELECT setval(pg_get_serial_sequence('items', 'item_id'), (SELECT MAX(item_id) FROM items));
SELECT setval(pg_get_serial_sequence('option_groups', 'group_id'), (SELECT MAX(group_id) FROM option_groups));
SELECT setval(pg_get_serial_sequence('option_items', 'option_item_id'), (SELECT MAX(option_item_id) FROM option_items));
SELECT setval(pg_get_serial_sequence('orders', 'order_id'), (SELECT MAX(order_id) FROM orders));
SELECT setval(pg_get_serial_sequence('order_items', 'order_item_id'), (SELECT MAX(order_item_id) FROM order_items));
SELECT setval(pg_get_serial_sequence('order_item_options', 'order_item_option_id'), (SELECT MAX(order_item_option_id) FROM order_item_options));
SELECT setval(pg_get_serial_sequence('payments', 'payment_id'), (SELECT MAX(payment_id) FROM payments));

-- ==============================================================================
-- PHẦN 7: CÁC TRUY VẤN TỔNG HỢP KIỂM CHỨNG TOÀN HỆ THỐNG
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 7.1. TRUY VẤN JOIN 4 BÊN TRỌNG TÂM: CHI TIẾT HÓA ĐƠN ĐƠN HÀNG [SV1]
-- Liên kết 4 bên: Đơn hàng + Món đặt + Tùy chọn Topping + Thanh toán & Tài xế
-- ------------------------------------------------------------------------------
SELECT 
    o.order_code,
    u_c.full_name AS customer_name,
    ca.recipient_phone,
    ca.street_address || ', ' || ca.district || ', ' || ca.city AS delivery_address,
    b.branch_name,
    u_d.full_name AS driver_name,
    d.vehicle_plate,
    oi.item_name_snapshot AS item_name,
    oi.unit_price_snapshot,
    oi.quantity,
    COALESCE(oio.option_name_snapshot, 'Không có tùy chọn') AS option_name,
    COALESCE(oio.extra_price_snapshot, 0.00) AS option_extra_price,
    o.delivery_fee,
    o.total_amount,
    p.payment_method,
    p.payment_status,
    cp.card_brand,
    cp.card_last4
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN users u_c ON c.customer_id = u_c.user_id
JOIN customer_addresses ca ON o.delivery_address_id = ca.address_id
JOIN branches b ON o.branch_id = b.branch_id
LEFT JOIN drivers d ON o.driver_id = d.driver_id
LEFT JOIN users u_d ON d.driver_id = u_d.user_id
JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_item_options oio ON oi.order_item_id = oio.order_item_id
LEFT JOIN payments p ON o.order_id = p.order_id
LEFT JOIN card_payments cp ON p.payment_id = cp.payment_id
WHERE o.order_id = 1;

-- ------------------------------------------------------------------------------
-- 7.2. TRUY VẤN SPATIAL DISPATCHING HAVERSINE: TÌM TOP TÀI XẾ SẴN SÀNG GẦN QUÁN [SV3]
-- Tìm tài xế AVAILABLE gần Chi nhánh 1 (45 Nguyễn Huệ: 10.7742, 106.7030)
-- ------------------------------------------------------------------------------
SELECT 
    d.driver_id,
    u.full_name AS driver_name,
    u.phone_number,
    d.vehicle_type,
    d.vehicle_plate,
    d.rating_average,
    d.total_trips,
    ROUND(
        (
            6371.0 * 2.0 * ASIN(
                SQRT(
                    LEAST(1.0, GREATEST(0.0,
                        POWER(SIN(RADIANS(d.current_lat - 10.77420000) / 2.0), 2) +
                        COS(RADIANS(10.77420000)) * COS(RADIANS(d.current_lat)) *
                        POWER(SIN(RADIANS(d.current_long - 106.70300000) / 2.0), 2)
                    ))
                )
            )
        )::numeric, 3
    ) AS distance_km,
    ROUND((
        (
            6371.0 * 2.0 * ASIN(
                SQRT(
                    LEAST(1.0, GREATEST(0.0,
                        POWER(SIN(RADIANS(d.current_lat - 10.77420000) / 2.0), 2) +
                        COS(RADIANS(10.77420000)) * COS(RADIANS(d.current_lat)) *
                        POWER(SIN(RADIANS(d.current_long - 106.70300000) / 2.0), 2)
                    ))
                )
            )
        ) / 25.0 * 60.0
    )::numeric, 1) AS estimated_pickup_minutes
FROM drivers d
JOIN users u ON d.driver_id = u.user_id
WHERE d.driver_status = 'AVAILABLE'
  AND d.is_active = TRUE
  AND d.current_lat IS NOT NULL
  AND d.current_long IS NOT NULL
  AND d.current_lat BETWEEN -90.0 AND 90.0
  AND d.current_long BETWEEN -180.0 AND 180.0
ORDER BY distance_km ASC, d.rating_average DESC, d.driver_id ASC
LIMIT 5;

-- ------------------------------------------------------------------------------
-- 7.3. TRUY VẤN THỐNG KÊ TỔNG HỢP TOÀN BỘ 21 BẢNG
-- ------------------------------------------------------------------------------
SELECT 'users' AS table_name, COUNT(*) AS total_rows FROM users UNION ALL
SELECT 'customers', COUNT(*) FROM customers UNION ALL
SELECT 'customer_addresses', COUNT(*) FROM customer_addresses UNION ALL
SELECT 'merchant_owners', COUNT(*) FROM merchant_owners UNION ALL
SELECT 'restaurants', COUNT(*) FROM restaurants UNION ALL
SELECT 'branches', COUNT(*) FROM branches UNION ALL
SELECT 'categories', COUNT(*) FROM categories UNION ALL
SELECT 'items', COUNT(*) FROM items UNION ALL
SELECT 'option_groups', COUNT(*) FROM option_groups UNION ALL
SELECT 'option_items', COUNT(*) FROM option_items UNION ALL
SELECT 'drivers', COUNT(*) FROM drivers UNION ALL
SELECT 'orders', COUNT(*) FROM orders UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items UNION ALL
SELECT 'order_item_options', COUNT(*) FROM order_item_options UNION ALL
SELECT 'payments', COUNT(*) FROM payments UNION ALL
SELECT 'cash_payments', COUNT(*) FROM cash_payments UNION ALL
SELECT 'card_payments', COUNT(*) FROM card_payments UNION ALL
SELECT 'ewallet_payments', COUNT(*) FROM ewallet_payments UNION ALL
SELECT 'order_status_logs', COUNT(*) FROM order_status_logs UNION ALL
SELECT 'restaurant_reviews', COUNT(*) FROM restaurant_reviews UNION ALL
SELECT 'driver_reviews', COUNT(*) FROM driver_reviews;
