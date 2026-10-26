-- ==============================================================================
-- KỊCH BẢN DDL VÀ RÀNG BUỘC: PHÂN HỆ ĐƠN HÀNG TRUNG TÂM (ORDER SUBSYSTEM)
-- Dự án: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
-- Phụ trách: SV1 - Nhóm trưởng (Bùi Duy Quang)
-- Hệ quản trị CSDL mục tiêu: PostgreSQL 14+ / 15 / 16
-- 
-- Danh mục 3 bảng cốt lõi:
--   1. ORDERS             : Đơn hàng trung tâm kết nối Khách hàng, Chi nhánh quán ăn, Tài xế
--   2. ORDER_ITEMS        : Chi tiết món đặt kèm ảnh chụp giá lịch sử (Unit Price Snapshot)
--   3. ORDER_ITEM_OPTIONS : Chi tiết tùy chọn/topping kèm đơn giá snapshot (Extra Price Snapshot)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. DỌN DẸP DỮ LIỆU CŨ (CLEANUP / ROLLBACK SCRIPT)
-- Xóa theo thứ tự: Bảng con trước, Bảng cha sau để không vi phạm ràng buộc FK
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS order_item_options CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;

-- ------------------------------------------------------------------------------
-- 1. BẢNG: ORDERS (Đơn hàng trung tâm kết nối các tác nhân sàn giao dịch)
-- ------------------------------------------------------------------------------
CREATE TABLE orders (
    order_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_code          VARCHAR(32) NOT NULL,
    customer_id         BIGINT NOT NULL,
    branch_id           BIGINT NOT NULL,
    driver_id           BIGINT, -- Cho phép NULL khi đơn mới tạo, đang chờ điều phối tài xế
    delivery_address_id BIGINT NOT NULL,
    
    order_status        VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    payment_status      VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
    
    -- Các trường tiền tệ (Đảm bảo snapshot và đối soát tài chính minh bạch)
    subtotal_amount     DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    delivery_fee        DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    service_fee         DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    discount_amount     DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    total_amount        DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    
    delivery_distance_km DECIMAL(6, 2),
    driver_rating       SMALLINT,
    restaurant_rating   SMALLINT,
    customer_note       TEXT,
    cancel_reason       VARCHAR(255),
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Ràng buộc mã đơn hàng là duy nhất toàn sàn
    CONSTRAINT uq_orders_order_code UNIQUE (order_code),

    -- Khóa ngoại tham chiếu Khách hàng (SV1)
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Khóa ngoại tham chiếu Chi nhánh nhà hàng (SV2)
    CONSTRAINT fk_orders_branches FOREIGN KEY (branch_id)
        REFERENCES branches (branch_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Khóa ngoại tham chiếu Sổ địa chỉ giao hàng (SV1)
    CONSTRAINT fk_orders_customer_addresses FOREIGN KEY (delivery_address_id)
        REFERENCES customer_addresses (address_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- [BR04] Máy trạng thái vòng đời đơn hàng nghiêm ngặt (DoorDash Order State Machine)
    CONSTRAINT chk_orders_status CHECK (
        order_status IN (
            'PENDING',           -- Khách vừa tạo đơn
            'CONFIRMED',         -- Quán đã tiếp nhận
            'PREPARING',         -- Đang nấu/chế biến món
            'READY_FOR_PICKUP',  -- Món đã đóng gói xong, chờ tài xế lấy
            'PICKED_UP',         -- Tài xế đã lấy món, đang trên đường giao
            'DELIVERED',         -- Giao thành công
            'CANCELLED'          -- Đơn đã hủy
        )
    ),

    -- Ràng buộc trạng thái thanh toán
    CONSTRAINT chk_orders_payment_status CHECK (
        payment_status IN ('UNPAID', 'AUTHORIZED', 'PAID', 'REFUNDED')
    ),

    -- Ràng buộc tài chính không âm
    CONSTRAINT chk_orders_amounts CHECK (
        subtotal_amount >= 0 AND
        delivery_fee >= 0 AND
        service_fee >= 0 AND
        discount_amount >= 0 AND
        total_amount >= 0
    ),

    -- Điểm đánh giá (1 đến 5 sao nếu có)
    CONSTRAINT chk_orders_driver_rating CHECK (driver_rating IS NULL OR driver_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_orders_restaurant_rating CHECK (restaurant_rating IS NULL OR restaurant_rating BETWEEN 1 AND 5)
);

-- Chỉ mục tối ưu tìm kiếm theo khách hàng, chi nhánh, và trạng thái đơn hàng
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_orders_branch_id ON orders (branch_id);
CREATE INDEX idx_orders_status ON orders (order_status);
CREATE INDEX idx_orders_created_at ON orders (created_at DESC);

COMMENT ON TABLE orders IS 'Bảng trung tâm lưu trữ đơn hàng liên kết khách, quán, tài xế và dòng tiền';
COMMENT ON COLUMN orders.order_code IS 'Mã đơn sinh ngẫu nhiên định dạng chuỗi dễ đọc cho tài xế và khách (VD: ORD-20261026-001)';
COMMENT ON COLUMN orders.driver_id IS 'Mã định danh tài xế (SV3), cho phép NULL khi đơn chưa gán cuốc';

-- ------------------------------------------------------------------------------
-- 2. BẢNG: ORDER_ITEMS (Chi tiết từng món trong đơn kèm Snapshot giá lịch sử)
-- [BR02] Bắt buộc lưu snapshot unit_price_snapshot để chống hiện tượng Price Drift
-- ------------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id            BIGINT NOT NULL,
    item_id             BIGINT, -- Cho phép SET NULL nếu sau này quán xóa món gốc trong thực đơn
    
    item_name_snapshot  VARCHAR(150) NOT NULL,
    unit_price_snapshot DECIMAL(10, 2) NOT NULL,
    quantity            INTEGER NOT NULL DEFAULT 1,
    subtotal            DECIMAL(12, 2) NOT NULL,
    item_note           VARCHAR(255),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Khóa ngoại tham chiếu Đơn hàng
    CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Khóa ngoại tham chiếu Món ăn danh mục của SV2
    CONSTRAINT fk_order_items_items FOREIGN KEY (item_id)
        REFERENCES items (item_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Ràng buộc số lượng và đơn giá
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_unit_price CHECK (unit_price_snapshot >= 0),
    CONSTRAINT chk_order_items_subtotal CHECK (subtotal >= 0)
);

CREATE INDEX idx_order_items_order_id ON order_items (order_id);
CREATE INDEX idx_order_items_item_id ON order_items (item_id);

COMMENT ON TABLE order_items IS 'Danh sách các món ăn trong đơn kèm snapshot giá lịch sử tránh trôi giá';
COMMENT ON COLUMN order_items.unit_price_snapshot IS 'Giá niêm yết của món tại đúng thời điểm khách đặt hàng';

-- ------------------------------------------------------------------------------
-- 3. BẢNG: ORDER_ITEM_OPTIONS (Tùy chọn/Topping đính kèm món trong đơn)
-- ------------------------------------------------------------------------------
CREATE TABLE order_item_options (
    order_item_option_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_item_id        BIGINT NOT NULL,
    option_item_id       BIGINT, -- Cho phép SET NULL nếu sau này quán cập nhật lại nhóm tùy chọn
    
    option_name_snapshot VARCHAR(100) NOT NULL,
    extra_price_snapshot DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Khóa ngoại tham chiếu Món ăn cụ thể trong đơn
    CONSTRAINT fk_order_item_options_order_items FOREIGN KEY (order_item_id)
        REFERENCES order_items (order_item_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Khóa ngoại tham chiếu Tùy chọn gốc của SV2
    CONSTRAINT fk_order_item_options_option_items FOREIGN KEY (option_item_id)
        REFERENCES option_items (option_item_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Ràng buộc giá phụ thu không âm
    CONSTRAINT chk_order_item_options_extra_price CHECK (extra_price_snapshot >= 0)
);

CREATE INDEX idx_order_item_options_item_id ON order_item_options (order_item_id);

COMMENT ON TABLE order_item_options IS 'Tùy chọn topping, kích cỡ, mức đường/đá chọn kèm món trong đơn';
COMMENT ON COLUMN order_item_options.extra_price_snapshot IS 'Mức phụ thu của topping tại thời điểm đặt hàng';
