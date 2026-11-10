USE food_delivery_db;
-- Chi tiết đơn, tránh nhân tổng do mỗi quan hệ 1-N được truy vấn riêng.
SELECT o.order_code,u.full_name customer,b.branch_name,o.order_status,o.total_amount,p.payment_method,p.payment_status
FROM orders o JOIN users u ON u.user_id=o.customer_id JOIN branches b ON b.branch_id=o.branch_id
LEFT JOIN payments p ON p.order_id=o.order_id AND p.payment_status IN('PENDING','SUCCESS')
WHERE o.order_code='ORD-DEMO-001';
SELECT oi.item_name_snapshot,oi.unit_price_snapshot,oi.quantity,oi.subtotal FROM order_items oi JOIN orders o USING(order_id) WHERE o.order_code='ORD-DEMO-001';
SELECT l.previous_status,l.new_status,l.created_at,l.note FROM order_status_logs l JOIN orders o USING(order_id) WHERE o.order_code='ORD-DEMO-001' ORDER BY l.log_id;
-- Tài xế AVAILABLE gần tọa độ chi nhánh theo Haversine (km; không phải quãng đường bộ).
SELECT d.driver_id,u.full_name,ROUND(6371*2*ASIN(SQRT(POWER(SIN(RADIANS(d.current_lat-10.7742)/2),2)+COS(RADIANS(10.7742))*COS(RADIANS(d.current_lat))*POWER(SIN(RADIANS(d.current_long-106.7030)/2),2))),3) distance_km
FROM drivers d JOIN users u ON u.user_id=d.driver_id WHERE d.driver_status='AVAILABLE' AND d.is_active=TRUE AND d.current_lat IS NOT NULL ORDER BY distance_km LIMIT 5;
