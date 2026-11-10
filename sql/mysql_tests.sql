USE food_delivery_db;
-- Kiểm tra metadata MySQL/InnoDB.
SELECT VERSION() mysql_version,@@default_storage_engine default_engine;
SELECT COUNT(*) table_count FROM information_schema.tables WHERE table_schema='food_delivery_db' AND engine='InnoDB';
-- Test hợp lệ/không hợp lệ chi tiết được tự động hóa trong app/test/api.test.js.
-- Các lệnh dưới đây phải thất bại nếu bỏ comment:
-- INSERT INTO order_items(order_id,item_id,item_name_snapshot,unit_price_snapshot,quantity,subtotal) VALUES(1,1,'Sai',1,0,0);
-- UPDATE orders SET order_status='DELIVERED' WHERE order_status='PENDING' LIMIT 1;
