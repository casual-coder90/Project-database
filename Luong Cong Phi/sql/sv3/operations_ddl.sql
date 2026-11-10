-- ==============================================================================
-- KỊCH BẢN DDL: PHÂN HỆ VẬN HÀNH, THANH TOÁN & ĐÁNH GIÁ (OPERATIONS SUBSYSTEM)
-- Dự án: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
-- Phụ trách: SV3 - Kỹ sư CSDL & Vận hành GIS (Lương Công Phi)
-- Hệ quản trị CSDL mục tiêu: PostgreSQL 14+ / 15 / 16
-- 
-- Danh mục 8 bảng phụ trách:
--   1. DRIVERS            : Phân lớp đối tác tài xế (kế thừa từ USERS)
--   2. PAYMENTS           : Siêu lớp thanh toán kế toán của đơn hàng
--   3. CASH_PAYMENTS      : Phân lớp thanh toán tiền mặt (COD)
--   4. CARD_PAYMENTS      : Phân lớp thanh toán thẻ ngân hàng / quốc tế
--   5. EWALLET_PAYMENTS   : Phân lớp thanh toán ví điện tử tích hợp
--   6. ORDER_STATUS_LOGS  : Nhật ký dòng thời gian chuyển đổi trạng thái đơn
--   7. RESTAURANT_REVIEWS : Đánh giá nhà hàng từ khách hàng
--   8. DRIVER_REVIEWS     : Đánh giá thái độ tài xế từ khách hàng
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. DỌN DẸP DỮ LIỆU CŨ (CLEANUP / ROLLBACK SCRIPT)
-- Xóa theo thứ tự: Bảng con trước, Bảng cha sau để không vi phạm ràng buộc FK
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS driver_reviews CASCADE;
DROP TABLE IF EXISTS restaurant_reviews CASCADE;
DROP TABLE IF EXISTS order_status_logs CASCADE;
DROP TABLE IF EXISTS ewallet_payments CASCADE;
DROP TABLE IF EXISTS card_payments CASCADE;
DROP TABLE IF EXISTS cash_payments CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;

-- ------------------------------------------------------------------------------
-- 1. BẢNG PHÂN LỚP: DRIVERS (Đối tác tài xế giao hàng)
-- Kế thừa từ siêu lớp USERS của SV1: driver_id vừa là PK vừa là FK
-- ------------------------------------------------------------------------------
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

    -- Khóa ngoại tham chiếu bảng cha USERS
    CONSTRAINT fk_drivers_users FOREIGN KEY (driver_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Tính duy nhất cho Giấy phép lái xe và Biển số xe
    CONSTRAINT uq_drivers_license UNIQUE (license_number),
    CONSTRAINT uq_drivers_plate UNIQUE (vehicle_plate),

    -- Ràng buộc loại phương tiện hợp lệ
    CONSTRAINT chk_drivers_vehicle_type CHECK (
        vehicle_type IN ('MOTORBIKE', 'ELECTRIC_BIKE', 'CAR')
    ),

    -- Ràng buộc máy trạng thái tài xế
    CONSTRAINT chk_drivers_status CHECK (
        driver_status IN ('OFFLINE', 'AVAILABLE', 'DELIVERING')
    ),

    -- Ràng buộc phạm vi tọa độ GPS (WGS-84) khi có cập nhật vị trí
    CONSTRAINT chk_drivers_latitude CHECK (
        current_lat IS NULL OR (current_lat BETWEEN -90.0 AND 90.0)
    ),
    CONSTRAINT chk_drivers_longitude CHECK (
        current_long IS NULL OR (current_long BETWEEN -180.0 AND 180.0)
    ),

    -- Ràng buộc điểm đánh giá sao và số chuyến
    CONSTRAINT chk_drivers_rating CHECK (rating_average BETWEEN 1.00 AND 5.00),
    CONSTRAINT chk_drivers_trips CHECK (total_trips >= 0)
);

-- TỐI ƯU HÓA CHỈ MỤC CHO THUẬT TOÁN ĐIỀU PHỐI TÀI XẾ (PARTIAL B-TREE INDEX)
-- Chỉ lập chỉ mục các tài xế AVAILABLE, ACTIVE và đã bật định vị GPS:
CREATE INDEX idx_drivers_available_dispatch
    ON drivers (current_lat, current_long)
    WHERE (driver_status = 'AVAILABLE' AND is_active = TRUE AND current_lat IS NOT NULL AND current_long IS NOT NULL);

COMMENT ON TABLE drivers IS 'Phân lớp tài xế giao hàng, lưu vết phương tiện, trạng thái và tọa độ GPS';
COMMENT ON COLUMN drivers.driver_status IS 'Trạng thái cuốc xe: OFFLINE (Nghỉ), AVAILABLE (Sẵn sàng nhận đơn), DELIVERING (Đang giao)';
COMMENT ON INDEX idx_drivers_available_dispatch IS 'Partial Index tối ưu hóa truy vấn tìm tài xế lân cận theo thuật toán Haversine';

-- ------------------------------------------------------------------------------
-- 2. BẢNG SIÊU LỚP: PAYMENTS (Giao dịch thanh toán kế toán đơn hàng)
-- Phụ thuộc vào: orders(order_id) thuộc phân hệ SV1
-- ------------------------------------------------------------------------------
CREATE TABLE payments (
    payment_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id        BIGINT NOT NULL,
    amount          DECIMAL(12, 2) NOT NULL,
    payment_method  VARCHAR(20) NOT NULL,
    payment_status  VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    paid_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Khóa ngoại tham chiếu đơn hàng
    CONSTRAINT fk_payments_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Quy tắc [BR05]: Mỗi đơn hàng ứng với 1 giao dịch thanh toán duy nhất
    CONSTRAINT uq_payments_order UNIQUE (order_id),

    -- Ràng buộc số tiền thanh toán không âm
    CONSTRAINT chk_payments_amount CHECK (amount >= 0.00),

    -- Cờ phân loại siêu lớp (Disjoint Specialization)
    CONSTRAINT chk_payments_method CHECK (
        payment_method IN ('CASH', 'CARD', 'EWALLET')
    ),

    -- Ràng buộc trạng thái thanh toán
    CONSTRAINT chk_payments_status CHECK (
        payment_status IN ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED')
    )
);

COMMENT ON TABLE payments IS 'Siêu lớp thanh toán kế toán của đơn hàng';
COMMENT ON COLUMN payments.order_id IS 'Khóa ngoại logic tham chiếu ORDERS(order_id), đảm bảo tính duy nhất';

-- ------------------------------------------------------------------------------
-- 3. BẢNG PHÂN LỚP: CASH_PAYMENTS (Thanh toán tiền mặt khi nhận hàng - COD)
-- Kế thừa từ PAYMENTS: payment_id vừa là PK vừa là FK
-- ------------------------------------------------------------------------------
CREATE TABLE cash_payments (
    payment_id          BIGINT PRIMARY KEY,
    change_amount_for   DECIMAL(12, 2),

    CONSTRAINT fk_cash_payments FOREIGN KEY (payment_id)
        REFERENCES payments (payment_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_cash_change CHECK (
        change_amount_for IS NULL OR change_amount_for >= 0.00
    )
);

COMMENT ON TABLE cash_payments IS 'Phân lớp thanh toán tiền mặt cho tài xế khi giao hàng';
COMMENT ON COLUMN cash_payments.change_amount_for IS 'Mệnh giá tiền mặt khách chuẩn bị để tài xế thối lại (nếu có)';

-- ------------------------------------------------------------------------------
-- 4. BẢNG PHÂN LỚP: CARD_PAYMENTS (Thanh toán qua thẻ ngân hàng)
-- Tuân thủ chuẩn bảo mật PCI DSS: CẤM LƯU SỐ THẺ ĐẦY ĐỦ VÀ MÃ CVV
-- ------------------------------------------------------------------------------
CREATE TABLE card_payments (
    payment_id      BIGINT PRIMARY KEY,
    card_last4      VARCHAR(4) NOT NULL,
    card_brand      VARCHAR(20) NOT NULL,
    transaction_ref VARCHAR(100) NOT NULL,

    CONSTRAINT fk_card_payments FOREIGN KEY (payment_id)
        REFERENCES payments (payment_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT uq_card_transaction_ref UNIQUE (transaction_ref),

    -- Ràng buộc chỉ lưu 4 số cuối của thẻ
    CONSTRAINT chk_card_last4 CHECK (card_last4 ~ '^[0-9]{4}$'),

    -- Ràng buộc tổ chức phát hành thẻ
    CONSTRAINT chk_card_brand CHECK (
        card_brand IN ('VISA', 'MASTERCARD', 'JCB', 'NAPAS')
    )
);

COMMENT ON TABLE card_payments IS 'Phân lớp thanh toán quẹt thẻ/cổng thẻ trực tuyến (Tuân thủ PCI DSS)';
COMMENT ON COLUMN card_payments.card_last4 IS '4 chữ số cuối cùng của thẻ in đối soát trên hóa đơn';

-- ------------------------------------------------------------------------------
-- 5. BẢNG PHÂN LỚP: EWALLET_PAYMENTS (Thanh toán qua ví điện tử tích hợp)
-- ------------------------------------------------------------------------------
CREATE TABLE ewallet_payments (
    payment_id              BIGINT PRIMARY KEY,
    wallet_provider         VARCHAR(20) NOT NULL,
    wallet_transaction_id   VARCHAR(100) NOT NULL,

    CONSTRAINT fk_ewallet_payments FOREIGN KEY (payment_id)
        REFERENCES payments (payment_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT uq_ewallet_transaction_id UNIQUE (wallet_transaction_id),

    CONSTRAINT chk_ewallet_provider CHECK (
        wallet_provider IN ('MOMO', 'ZALOPAY', 'SHOPEEPAY')
    )
);

COMMENT ON TABLE ewallet_payments IS 'Phân lớp thanh toán quét mã QR/liên kết ví điện tử';

-- ------------------------------------------------------------------------------
-- 6. BẢNG: ORDER_STATUS_LOGS (Nhật ký dòng thời gian trạng thái đơn)
-- Phụ thuộc vào: orders(order_id) và users(user_id)
-- ------------------------------------------------------------------------------
CREATE TABLE order_status_logs (
    log_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id            BIGINT NOT NULL,
    previous_status     VARCHAR(30),
    new_status          VARCHAR(30) NOT NULL,
    changed_by_user_id  BIGINT,
    note                TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_logs_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_logs_users FOREIGN KEY (changed_by_user_id)
        REFERENCES users (user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Ràng buộc danh mục trạng thái đơn hàng [BR04]
    CONSTRAINT chk_logs_status CHECK (
        new_status IN ('PENDING', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'DELIVERED', 'CANCELLED')
    )
);

CREATE INDEX idx_logs_order_id ON order_status_logs (order_id);

COMMENT ON TABLE order_status_logs IS 'Ghi vết dòng thời gian kiểm toán chuyển đổi trạng thái đơn hàng';

-- ------------------------------------------------------------------------------
-- 7. BẢNG: RESTAURANT_REVIEWS (Khách đánh giá nhà hàng)
-- Phụ thuộc vào: orders(order_id), customers(customer_id), restaurants(restaurant_id)
-- ------------------------------------------------------------------------------
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
        REFERENCES orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_reviews_customers FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_reviews_restaurants FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Quy tắc [BR07]: Mỗi đơn hàng chỉ được đánh giá nhà hàng đúng 1 lần
    CONSTRAINT uq_restaurant_reviews_order UNIQUE (order_id),

    -- Ràng buộc thang điểm từ 1 đến 5 sao
    CONSTRAINT chk_restaurant_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE INDEX idx_reviews_restaurant_id ON restaurant_reviews (restaurant_id);

COMMENT ON TABLE restaurant_reviews IS 'Phản hồi số sao và nhận xét của khách hàng đối với món ăn/quán';

-- ------------------------------------------------------------------------------
-- 8. BẢNG: DRIVER_REVIEWS (Khách đánh giá đối tác tài xế)
-- Phụ thuộc vào: orders(order_id), customers(customer_id), drivers(driver_id)
-- ------------------------------------------------------------------------------
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
        REFERENCES orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_driver_reviews_customers FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_driver_reviews_drivers FOREIGN KEY (driver_id)
        REFERENCES drivers (driver_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Quy tắc [BR07]: Mỗi đơn hàng chỉ được đánh giá tài xế đúng 1 lần
    CONSTRAINT uq_driver_reviews_order UNIQUE (order_id),

    -- Ràng buộc số sao từ 1 đến 5
    CONSTRAINT chk_driver_rating CHECK (rating BETWEEN 1 AND 5),

    -- Tiền boa thêm cho tài xế không âm
    CONSTRAINT chk_driver_tipping CHECK (tipping_amount >= 0.00)
);

CREATE INDEX idx_reviews_driver_id ON driver_reviews (driver_id);

COMMENT ON TABLE driver_reviews IS 'Phản hồi chất lượng phục vụ và tiền boa thêm cho tài xế';

-- ==============================================================================
-- 9. KỊCH BẢN KIỂM CHỨNG BẪY LỖI RÀNG BUỘC (NEGATIVE TEST CASES)
-- ==============================================================================

-- [TEST BẪY LỖI 1]: Cố tình chèn điểm đánh giá sao ngoài đoạn [1, 5] (Vi phạm chk_driver_rating)
-- Kỳ vọng: Lỗi violates check constraint "chk_driver_rating"
/*
INSERT INTO driver_reviews (order_id, customer_id, driver_id, rating, comment)
VALUES (1, 1, 4, 6, 'Dịch vụ tuyệt đỉnh 6 sao');
*/

-- [TEST BẪY LỖI 2]: Cố tình lưu số tiền boa âm (Vi phạm chk_driver_tipping)
-- Kỳ vọng: Lỗi violates check constraint "chk_driver_tipping"
/*
INSERT INTO driver_reviews (order_id, customer_id, driver_id, rating, tipping_amount)
VALUES (1, 1, 4, 5, -15000.00);
*/

-- [TEST BẪY LỖI 3]: Cố tình lưu card_last4 không đủ 4 chữ số (Vi phạm chk_card_last4)
-- Kỳ vọng: Lỗi violates check constraint "chk_card_last4"
/*
INSERT INTO card_payments (payment_id, card_last4, card_brand, transaction_ref)
VALUES (1, '123', 'VISA', 'TXN_TEST_FAIL');
*/
