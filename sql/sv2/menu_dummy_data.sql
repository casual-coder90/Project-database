-- ==============================================================================
-- KỊCH BẢN DỮ LIỆU MẪU KIỂM THỬ: PHÂN HỆ NHÀ HÀNG & THỰC ĐƠN (SEED DUMMY DATA)
-- Dự án: Nền tảng tổng hợp giao đồ ăn đa đối tác (DoorDash Model Platform)
-- Phụ trách: SV2 - Phạm Đình Phúc
-- Hệ quản trị CSDL mục tiêu: PostgreSQL 14+ / 15 / 16
-- 
-- Thống kê số lượng bản ghi:
--   - 5 Nhà hàng đối tác (Đạt mục tiêu)
--   - 7 Chi nhánh thực tế tại các quận TP.HCM
--   - 8 Danh mục thực đơn
--   - 22 Món ăn / Đồ uống niêm yết (Vượt mục tiêu 20 món)
--   - 12 Nhóm tùy chọn (Kích cỡ, Mức đường, Đá, Topping, Đồ ăn kèm)
--   - 39 Lựa chọn chi tiết kèm phụ thu (Vượt mục tiêu 30 options)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. DỌN SẠCH DỮ LIỆU THỰC ĐƠN TRƯỚC KHI NẠP MỚI
-- ------------------------------------------------------------------------------
TRUNCATE TABLE option_items, option_groups, items, categories, branches, restaurants RESTART IDENTITY CASCADE;

-- ------------------------------------------------------------------------------
-- 1. NẠP DỮ LIỆU BẢNG: RESTAURANTS (5 Nhà hàng ẩm thực đa dạng)
-- Tham chiếu owner_id = 3 (Chủ nhà hàng Lê Hoàng Nam đã tạo ở users_ddl.sql của SV1)
-- ------------------------------------------------------------------------------
INSERT INTO restaurants (restaurant_id, owner_id, restaurant_name, cuisine_type, description, logo_url, banner_url, is_active)
OVERRIDING SYSTEM VALUE VALUES
    (1, 3, 'Cơm Tấm Sài Gòn Xưa', 'Cơm Tấm & Món Việt', 'Hương vị cơm tấm sườn nướng than hoa gia truyền đậm đà Sài Gòn', 'https://storage.fooddelivery.vn/logos/comtam_logo.png', 'https://storage.fooddelivery.vn/banners/comtam_banner.jpg', TRUE),
    (2, 3, 'Boba House - Trà Sữa Đài Loan', 'Trà Sữa & Đồ Uống', 'Trà sữa đậm vị lá trà tươi nhập khẩu kết hợp topping thủ công', 'https://storage.fooddelivery.vn/logos/bobahouse_logo.png', 'https://storage.fooddelivery.vn/banners/bobahouse_banner.jpg', TRUE),
    (3, 3, 'Phở Bò Gia Truyền 1985', 'Phở & Món Nước', 'Nước dùng hầm từ xương bò nguyên chất 18 tiếng không phụ gia', 'https://storage.fooddelivery.vn/logos/pho1985_logo.png', 'https://storage.fooddelivery.vn/banners/pho1985_banner.jpg', TRUE),
    (4, 3, 'Crispy Chicken & Burger', 'Fast Food & Gà Rán', 'Gà rán sốt cay giòn rụm chuẩn phong cách gà rán đường phố Seoul', 'https://storage.fooddelivery.vn/logos/crispy_logo.png', 'https://storage.fooddelivery.vn/banners/crispy_banner.jpg', TRUE),
    (5, 3, 'Bếp Xanh Chay Healthy', 'Món Chay & Salad', 'Ẩm thực chay thực dưỡng, thanh đạm, rau củ quả hữu cơ organic', 'https://storage.fooddelivery.vn/logos/bepxanh_logo.png', 'https://storage.fooddelivery.vn/banners/bepxanh_banner.jpg', TRUE);

-- ------------------------------------------------------------------------------
-- 2. NẠP DỮ LIỆU BẢNG: BRANCHES (7 Chi nhánh tại TP.HCM)
-- Cung cấp tọa độ WGS-84 phục vụ thuật toán định tuyến GIS Dispatching của SV3
-- Lưu ý: Chi nhánh 5 mở xuyên đêm (18:00 - 02:00 sáng hôm sau) [BR-M01]
-- ------------------------------------------------------------------------------
INSERT INTO branches (branch_id, restaurant_id, branch_name, phone_number, street_address, ward, district, city, latitude, longitude, opening_time, closing_time, is_active)
OVERRIDING SYSTEM VALUE VALUES
    -- Quán 1: Cơm Tấm Sài Gòn Xưa
    (1, 1, 'Chi nhánh Bến Nghé Quận 1', '02838221144', 'Số 45 Nguyễn Huệ', 'Bến Nghé', 'Quận 1', 'TP. Hồ Chí Minh', 10.77420000, 106.70300000, '06:30:00', '22:00:00', TRUE),
    (2, 1, 'Chi nhánh Hàng Xanh Bình Thạnh', '02838992255', 'Số 215 Điện Biên Phủ', 'Phường 15', 'Bình Thạnh', 'TP. Hồ Chí Minh', 10.80150000, 106.71450000, '06:00:00', '23:00:00', TRUE),
    
    -- Quán 2: Boba House
    (3, 2, 'Chi nhánh Sư Vạn Hạnh Quận 10', '02838663366', 'Số 780 Sư Vạn Hạnh', 'Phường 12', 'Quận 10', 'TP. Hồ Chí Minh', 10.77600000, 106.66750000, '08:30:00', '22:30:00', TRUE),
    (4, 2, 'Chi nhánh Thảo Điền Thủ Đức', '02838774488', 'Số 88 Xuân Thủy', 'Thảo Điền', 'Thủ Đức', 'TP. Hồ Chí Minh', 10.80450000, 106.73500000, '09:00:00', '23:00:00', TRUE),
    
    -- Quán 3: Phở Bò Gia Truyền 1985 (Phục vụ xuyên đêm)
    (5, 3, 'Chi nhánh Bàn Cờ Quận 3', '02839335577', 'Số 120 Võ Văn Tần', 'Phường 6', 'Quận 3', 'TP. Hồ Chí Minh', 10.77850000, 106.69120000, '18:00:00', '02:00:00', TRUE),
    
    -- Quán 4: Crispy Chicken
    (6, 4, 'Chi nhánh Phan Xích Long Phú Nhuận', '02839956699', 'Số 150 Phan Xích Long', 'Phường 2', 'Phú Nhuận', 'TP. Hồ Chí Minh', 10.79680000, 106.68850000, '09:30:00', '22:30:00', TRUE),
    
    -- Quán 5: Bếp Xanh Chay Healthy
    (7, 5, 'Chi nhánh Tân Phong Quận 7', '02837718822', 'Số 320 Nguyễn Thị Thập', 'Tân Phong', 'Quận 7', 'TP. Hồ Chí Minh', 10.73800000, 106.70950000, '07:00:00', '21:30:00', TRUE);

-- ------------------------------------------------------------------------------
-- 3. NẠP DỮ LIỆU BẢNG: CATEGORIES (8 Danh mục thực đơn)
-- ------------------------------------------------------------------------------
INSERT INTO categories (category_id, restaurant_id, category_name, display_order, is_active)
OVERRIDING SYSTEM VALUE VALUES
    -- Quán 1
    (1, 1, 'Cơm Tấm Đĩa Truyền Thống', 1, TRUE),
    (2, 1, 'Món Canh & Ăn Kèm', 2, TRUE),
    
    -- Quán 2
    (3, 2, 'Trà Sữa Đậm Vị Truyền Thống', 1, TRUE),
    (4, 2, 'Trà Trái Cây Thanh Nhiệt', 2, TRUE),
    
    -- Quán 3
    (5, 3, 'Phở Bò Gia Truyền Hà Nội', 1, TRUE),
    
    -- Quán 4
    (6, 4, 'Gà Rán Giòn Rụm Cay Ngọt', 1, TRUE),
    (7, 4, 'Burger & Khoai Tây Chiên', 2, TRUE),
    
    -- Quán 5
    (8, 5, 'Salad Rau Củ & Món Chay Dưỡng Sinh', 1, TRUE);

-- ------------------------------------------------------------------------------
-- 4. NẠP DỮ LIỆU BẢNG: ITEMS (22 Món ăn / Đồ uống niêm yết)
-- Giá gốc niêm yết tính bằng VNĐ (base_price >= 0)
-- ------------------------------------------------------------------------------
INSERT INTO items (item_id, category_id, item_name, description, base_price, image_url, is_available, display_order)
OVERRIDING SYSTEM VALUE VALUES
    -- Cơm Tấm Sài Gòn Xưa (Món 1 -> 5)
    (1, 1, 'Cơm Sườn Nướng Mật Ong', 'Cơm tấm sườn cốt lết ướp mật ong rừng nướng than hoa thơm lừng', 45000.00, 'https://storage.fooddelivery.vn/items/com_suon.jpg', TRUE, 1),
    (2, 1, 'Cơm Sườn Bì Chả Đặc Biệt', 'Sườn cọng nướng kèm bì thính vàng giòn và chả trứng hấp thơm ngậy', 65000.00, 'https://storage.fooddelivery.vn/items/com_suon_bi_cha.jpg', TRUE, 2),
    (3, 1, 'Cơm Đùi Gà Nướng Tiêu', 'Đùi gà góc tư nướng sốt tiêu đen đậm vị ăn kèm đồ chua giòn ngọt', 50000.00, 'https://storage.fooddelivery.vn/items/com_ga.jpg', TRUE, 3),
    (4, 2, 'Canh Khổ Qua Nhồi Thịt', 'Khổ qua đắng thanh nhồi thịt heo băm mộc nhĩ thanh nhiệt', 25000.00, 'https://storage.fooddelivery.vn/items/canh_kho_qua.jpg', TRUE, 1),
    (5, 2, 'Canh Rong Biển Thịt Bằm', 'Rong biển thanh mát nấu thịt nạc bằm và đậu hũ non', 20000.00, 'https://storage.fooddelivery.vn/items/canh_rong_bien.jpg', TRUE, 2),

    -- Boba House (Món 6 -> 10)
    (6, 3, 'Trà Sữa Trân Châu Đường Đen', 'Trà đen Ceylon hảo hạng hòa quyện sữa tươi thanh trùng và trân châu đường đen', 42000.00, 'https://storage.fooddelivery.vn/items/ts_duong_den.jpg', TRUE, 1),
    (7, 3, 'Trà Sữa Oolong Nướng', 'Vị trà Oolong sấy than nướng đặc trưng hương khói béo ngậy', 45000.00, 'https://storage.fooddelivery.vn/items/ts_oolong.jpg', TRUE, 2),
    (8, 3, 'Trà Sữa Matcha Nhật Bản', 'Bột matcha Uji chuẩn Nhật kết hợp sữa béo ngậy', 48000.00, 'https://storage.fooddelivery.vn/items/ts_matcha.jpg', TRUE, 3),
    (9, 4, 'Trà Đào Cam Sả Hoàng Kim', 'Trà đen thanh mát ủ cùng cam tươi, sả đập dập và đào miếng ngâm giòn', 39000.00, 'https://storage.fooddelivery.vn/items/tra_dao.jpg', TRUE, 1),
    (10, 4, 'Trà Ổi Hồng Hạt Chia', 'Nước ép ổi hồng thanh ngọt kết hợp hạt chia organic bổ dưỡng', 42000.00, 'https://storage.fooddelivery.vn/items/tra_oi_hong.jpg', TRUE, 2),

    -- Phở Bò Gia Truyền 1985 (Món 11 -> 14)
    (11, 5, 'Phở Tái Lăn Hà Nội', 'Thịt bò tươi xào tái lăn tỏi lửa lớn dậy mùi thơm nức', 55000.00, 'https://storage.fooddelivery.vn/items/pho_tai_lan.jpg', TRUE, 1),
    (12, 5, 'Phở Nạm Gầu Giòn', 'Thịt nạm mềm thơm và gầu bò giòn sần sật béo ngậy', 60000.00, 'https://storage.fooddelivery.vn/items/pho_nam_gau.jpg', TRUE, 2),
    (13, 5, 'Phở Đặc Biệt Thập Cẩm', 'Tô đầy đủ tái, nạm, gầu, gân và bò viên khổng lồ nước dùng thanh ngọt', 75000.00, 'https://storage.fooddelivery.vn/items/pho_dac_biet.jpg', TRUE, 3),
    (14, 5, 'Bò Kho Bánh Mì Nóng', 'Bò kho hầm cà rốt sả quế ăn kèm bánh mì nướng giòn', 55000.00, 'https://storage.fooddelivery.vn/items/bo_kho.jpg', TRUE, 4),

    -- Crispy Chicken & Burger (Món 15 -> 18)
    (15, 6, 'Gà Rán Sốt Cay Ngọt Seoul (2 Miếng)', '2 miếng đùi và má đùi gà chiên giòn rụm áo đẫm sốt cay ngọt Hàn Quốc', 69000.00, 'https://storage.fooddelivery.vn/items/ga_cay_ngot.jpg', TRUE, 1),
    (16, 6, 'Gà Rán Truyền Thống Giòn Da (3 Miếng)', '3 miếng gà tẩm bột chiên nguyên bản thơm nức giòn rụm', 89000.00, 'https://storage.fooddelivery.vn/items/ga_truyen_thong.jpg', TRUE, 2),
    (17, 7, 'Burger Bò Phô Mai Tan Chảy', 'Thịt bò Úc xay nướng than kèm sốt burger đặc biệt và phô mai Cheddar', 59000.00, 'https://storage.fooddelivery.vn/items/burger_bo.jpg', TRUE, 1),
    (18, 7, 'Khoai Tây Lắc Phô Mai Giòn', 'Khoai tây cọng Bỉ chiên vàng lắc bột phô mai béo mặn', 35000.00, 'https://storage.fooddelivery.vn/items/khoai_tay.jpg', TRUE, 2),

    -- Bếp Xanh Chay Healthy (Món 19 -> 22)
    (19, 8, 'Salad Ức Gà Áp Chảo Mè Rang', 'Ức gà tẩm ướp áp chảo mềm mọng kèm xà lách Romaine, cà chua bi, sốt mè', 55000.00, 'https://storage.fooddelivery.vn/items/salad_uc_ga.jpg', TRUE, 1),
    (20, 8, 'Cơm Gạo Lứt Xào Nấm Đông Cô', 'Gạo lứt đỏ dẻo thơm xào nấm tươi, bắp ngọt và đậu hà lan', 49000.00, 'https://storage.fooddelivery.vn/items/com_gao_lut.jpg', TRUE, 2),
    (21, 8, 'Bún Thái Chay Chua Cay', 'Nước dùng chua cay sả riềng ăn kèm chả nấm, đậu hũ chiên và rau muống', 45000.00, 'https://storage.fooddelivery.vn/items/bun_thai_chay.jpg', TRUE, 3),
    (22, 8, 'Gỏi Cuốn Ngũ Sắc Chay (4 Cuộn)', 'Rau thơm, bún, đậu hũ chiên và nấm đùi gà cuốn bánh tráng chấm tương đậu', 38000.00, 'https://storage.fooddelivery.vn/items/goi_cuon_chay.jpg', TRUE, 4);

-- ------------------------------------------------------------------------------
-- 5. NẠP DỮ LIỆU BẢNG: OPTION_GROUPS (12 Nhóm tùy chọn)
-- Cài đặt min_selection và max_selection hợp lệ bảo đảm chk_option_groups_bounds
-- ------------------------------------------------------------------------------
INSERT INTO option_groups (group_id, item_id, group_name, min_selection, max_selection, is_required, display_order)
OVERRIDING SYSTEM VALUE VALUES
    -- Nhóm cho Cơm Sườn (Item 1 & 2)
    (1, 1, 'Lựa Chọn Khẩu Phần Cơm', 1, 1, TRUE, 1),
    (2, 2, 'Món Gọi Thêm Đậm Đà', 0, 4, FALSE, 2),
    
    -- Nhóm cho Trà Sữa Đường Đen (Item 6)
    (3, 6, 'Chọn Kích Cỡ Ly', 1, 1, TRUE, 1),
    (4, 6, 'Chọn Mức Đường', 1, 1, TRUE, 2),
    (5, 6, 'Chọn Mức Đá', 1, 1, TRUE, 3),
    (6, 6, 'Topping Thêm Đỉnh Cao', 0, 4, FALSE, 4),
    
    -- Nhóm cho Trà Đào Cam Sả (Item 9)
    (7, 9, 'Kích Thước Ly Nước', 1, 1, TRUE, 1),
    (8, 9, 'Topping Giải Nhiệt', 0, 2, FALSE, 2),
    
    -- Nhóm cho Phở Tái Lăn (Item 11)
    (9, 11, 'Món Kèm Chuẩn Vị Bắc', 0, 3, FALSE, 1),
    
    -- Nhóm cho Gà Rán Sốt Cay Ngọt (Item 15)
    (10, 15, 'Mức Độ Cay Sốt', 1, 1, TRUE, 1),
    (11, 15, 'Sốt Chấm Thêm Đặc Biệt', 0, 2, FALSE, 2),
    
    -- Nhóm cho Salad Ức Gà (Item 19)
    (12, 19, 'Loại Sốt Trộn Salad', 1, 1, TRUE, 1);

-- ------------------------------------------------------------------------------
-- 6. NẠP DỮ LIỆU BẢNG: OPTION_ITEMS (39 Lựa chọn chi tiết kèm phụ thu)
-- Giá phụ thu (extra_price >= 0.00), có tùy chọn phụ thu 0đ và tùy chọn phụ thu dương
-- ------------------------------------------------------------------------------
INSERT INTO option_items (option_item_id, group_id, option_name, extra_price, is_available, display_order)
OVERRIDING SYSTEM VALUE VALUES
    -- Group 1: Khẩu phần cơm (Món 1)
    (1, 1, 'Cơm phần bình thường', 0.00, TRUE, 1),
    (2, 1, 'Thêm 1 chén cơm thêm', 8000.00, TRUE, 2),
    (3, 1, 'Phần cơm ít (giảm tinh bột)', 0.00, TRUE, 3),

    -- Group 2: Món thêm cơm tấm (Món 2)
    (4, 2, 'Trứng ốp la lòng đào', 10000.00, TRUE, 1),
    (5, 2, 'Chả trứng chưng thịt nấm', 12000.00, TRUE, 2),
    (6, 2, 'Tóp mỡ mỡ hành béo ngậy', 5000.00, TRUE, 3),
    (7, 2, 'Bì heo trộn thính thơm', 10000.00, TRUE, 4),

    -- Group 3: Size ly trà sữa (Món 6)
    (8, 3, 'Size M (Tiêu chuẩn 500ml)', 0.00, TRUE, 1),
    (9, 3, 'Size L (Cỡ lớn 700ml)', 10000.00, TRUE, 2),

    -- Group 4: Mức đường (Món 6)
    (10, 4, '100% Đường (Chuẩn vị ngọt)', 0.00, TRUE, 1),
    (11, 4, '70% Đường (Ít ngọt nhẹ)', 0.00, TRUE, 2),
    (12, 4, '50% Đường (Nửa ngọt thanh)', 0.00, TRUE, 3),
    (13, 4, '30% Đường (Rất ít ngọt)', 0.00, TRUE, 4),
    (14, 4, '0% Đường (Không ngọt)', 0.00, TRUE, 5),

    -- Group 5: Mức đá (Món 6)
    (15, 5, '100% Đá (Mát lạnh sâu)', 0.00, TRUE, 1),
    (16, 5, '50% Đá (Mát vừa)', 0.00, TRUE, 2),
    (17, 5, 'Không lấy đá (Uống liền)', 0.00, TRUE, 3),

    -- Group 6: Topping trà sữa (Món 6)
    (18, 6, 'Trân châu đen dẻo dai', 8000.00, TRUE, 1),
    (19, 6, 'Trân châu trắng 3Q giòn', 10000.00, TRUE, 2),
    (20, 6, 'Pudding trứng béo mềm', 10000.00, TRUE, 3),
    (21, 6, 'Kem Cheese Macchiato béo ngậy', 12000.00, TRUE, 4),
    (22, 6, 'Thạch dừa sần sật', 8000.00, TRUE, 5),

    -- Group 7: Size ly trà đào (Món 9)
    (23, 7, 'Size M (Tiêu chuẩn 500ml)', 0.00, TRUE, 1),
    (24, 7, 'Size L (Cỡ lớn 700ml)', 8000.00, TRUE, 2),

    -- Group 8: Topping trà đào (Món 9)
    (25, 8, 'Thêm 2 miếng đào ngâm giòn', 10000.00, TRUE, 1),
    (26, 8, 'Thạch nha đam thanh mát', 8000.00, TRUE, 2),

    -- Group 9: Đồ kèm phở (Món 11)
    (27, 9, 'Quẩy giòn giòn Hà Nội (3 cái)', 10000.00, TRUE, 1),
    (28, 9, 'Trứng gà ta chần nước lèo', 8000.00, TRUE, 2),
    (29, 9, 'Thịt bò tái chần thêm', 22000.00, TRUE, 3),
    (30, 9, 'Tiết luộc mềm ngậy', 8000.00, TRUE, 4),

    -- Group 10: Mức độ cay gà rán (Món 15)
    (31, 10, 'Cay vừa (Chuẩn vị Hàn Quốc)', 0.00, TRUE, 1),
    (32, 10, 'Cay nhiều xé lưỡi', 0.00, TRUE, 2),
    (33, 10, 'Không cay (Sốt ngọt tỏi)', 0.00, TRUE, 3),

    -- Group 11: Sốt chấm gà rán (Món 15)
    (34, 11, 'Sốt mù tạt mật ong Honey Mustard', 8000.00, TRUE, 1),
    (35, 11, 'Sốt phô mai tan chảy béo mặn', 10000.00, TRUE, 2),

    -- Group 12: Sốt trộn Salad (Món 19)
    (36, 12, 'Sốt mè rang Kewpie Nhật Bản', 0.00, TRUE, 1),
    (37, 12, 'Sốt chanh dây chua ngọt tươi mát', 0.00, TRUE, 2),
    (38, 12, 'Sốt giấm Ý Balsamic nguyên chất', 5000.00, TRUE, 3),
    (39, 12, 'Sốt sữa chua Hy Lạp thảo mộc', 5000.00, TRUE, 4);

-- ------------------------------------------------------------------------------
-- 7. CẬP NHẬT SEQUENCE ĐỂ IDENTITY TỰ TĂNG CHÍNH XÁC KHI INSERT TIẾP
-- ------------------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('restaurants', 'restaurant_id'), (SELECT MAX(restaurant_id) FROM restaurants));
SELECT setval(pg_get_serial_sequence('branches', 'branch_id'), (SELECT MAX(branch_id) FROM branches));
SELECT setval(pg_get_serial_sequence('categories', 'category_id'), (SELECT MAX(category_id) FROM categories));
SELECT setval(pg_get_serial_sequence('items', 'item_id'), (SELECT MAX(item_id) FROM items));
SELECT setval(pg_get_serial_sequence('option_groups', 'group_id'), (SELECT MAX(group_id) FROM option_groups));
SELECT setval(pg_get_serial_sequence('option_items', 'option_item_id'), (SELECT MAX(option_item_id) FROM option_items));

-- ==============================================================================
-- 8. TRUY VẤN KIỂM CHỨNG DỮ LIỆU & TOÀN VẸN THỰC ĐƠN
-- ==============================================================================

-- 8.1. Thống kê tổng số lượng bản ghi của 6 bảng
SELECT 'restaurants' AS table_name, COUNT(*) AS total_records FROM restaurants
UNION ALL
SELECT 'branches', COUNT(*) FROM branches
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'items', COUNT(*) FROM items
UNION ALL
SELECT 'option_groups', COUNT(*) FROM option_groups
UNION ALL
SELECT 'option_items', COUNT(*) FROM option_items;

-- 8.2. Truy vấn liên kết toàn diện cây thực đơn: Quán -> Danh mục -> Món -> Tùy chọn -> Giá
SELECT 
    r.restaurant_name,
    c.category_name,
    i.item_name,
    i.base_price,
    og.group_name,
    og.min_selection,
    og.max_selection,
    oi.option_name,
    oi.extra_price
FROM restaurants r
JOIN categories c ON r.restaurant_id = c.restaurant_id
JOIN items i ON c.category_id = i.category_id
LEFT JOIN option_groups og ON i.item_id = og.item_id
LEFT JOIN option_items oi ON og.group_id = oi.group_id
ORDER BY r.restaurant_id, c.category_id, i.item_id, og.group_id, oi.option_item_id;
