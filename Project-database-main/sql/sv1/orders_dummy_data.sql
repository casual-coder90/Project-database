-- ==============================================================================
-- KỊCH BẢN NẠP DỮ LIỆU MẪU: PHÂN HỆ ĐƠN HÀNG (SEED DUMMY DATA FOR ORDERS)
-- Dự án: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
-- Phụ trách: SV1 - Nhóm trưởng (Bùi Duy Quang)
-- Hệ quản trị CSDL mục tiêu: PostgreSQL 14+ / 15 / 16
-- 
-- Dữ liệu liên kết chặt chẽ với:
--   - Khách hàng & Sổ địa chỉ (users_ddl.sql của SV1)
--   - Quán ăn, Chi nhánh, Món ăn, Topping (menu_ddl.sql & menu_dummy_data.sql của SV2)
-- ==============================================================================

TRUNCATE TABLE order_item_options, order_items, orders RESTART IDENTITY CASCADE;

-- ------------------------------------------------------------------------------
-- 1. NẠP DỮ LIỆU BẢNG: ORDERS (5 Đơn hàng đa dạng trạng thái và khách hàng)
-- ------------------------------------------------------------------------------
INSERT INTO orders (
    order_id, order_code, customer_id, branch_id, driver_id, delivery_address_id,
    order_status, payment_status,
    subtotal_amount, delivery_fee, service_fee, discount_amount, total_amount,
    delivery_distance_km, driver_rating, restaurant_rating, customer_note, created_at
)
OVERRIDING SYSTEM VALUE VALUES
    -- Đơn 1: Khách 1 (Nguyễn Văn An) đặt Cơm Tấm Sài Gòn Xưa (Chi nhánh Bến Nghé Q1) -> Đã giao thành công
    (1, 'ORD-20261026-0001', 1, 1, 4, 1,
     'DELIVERED', 'PAID',
     125000.00, 15000.00, 3000.00, 10000.00, 133000.00,
     1.8, 5, 5, 'Giao lên tầng 3 bấm chuông giúp em, đừng bấm còi', CURRENT_TIMESTAMP - INTERVAL '2 days'),

    -- Đơn 2: Khách 1 (Nguyễn Văn An) đặt Trà Sữa Boba House (Chi nhánh Sư Vạn Hạnh Q10) về Công ty -> Đã giao
    (2, 'ORD-20261026-0002', 1, 3, 4, 2,
     'DELIVERED', 'PAID',
     105000.00, 22000.00, 4000.00, 0.00, 131000.00,
     4.2, 4, 5, 'Gọi trước khi đến 5 phút để xuống sảnh lấy', CURRENT_TIMESTAMP - INTERVAL '1 day'),

    -- Đơn 3: Khách 2 (Trần Thị Bích) đặt Phở Bò 1985 (Chi nhánh Bàn Cờ Q3) về Thảo Điền -> Đang giao đường dài
    (3, 'ORD-20261026-0003', 2, 5, 4, 3,
     'PICKED_UP', 'PAID',
     155000.00, 35000.00, 5000.00, 20000.00, 175000.00,
     7.5, NULL, NULL, 'Xin thêm nhiều ớt sa tế và chanh tươi', CURRENT_TIMESTAMP - INTERVAL '30 minutes'),

    -- Đơn 4: Khách 2 (Trần Thị Bích) đặt Gà Rán Crispy Chicken (Chi nhánh Phan Xích Long) -> Quán đang làm
    (4, 'ORD-20261026-0004', 2, 6, NULL, 3,
     'PREPARING', 'PAID',
     199000.00, 28000.00, 4000.00, 15000.00, 216000.00,
     5.6, NULL, NULL, 'Gà rán để tương ớt và tương cà riêng giùm', CURRENT_TIMESTAMP - INTERVAL '10 minutes'),

    -- Đơn 5: Khách 1 đặt Cơm Tấm Sài Gòn Xưa -> Khách đổi ý hủy đơn
    (5, 'ORD-20261026-0005', 1, 1, NULL, 1,
     'CANCELLED', 'REFUNDED',
     65000.00, 15000.00, 2000.00, 0.00, 82000.00,
     1.8, NULL, NULL, 'Đặt nhầm địa chỉ, hủy đặt lại', CURRENT_TIMESTAMP - INTERVAL '3 hours');

-- ------------------------------------------------------------------------------
-- 2. NẠP DỮ LIỆU BẢNG: ORDER_ITEMS (Chi tiết món ăn trong các đơn hàng)
-- Lưu ý: unit_price_snapshot ghi lại đúng giá món tại thời điểm đặt [BR02]
-- ------------------------------------------------------------------------------
INSERT INTO order_items (
    order_item_id, order_id, item_id,
    item_name_snapshot, unit_price_snapshot, quantity, subtotal, item_note
)
OVERRIDING SYSTEM VALUE VALUES
    -- Đơn 1: Cơm sườn bì chả đặc biệt (x1) + Canh khổ qua (x1)
    (1, 1, 1, 'Cơm Tấm Sườn Bì Chả Đặc Biệt', 65000.00, 1, 65000.00, 'Nhiều mỡ hành, tóp mỡ giòn'),
    (2, 1, 4, 'Canh Khổ Qua Nhồi Thịt', 25000.00, 1, 25000.00, 'Nước canh nóng hổi'),
    -- Kèm theo 1 đĩa Cơm sườn non nướng mật ong (x1)
    (3, 1, 2, 'Cơm Tấm Sườn Non Nướng Mật Ong', 55000.00, 1, 55000.00, 'Ít cơm, nhiều dưa chua'),

    -- Đơn 2: 2 ly Trà Sữa Trân Châu Hoàng Kim
    (4, 2, 5, 'Trà Sữa Trân Châu Hoàng Kim', 45000.00, 2, 9000.00, '1 ly 70% đường, 1 ly 50% đường'),

    -- Đơn 3: Phở Bò Tái Nạm Gầu (x2)
    (5, 3, 9, 'Phở Bò Tái Nạm Gầu Đặc Biệt', 75000.00, 2, 150000.00, 'Bánh phở mềm, hành trần'),

    -- Đơn 4: Combo Gà Rán Gia Đình (x1)
    (6, 4, 13, 'Combo Gà Rán Giòn Gia Đình', 189000.00, 1, 189000.00, 'Sốt cay ngọt Hàn Quốc');

-- ------------------------------------------------------------------------------
-- 3. NẠP DỮ LIỆU BẢNG: ORDER_ITEM_OPTIONS (Topping / Tùy chọn kèm theo món)
-- Lưu ý: extra_price_snapshot ghi nhận mức phụ thu lịch sử [BR02]
-- ------------------------------------------------------------------------------
INSERT INTO order_item_options (
    order_item_option_id, order_item_id, option_item_id,
    option_name_snapshot, extra_price_snapshot
)
OVERRIDING SYSTEM VALUE VALUES
    -- Topping cho Món 1 (Cơm tấm sườn bì chả của Đơn 1): Thêm trứng ốp la + Chả trứng thêm
    (1, 1, 1, 'Trứng Ốp La Lòng Đào', 10000.00),
    (2, 1, 2, 'Chả Trứng Hấp Thêm', 12000.00),

    -- Topping cho Món 2 (Cơm tấm sườn non của Đơn 1): Thêm canh rong biển
    (3, 3, 4, 'Canh Rong Biển Thịt Bằm', 15000.00),

    -- Topping cho Ly trà sữa 1 (Đơn 2): Size L + Thêm Trân Châu Đen + 70% Đường + Ít Đá
    (4, 4, 6, 'Size L (Khổng lồ 700ml)', 10000.00),
    (5, 4, 15, 'Trân Châu Đen Dẻo', 8000.00),
    (6, 4, 16, 'Pudding Trứng Mềm', 10000.00),

    -- Topping cho Tô Phở (Đơn 3): Trứng chần nước béo + Quẩy giòn
    (7, 5, 20, 'Trứng Gà Chần Nước Béo', 10000.00),
    (8, 5, 21, 'Quẩy Giòn Hà Nội (2 chiếc)', 8000.00);
