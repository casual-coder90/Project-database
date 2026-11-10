-- MySQL 8.4 / InnoDB. Seed idempotent: chạy lại không tạo bản ghi trùng.
USE food_delivery_db;
START TRANSACTION;
INSERT INTO users(user_id,email,phone_number,password_hash,full_name,user_type,status) VALUES
 (1,'an.nguyen@gmail.com','0901234567','$demo-not-for-login','Nguyễn Văn An','CUSTOMER','ACTIVE'),
 (2,'bich.tran@gmail.com','0912345678','$demo-not-for-login','Trần Thị Bích','CUSTOMER','ACTIVE'),
 (3,'nam.le@gmail.com','0988889999','$demo-not-for-login','Lê Hoàng Nam','MERCHANT_OWNER','ACTIVE'),
 (4,'hung.vo@gmail.com','0933445566','$demo-not-for-login','Võ Quốc Hưng','DRIVER','ACTIVE'),
 (5,'hai.nguyen@gmail.com','0931111101','$demo-not-for-login','Nguyễn Văn Hải','DRIVER','ACTIVE'),
 (6,'tuan.tran@gmail.com','0931111102','$demo-not-for-login','Trần Minh Tuấn','DRIVER','ACTIVE')
ON DUPLICATE KEY UPDATE full_name=VALUES(full_name),status='ACTIVE';
INSERT INTO customers(customer_id,loyalty_points,birth_date) VALUES(1,150,'1998-05-12'),(2,50,'2001-11-20')
ON DUPLICATE KEY UPDATE loyalty_points=VALUES(loyalty_points);
INSERT INTO customer_addresses(address_id,customer_id,recipient_name,recipient_phone,street_address,ward,district,city,latitude,longitude,address_label,is_default) VALUES
 (1,1,'Nguyễn Văn An','0901234567','123 Nguyễn Huệ','Bến Nghé','Quận 1','TP.HCM',10.7745,106.7032,'Nhà',TRUE),
 (2,2,'Trần Thị Bích','0912345678','Masteri Thảo Điền','Thảo Điền','Thủ Đức','TP.HCM',10.8038,106.7410,'Căn hộ',TRUE)
ON DUPLICATE KEY UPDATE recipient_name=VALUES(recipient_name);
INSERT INTO merchant_owners(merchant_owner_id,tax_code,identity_card_number,kyc_status,verified_at)
VALUES(3,'0315894123','079098001234','VERIFIED',CURRENT_TIMESTAMP(6)) ON DUPLICATE KEY UPDATE kyc_status='VERIFIED';
INSERT INTO restaurants(restaurant_id,owner_id,restaurant_name,cuisine_type,description,is_active) VALUES
 (1,3,'Cơm Tấm Sài Gòn Xưa','Món Việt','Cơm tấm truyền thống',TRUE),(2,3,'Boba House','Đồ uống','Trà sữa',TRUE)
ON DUPLICATE KEY UPDATE restaurant_name=VALUES(restaurant_name),is_active=TRUE;
INSERT INTO branches(branch_id,restaurant_id,branch_name,phone_number,street_address,ward,district,city,latitude,longitude,opening_time,closing_time,is_active) VALUES
 (1,1,'Chi nhánh Bến Nghé Quận 1','02838221144','45 Nguyễn Huệ','Bến Nghé','Quận 1','TP.HCM',10.7742,106.7030,'06:30','22:00',TRUE),
 (2,2,'Chi nhánh Sư Vạn Hạnh Quận 10','02838663366','780 Sư Vạn Hạnh','Phường 12','Quận 10','TP.HCM',10.7760,106.6675,'08:30','22:30',TRUE)
ON DUPLICATE KEY UPDATE branch_name=VALUES(branch_name),is_active=TRUE;
INSERT INTO categories(category_id,restaurant_id,category_name,display_order,is_active) VALUES
 (1,1,'Cơm tấm',1,TRUE),(2,2,'Trà sữa',1,TRUE)
ON DUPLICATE KEY UPDATE category_name=VALUES(category_name),is_active=TRUE;
INSERT INTO items(item_id,category_id,item_name,description,base_price,is_available) VALUES
 (1,1,'Cơm Sườn Bì Chả Đặc Biệt','Món demo',65000,TRUE),(2,2,'Trà Sữa Trân Châu Đường Đen','Món demo',42000,TRUE)
ON DUPLICATE KEY UPDATE item_name=VALUES(item_name),base_price=VALUES(base_price),is_available=TRUE;
INSERT INTO option_groups(group_id,item_id,group_name,min_selection,max_selection,is_required) VALUES
 (1,1,'Món gọi thêm',0,3,FALSE),(2,2,'Kích cỡ',1,1,TRUE)
ON DUPLICATE KEY UPDATE group_name=VALUES(group_name);
INSERT INTO option_items(option_item_id,group_id,option_name,extra_price,is_available) VALUES
 (1,1,'Trứng ốp la',10000,TRUE),(2,1,'Tóp mỡ',5000,TRUE),(3,2,'Size M',0,TRUE),(4,2,'Size L',10000,TRUE)
ON DUPLICATE KEY UPDATE option_name=VALUES(option_name),extra_price=VALUES(extra_price),is_available=TRUE;
INSERT INTO drivers(driver_id,license_number,vehicle_type,vehicle_plate,current_lat,current_long,driver_status,is_active,rating_average,total_trips) VALUES
 (4,'GPLX-7900','MOTORBIKE','59-X1 999.99',10.7735,106.7010,'AVAILABLE',TRUE,4.95,320),
 (5,'GPLX-7901','MOTORBIKE','59-A1 111.11',10.7715,106.7042,'AVAILABLE',TRUE,4.90,150),
 (6,'GPLX-7902','MOTORBIKE','59-A1 222.22',10.7721,106.6983,'AVAILABLE',TRUE,4.80,210)
ON DUPLICATE KEY UPDATE is_active=TRUE;
COMMIT;
