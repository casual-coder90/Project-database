-- ==============================================================================
-- KỊCH BẢN DDL: PHÂN HỆ NHÀ HÀNG & THỰC ĐƠN (RESTAURANT & MENU SUBSYSTEM)
-- Dự án: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
-- Phụ trách: SV2 - Thành viên nhóm (Phạm Đình Phúc)
-- Hệ quản trị CSDL mục tiêu: PostgreSQL 14+ / 15 / 16
-- 
-- Danh mục 6 bảng phụ trách:
--   1. RESTAURANTS   : Thương hiệu nhà hàng đối tác
--   2. BRANCHES      : Chi nhánh thực tế của nhà hàng (Tọa độ GPS, giờ hoạt động)
--   3. CATEGORIES    : Danh mục thực đơn (Cơm, Đồ uống, Khai vị,...)
--   4. ITEMS         : Món ăn / Đồ uống niêm yết (Giá gốc, trạng thái)
--   5. OPTION_GROUPS : Nhóm tùy chọn bổ sung cho món (Size, Mức đường, Topping)
--   6. OPTION_ITEMS  : Từng lựa chọn chi tiết kèm phụ thu
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. DỌN DẸP DỮ LIỆU CŨ (CLEANUP / ROLLBACK SCRIPT)
-- Xóa theo thứ tự: Bảng con trước, Bảng cha sau để không vi phạm ràng buộc FK
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS option_items CASCADE;
DROP TABLE IF EXISTS option_groups CASCADE;
DROP TABLE IF EXISTS items CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS branches CASCADE;
DROP TABLE IF EXISTS restaurants CASCADE;

-- ------------------------------------------------------------------------------
-- 1. BẢNG: RESTAURANTS (Thương hiệu nhà hàng đối tác)
-- Phụ thuộc vào: merchant_owners(merchant_owner_id) thuộc phân hệ SV1
-- ------------------------------------------------------------------------------
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

    -- Khóa ngoại tham chiếu chủ nhà hàng KYC (SV1)
    CONSTRAINT fk_restaurants_merchant_owners FOREIGN KEY (owner_id)
        REFERENCES merchant_owners (merchant_owner_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Ràng buộc dữ liệu không rỗng
    CONSTRAINT chk_restaurants_name CHECK (LENGTH(TRIM(restaurant_name)) > 0),
    CONSTRAINT chk_restaurants_cuisine CHECK (LENGTH(TRIM(cuisine_type)) > 0)
);

COMMENT ON TABLE restaurants IS 'Thương hiệu nhà hàng đối tác tham gia sàn giao dịch';
COMMENT ON COLUMN restaurants.owner_id IS 'Khóa ngoại tham chiếu MERCHANT_OWNERS(merchant_owner_id) do SV1 quản lý';
COMMENT ON COLUMN restaurants.cuisine_type IS 'Thể loại ẩm thực đặc trưng (Cơm tấm, Trà sữa, Món Hàn,...)';
COMMENT ON COLUMN restaurants.is_active IS 'Trạng thái đối tác: TRUE = Hoạt động, FALSE = Khóa/Tạm dừng';

-- ------------------------------------------------------------------------------
-- 2. BẢNG: BRANCHES (Chi nhánh phục vụ thực tế của nhà hàng)
-- Phụ thuộc vào: restaurants(restaurant_id)
-- ------------------------------------------------------------------------------
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

    -- Khóa ngoại tham chiếu thương hiệu nhà hàng
    CONSTRAINT fk_branches_restaurants FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Tên chi nhánh không được trùng lặp trong cùng một thương hiệu nhà hàng
    CONSTRAINT uq_branches_restaurant_name UNIQUE (restaurant_id, branch_name),

    -- Ràng buộc kiểm tra phạm vi tọa độ GPS hợp lệ (chuẩn WGS-84)
    CONSTRAINT chk_branches_latitude CHECK (latitude BETWEEN -90.0 AND 90.0),
    CONSTRAINT chk_branches_longitude CHECK (longitude BETWEEN -180.0 AND 180.0),

    -- Ràng buộc định dạng số điện thoại
    CONSTRAINT chk_branches_phone CHECK (phone_number ~* '^[0-9+ ]{8,20}$'),
    CONSTRAINT chk_branches_name CHECK (LENGTH(TRIM(branch_name)) > 0),
    CONSTRAINT chk_branches_address CHECK (LENGTH(TRIM(street_address)) > 0)
);

-- GHI CHÚ NGHIỆP VỤ GIỜ HOẠT ĐỘNG [BR-M01]:
-- Không áp dụng CHECK (closing_time > opening_time) nhằm hỗ trợ trường hợp quán mở qua đêm
-- Ví dụ: Quán ăn đêm mở 18:00 và đóng lúc 02:00 sáng hôm sau (closing_time < opening_time là hợp lệ).

COMMENT ON TABLE branches IS 'Điểm bán vật lý cụ thể, nơi tài xế đến lấy món và nhận đơn giao';
COMMENT ON COLUMN branches.latitude IS 'Tọa độ vĩ độ dùng cho giải thuật điều phối tài xế (SV3)';
COMMENT ON COLUMN branches.longitude IS 'Tọa độ kinh độ dùng cho giải thuật điều phối tài xế (SV3)';
COMMENT ON COLUMN branches.opening_time IS 'Thời điểm mở cửa phục vụ trong ngày (kiểu TIME)';
COMMENT ON COLUMN branches.closing_time IS 'Thời điểm đóng cửa nghỉ trong ngày (kiểu TIME)';

-- ------------------------------------------------------------------------------
-- 3. BẢNG: CATEGORIES (Danh mục món ăn trong thực đơn)
-- Phụ thuộc vào: restaurants(restaurant_id)
-- ------------------------------------------------------------------------------
CREATE TABLE categories (
    category_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    restaurant_id   BIGINT NOT NULL,
    category_name   VARCHAR(100) NOT NULL,
    display_order   INTEGER NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Khóa ngoại tham chiếu nhà hàng
    CONSTRAINT fk_categories_restaurants FOREIGN KEY (restaurant_id)
        REFERENCES restaurants (restaurant_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Không trùng tên danh mục trong cùng 1 nhà hàng
    CONSTRAINT uq_categories_restaurant_name UNIQUE (restaurant_id, category_name),

    -- Thứ tự hiển thị không âm
    CONSTRAINT chk_categories_display_order CHECK (display_order >= 0),
    CONSTRAINT chk_categories_name CHECK (LENGTH(TRIM(category_name)) > 0)
);

COMMENT ON TABLE categories IS 'Phân nhóm thực đơn của từng nhà hàng (Cơm, Đồ uống, Khai vị,...)';
COMMENT ON COLUMN categories.display_order IS 'Thứ tự ưu tiên sắp xếp trên giao diện ứng dụng (>= 0)';

-- ------------------------------------------------------------------------------
-- 4. BẢNG: ITEMS (Món ăn / Đồ uống niêm yết)
-- Phụ thuộc vào: categories(category_id)
-- ------------------------------------------------------------------------------
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

    -- Khóa ngoại tham chiếu danh mục (Chặn xóa danh mục nếu còn món)
    CONSTRAINT fk_items_categories FOREIGN KEY (category_id)
        REFERENCES categories (category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Tên món không trùng lặp trong cùng một danh mục
    CONSTRAINT uq_items_category_name UNIQUE (category_id, item_name),

    -- Ràng buộc giá gốc niêm yết không âm (VNĐ)
    CONSTRAINT chk_items_base_price CHECK (base_price >= 0.00),

    -- Thứ tự hiển thị không âm
    CONSTRAINT chk_items_display_order CHECK (display_order >= 0),
    CONSTRAINT chk_items_name CHECK (LENGTH(TRIM(item_name)) > 0)
);

COMMENT ON TABLE items IS 'Món ăn, đồ uống cụ thể được niêm yết bán trên sàn';
COMMENT ON COLUMN items.base_price IS 'Giá bán niêm yết hiện thời (VNĐ). Đơn hàng sẽ snapshot giá này khi thanh toán [BR02]';
COMMENT ON COLUMN items.is_available IS 'Trạng thái còn món hay tạm hết hàng trong ngày';

-- ------------------------------------------------------------------------------
-- 5. BẢNG: OPTION_GROUPS (Nhóm tùy chọn của món ăn)
-- Phụ thuộc vào: items(item_id)
-- ------------------------------------------------------------------------------
CREATE TABLE option_groups (
    group_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item_id         BIGINT NOT NULL,
    group_name      VARCHAR(100) NOT NULL,
    min_selection   INTEGER NOT NULL DEFAULT 0,
    max_selection   INTEGER NOT NULL DEFAULT 1,
    is_required     BOOLEAN NOT NULL DEFAULT FALSE,
    display_order   INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Khóa ngoại tham chiếu món ăn (Xóa món thì dọn dẹp tùy chọn)
    CONSTRAINT fk_option_groups_items FOREIGN KEY (item_id)
        REFERENCES items (item_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Tên nhóm không trùng trong cùng 1 món
    CONSTRAINT uq_option_groups_item_name UNIQUE (item_id, group_name),

    -- Ràng buộc toàn vẹn số lượng chọn: min >= 0, max >= min, max >= 1
    CONSTRAINT chk_option_groups_bounds CHECK (
        min_selection >= 0 AND 
        max_selection >= min_selection AND 
        max_selection >= 1
    ),

    -- Thứ tự hiển thị không âm
    CONSTRAINT chk_option_groups_display_order CHECK (display_order >= 0),
    CONSTRAINT chk_option_groups_name CHECK (LENGTH(TRIM(group_name)) > 0)
);

COMMENT ON TABLE option_groups IS 'Nhóm tùy chọn kèm theo món (Kích cỡ ly, Mức đá, Lượng đường, Topping)';
COMMENT ON COLUMN option_groups.min_selection IS 'Số lựa chọn tối thiểu bắt buộc khách phải chọn (>= 0)';
COMMENT ON COLUMN option_groups.max_selection IS 'Số lựa chọn tối đa khách được phép tích chọn (>= min_selection)';
COMMENT ON COLUMN option_groups.is_required IS 'Cờ bắt buộc: TRUE nếu min_selection >= 1';

-- ------------------------------------------------------------------------------
-- 6. BẢNG: OPTION_ITEMS (Chi tiết lựa chọn trong nhóm kèm phụ thu)
-- Phụ thuộc vào: option_groups(group_id)
-- ------------------------------------------------------------------------------
CREATE TABLE option_items (
    option_item_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id        BIGINT NOT NULL,
    option_name     VARCHAR(100) NOT NULL,
    extra_price     DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    is_available    BOOLEAN NOT NULL DEFAULT TRUE,
    display_order   INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Khóa ngoại tham chiếu nhóm tùy chọn
    CONSTRAINT fk_option_items_groups FOREIGN KEY (group_id)
        REFERENCES option_groups (group_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Tên lựa chọn không trùng trong cùng một nhóm
    CONSTRAINT uq_option_items_group_name UNIQUE (group_id, option_name),

    -- Ràng buộc đơn giá phụ thu không âm (có thể = 0.00 nếu tùy chọn miễn phí)
    CONSTRAINT chk_option_items_extra_price CHECK (extra_price >= 0.00),

    -- Thứ tự hiển thị không âm
    CONSTRAINT chk_option_items_display_order CHECK (display_order >= 0),
    CONSTRAINT chk_option_items_name CHECK (LENGTH(TRIM(option_name)) > 0)
);

COMMENT ON TABLE option_items IS 'Lựa chọn chi tiết của từng tùy chọn (Size M, Size L, Trân châu đen,...)';
COMMENT ON COLUMN option_items.extra_price IS 'Đơn giá cộng thêm (VNĐ). Sẽ snapshot vào order_item_options khi đặt hàng';

-- ==============================================================================
-- 7. KỊCH BẢN THỬ NGHIỆM TÍNH TOÀN VẸN RÀNG BUỘC (NEGATIVE TEST CASES)
-- Minh họa các trường hợp bị chặn bởi các CHECK / UNIQUE / FK constraints:
-- ==============================================================================

-- [TEST BẪY LỖI 1]: Cố tình thêm món ăn có đơn giá gốc âm (Vi phạm chk_items_base_price)
-- Kỳ vọng: Lỗi violates check constraint "chk_items_base_price"
/*
INSERT INTO items (category_id, item_name, base_price)
VALUES (1, 'Món Lỗi Giá Âm', -25000.00);
*/

-- [TEST BẪY LỖI 2]: Cố tình tạo nhóm tùy chọn có max_selection < min_selection (Vi phạm chk_option_groups_bounds)
-- Kỳ vọng: Lỗi violates check constraint "chk_option_groups_bounds"
/*
INSERT INTO option_groups (item_id, group_name, min_selection, max_selection)
VALUES (1, 'Nhóm Lỗi Cấu Hình', 3, 1);
*/

-- [TEST BẪY LỖI 3]: Cố tình tạo tùy chọn có extra_price âm (Vi phạm chk_option_items_extra_price)
-- Kỳ vọng: Lỗi violates check constraint "chk_option_items_extra_price"
/*
INSERT INTO option_items (group_id, option_name, extra_price)
VALUES (1, 'Topping Giá Âm', -5000.00);
*/

-- [TEST BẪY LỖI 4]: Cố tình chèn tọa độ GPS nằm ngoài bề mặt trái đất (Vi phạm chk_branches_latitude)
-- Kỳ vọng: Lỗi violates check constraint "chk_branches_latitude"
/*
INSERT INTO branches (restaurant_id, branch_name, phone_number, street_address, district, city, latitude, longitude, opening_time, closing_time)
VALUES (1, 'Chi Nhánh Lỗi Tọa Độ', '0909999999', '123 Test', 'Quận 1', 'TP.HCM', 95.50000000, 106.70000000, '08:00', '22:00');
*/
