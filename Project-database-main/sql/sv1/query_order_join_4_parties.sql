-- ==============================================================================
-- TRUY VẤN TRỌNG TÂM: JOIN 4 BÊN CHI TIẾT ĐƠN HÀNG (4-WAY JOIN ORDER DETAILS)
-- Dự án: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
-- Phụ trách: SV1 - Nhóm trưởng (Bùi Duy Quang)
-- Mã công việc trong WBS: SV1-04
-- Hệ quản trị CSDL mục tiêu: PostgreSQL 14+ / 15 / 16
--
-- Mục tiêu nghiệp vụ:
--   - Kết nối 4 chủ thể cốt lõi trên sàn giao dịch:
--       1. KHÁCH HÀNG (USERS & CUSTOMERS & SỔ ĐỊA CHỈ NHẬN HÀNG)
--       2. ĐƠN HÀNG TRUNG TÂM (ORDERS)
--       3. ĐỐI TÁC NHÀ HÀNG & CHI NHÁNH (RESTAURANTS & BRANCHES)
--       4. CHI TIẾT MÓN ĂN & TOPPING KÈM THEO (ORDER_ITEMS & ORDER_ITEM_OPTIONS)
--   - Giải quyết bài toán: Một đơn hàng có thể có nhiều món, và mỗi món có thể có nhiều
--     topping/option tùy chọn. 
--   - Cung cấp 2 phiên bản truy vấn:
--       + Phiên bản 1: Dạng phẳng (Tabular Flat Rows) dùng cho báo cáo trích xuất ETL.
--       + Phiên bản 2: Dạng tổng hợp JSON/Array Aggregation (chuẩn hóa API cho Frontend).
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- PHIÊN BẢN 1: TRUY VẤN JOIN 4 BÊN DẠNG BẢNG PHẲNG (TABULAR REPORT)
-- Kết nối tuần tự các bảng:
--   orders (o)
--   -> users (u) & customer_addresses (ca)
--   -> branches (b) & restaurants (r)
--   -> order_items (oi)
--   -> order_item_options (oio)
-- ------------------------------------------------------------------------------
SELECT 
    -- 1. Thông tin định danh đơn hàng
    o.order_id,
    o.order_code,
    o.order_status,
    o.payment_status,
    TO_CHAR(o.created_at, 'DD/MM/YYYY HH24:MI:SS') AS order_time,

    -- 2. Thông tin khách hàng & Địa chỉ giao hàng
    u.full_name AS customer_name,
    u.phone_number AS customer_phone,
    ca.recipient_name,
    ca.recipient_phone,
    ca.street_address || ', ' || ca.district || ', ' || ca.city AS delivery_full_address,

    -- 3. Thông tin Nhà hàng & Chi nhánh phục vụ
    r.restaurant_name,
    r.cuisine_type,
    b.branch_name,
    b.street_address || ', ' || b.district AS branch_location,
    b.phone_number AS branch_phone,

    -- 4. Chi tiết món ăn đặt (Lấy từ snapshot lịch sử)
    oi.order_item_id,
    oi.item_name_snapshot AS ordered_item_name,
    oi.unit_price_snapshot AS item_unit_price,
    oi.quantity AS item_quantity,
    oi.subtotal AS item_subtotal,
    oi.item_note,

    -- 5. Chi tiết Topping / Tùy chọn kèm theo món (Nếu có)
    COALESCE(oio.option_name_snapshot, 'Không có topping') AS topping_name,
    COALESCE(oio.extra_price_snapshot, 0.00) AS topping_extra_price,

    -- 6. Tổng kết tài chính đơn hàng
    o.subtotal_amount,
    o.delivery_fee,
    o.service_fee,
    o.discount_amount,
    o.total_amount AS final_order_total

FROM orders o
-- Phía Khách hàng (SV1)
JOIN customers c ON o.customer_id = c.customer_id
JOIN users u ON c.customer_id = u.user_id
JOIN customer_addresses ca ON o.delivery_address_id = ca.address_id

-- Phía Nhà hàng & Chi nhánh (SV2)
JOIN branches b ON o.branch_id = b.branch_id
JOIN restaurants r ON b.restaurant_id = r.restaurant_id

-- Phía Chi tiết món ăn & Topping (SV1 liên kết SV2)
JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_item_options oio ON oi.order_item_id = oio.order_item_id

ORDER BY 
    o.order_id DESC, 
    oi.order_item_id ASC, 
    oio.order_item_option_id ASC;


-- ------------------------------------------------------------------------------
-- PHIÊN BẢN 2: TRUY VẤN JOIN 4 BÊN GỘP JSON (AGGREGATED ORDER SUMMARY)
-- Gom nhóm mỗi đơn hàng thành 1 dòng duy nhất, danh sách món và topping được
-- cấu trúc thành mảng JSON lồng nhau (Nested JSON Array), không bị trùng lặp dòng.
-- Rất thích hợp để cấp dữ liệu trực tiếp cho App Mobile / Web Admin Dashboard.
-- ------------------------------------------------------------------------------
WITH item_with_options AS (
    SELECT 
        oi.order_id,
        oi.order_item_id,
        oi.item_name_snapshot,
        oi.unit_price_snapshot,
        oi.quantity,
        oi.subtotal,
        oi.item_note,
        COALESCE(
            JSON_AGG(
                JSON_BUILD_OBJECT(
                    'topping_name', oio.option_name_snapshot,
                    'extra_price', oio.extra_price_snapshot
                )
            ) FILTER (WHERE oio.order_item_option_id IS NOT NULL),
            '[]'::json
        ) AS options_list
    FROM order_items oi
    LEFT JOIN order_item_options oio ON oi.order_item_id = oio.order_item_id
    GROUP BY 
        oi.order_id, oi.order_item_id, oi.item_name_snapshot, 
        oi.unit_price_snapshot, oi.quantity, oi.subtotal, oi.item_note
),
order_aggregated_items AS (
    SELECT 
        iwo.order_id,
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'item_name', iwo.item_name_snapshot,
                'unit_price', iwo.unit_price_snapshot,
                'quantity', iwo.quantity,
                'subtotal', iwo.subtotal,
                'note', iwo.item_note,
                'toppings', iwo.options_list
            )
        ) AS items_in_order
    FROM item_with_options iwo
    GROUP BY iwo.order_id
)
SELECT 
    o.order_id,
    o.order_code,
    o.order_status,
    o.payment_status,
    o.total_amount,
    
    -- Thông tin người đặt
    JSON_BUILD_OBJECT(
        'customer_name', u.full_name,
        'customer_phone', u.phone_number,
        'recipient_name', ca.recipient_name,
        'recipient_phone', ca.recipient_phone,
        'delivery_address', ca.street_address || ', ' || ca.district || ', ' || ca.city
    ) AS customer_info,

    -- Thông tin quán phục vụ
    JSON_BUILD_OBJECT(
        'restaurant_name', r.restaurant_name,
        'branch_name', b.branch_name,
        'branch_address', b.street_address || ', ' || b.district,
        'branch_phone', b.phone_number
    ) AS restaurant_info,

    -- Danh sách toàn bộ món & Topping
    oai.items_in_order

FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN users u ON c.customer_id = u.user_id
JOIN customer_addresses ca ON o.delivery_address_id = ca.address_id
JOIN branches b ON o.branch_id = b.branch_id
JOIN restaurants r ON b.restaurant_id = r.restaurant_id
JOIN order_aggregated_items oai ON o.order_id = oai.order_id
ORDER BY o.order_id DESC;
