-- MySQL 8.4.11 / InnoDB - schema chính thức của đồ án.
CREATE DATABASE IF NOT EXISTS food_delivery_db CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE food_delivery_db;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS driver_reviews,restaurant_reviews,order_status_logs,ewallet_payments,card_payments,cash_payments,payments,driver_location_history,delivery_assignments,deliveries,order_item_options,order_items,orders,drivers,option_items,option_groups,items,categories,branches,restaurants,merchant_owners,customer_addresses,customers,users;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE users(
 user_id BIGINT AUTO_INCREMENT PRIMARY KEY,email VARCHAR(255) NOT NULL UNIQUE,phone_number VARCHAR(30) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,full_name VARCHAR(120) NOT NULL,user_type VARCHAR(30) NOT NULL,status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
 CONSTRAINT chk_users_type CHECK(user_type IN('CUSTOMER','MERCHANT_OWNER','DRIVER')),
 CONSTRAINT chk_users_status CHECK(status IN('ACTIVE','SUSPENDED','DELETED'))
) ENGINE=InnoDB;
CREATE TABLE customers(
 customer_id BIGINT PRIMARY KEY,loyalty_points INT NOT NULL DEFAULT 0,birth_date DATE,avatar_url VARCHAR(500),
 CONSTRAINT fk_customer_user FOREIGN KEY(customer_id) REFERENCES users(user_id) ON DELETE RESTRICT,
 CONSTRAINT chk_customer_points CHECK(loyalty_points>=0)
) ENGINE=InnoDB;
CREATE TABLE customer_addresses(
 address_id BIGINT AUTO_INCREMENT PRIMARY KEY,customer_id BIGINT NOT NULL,recipient_name VARCHAR(120) NOT NULL,recipient_phone VARCHAR(30) NOT NULL,
 street_address VARCHAR(255) NOT NULL,ward VARCHAR(100),district VARCHAR(100) NOT NULL,city VARCHAR(100) NOT NULL,
 latitude DECIMAL(10,8) NOT NULL,longitude DECIMAL(11,8) NOT NULL,address_label VARCHAR(50),is_default BOOLEAN NOT NULL DEFAULT FALSE,
 default_customer_guard BIGINT GENERATED ALWAYS AS(CASE WHEN is_default=1 THEN customer_id ELSE NULL END) STORED,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 CONSTRAINT fk_address_customer FOREIGN KEY(customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
 CONSTRAINT uq_customer_default UNIQUE(default_customer_guard),CONSTRAINT chk_address_lat CHECK(latitude BETWEEN -90 AND 90),
 CONSTRAINT chk_address_lon CHECK(longitude BETWEEN -180 AND 180)
) ENGINE=InnoDB;
CREATE TABLE merchant_owners(
 merchant_owner_id BIGINT PRIMARY KEY,tax_code VARCHAR(30) NOT NULL UNIQUE,identity_card_number VARCHAR(30) NOT NULL UNIQUE,
 business_license_url VARCHAR(500),kyc_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',verified_at DATETIME(6),
 CONSTRAINT fk_owner_user FOREIGN KEY(merchant_owner_id) REFERENCES users(user_id) ON DELETE RESTRICT,
 CONSTRAINT chk_owner_kyc CHECK(kyc_status IN('PENDING','VERIFIED','REJECTED'))
) ENGINE=InnoDB;
CREATE TABLE restaurants(
 restaurant_id BIGINT AUTO_INCREMENT PRIMARY KEY,owner_id BIGINT NOT NULL,restaurant_name VARCHAR(150) NOT NULL,cuisine_type VARCHAR(100),description TEXT,is_active BOOLEAN NOT NULL DEFAULT TRUE,
 CONSTRAINT fk_restaurant_owner FOREIGN KEY(owner_id) REFERENCES merchant_owners(merchant_owner_id) ON DELETE RESTRICT
) ENGINE=InnoDB;
CREATE TABLE branches(
 branch_id BIGINT AUTO_INCREMENT PRIMARY KEY,restaurant_id BIGINT NOT NULL,branch_name VARCHAR(150) NOT NULL,phone_number VARCHAR(30),street_address VARCHAR(255) NOT NULL,
 ward VARCHAR(100),district VARCHAR(100),city VARCHAR(100),latitude DECIMAL(10,8) NOT NULL,longitude DECIMAL(11,8) NOT NULL,
 opening_time TIME,closing_time TIME,is_active BOOLEAN NOT NULL DEFAULT TRUE,
 CONSTRAINT fk_branch_restaurant FOREIGN KEY(restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE RESTRICT,
 CONSTRAINT chk_branch_lat CHECK(latitude BETWEEN -90 AND 90),CONSTRAINT chk_branch_lon CHECK(longitude BETWEEN -180 AND 180)
) ENGINE=InnoDB;
CREATE TABLE categories(
 category_id BIGINT AUTO_INCREMENT PRIMARY KEY,restaurant_id BIGINT NOT NULL,category_name VARCHAR(120) NOT NULL,display_order INT NOT NULL DEFAULT 0,is_active BOOLEAN NOT NULL DEFAULT TRUE,
 CONSTRAINT fk_category_restaurant FOREIGN KEY(restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE RESTRICT,
 CONSTRAINT uq_category_name UNIQUE(restaurant_id,category_name)
) ENGINE=InnoDB;
CREATE TABLE items(
 item_id BIGINT AUTO_INCREMENT PRIMARY KEY,category_id BIGINT NOT NULL,item_name VARCHAR(150) NOT NULL,description TEXT,base_price DECIMAL(12,2) NOT NULL,is_available BOOLEAN NOT NULL DEFAULT TRUE,
 CONSTRAINT fk_item_category FOREIGN KEY(category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,CONSTRAINT chk_item_price CHECK(base_price>=0)
) ENGINE=InnoDB;
CREATE TABLE option_groups(
 group_id BIGINT AUTO_INCREMENT PRIMARY KEY,item_id BIGINT NOT NULL,group_name VARCHAR(120) NOT NULL,min_selection INT NOT NULL DEFAULT 0,max_selection INT NOT NULL DEFAULT 1,is_required BOOLEAN NOT NULL DEFAULT FALSE,
 CONSTRAINT fk_group_item FOREIGN KEY(item_id) REFERENCES items(item_id) ON DELETE CASCADE,
 CONSTRAINT chk_group_selection CHECK(min_selection>=0 AND max_selection>=min_selection)
) ENGINE=InnoDB;
CREATE TABLE option_items(
 option_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,group_id BIGINT NOT NULL,option_name VARCHAR(120) NOT NULL,extra_price DECIMAL(12,2) NOT NULL DEFAULT 0,is_available BOOLEAN NOT NULL DEFAULT TRUE,
 CONSTRAINT fk_option_group FOREIGN KEY(group_id) REFERENCES option_groups(group_id) ON DELETE CASCADE,CONSTRAINT chk_option_price CHECK(extra_price>=0)
) ENGINE=InnoDB;
CREATE TABLE drivers(
 driver_id BIGINT PRIMARY KEY,license_number VARCHAR(50) NOT NULL UNIQUE,vehicle_type VARCHAR(30) NOT NULL,vehicle_plate VARCHAR(30) NOT NULL UNIQUE,
 current_lat DECIMAL(10,8),current_long DECIMAL(11,8),driver_status VARCHAR(20) NOT NULL DEFAULT 'OFFLINE',is_active BOOLEAN NOT NULL DEFAULT TRUE,
 rating_average DECIMAL(3,2) NOT NULL DEFAULT 0,total_trips INT NOT NULL DEFAULT 0,
 CONSTRAINT fk_driver_user FOREIGN KEY(driver_id) REFERENCES users(user_id) ON DELETE RESTRICT,
 CONSTRAINT chk_driver_vehicle CHECK(vehicle_type IN('MOTORBIKE','ELECTRIC_BIKE','CAR')),
 CONSTRAINT chk_driver_status CHECK(driver_status IN('OFFLINE','AVAILABLE','DELIVERING')),
 CONSTRAINT chk_driver_coords CHECK((current_lat IS NULL AND current_long IS NULL) OR (current_lat BETWEEN -90 AND 90 AND current_long BETWEEN -180 AND 180))
) ENGINE=InnoDB;
CREATE TABLE orders(
 order_id BIGINT AUTO_INCREMENT PRIMARY KEY,order_code VARCHAR(50) NOT NULL UNIQUE,customer_id BIGINT NOT NULL,branch_id BIGINT NOT NULL,driver_id BIGINT NULL,delivery_address_id BIGINT NOT NULL,
 recipient_name_snapshot VARCHAR(120) NOT NULL,recipient_phone_snapshot VARCHAR(30) NOT NULL,delivery_address_snapshot TEXT NOT NULL,
 delivery_latitude_snapshot DECIMAL(10,8) NOT NULL,delivery_longitude_snapshot DECIMAL(11,8) NOT NULL,order_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
 subtotal_amount DECIMAL(12,2) NOT NULL,delivery_fee DECIMAL(12,2) NOT NULL DEFAULT 0,service_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
 discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,total_amount DECIMAL(12,2) NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
 CONSTRAINT fk_order_customer FOREIGN KEY(customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
 CONSTRAINT fk_order_branch FOREIGN KEY(branch_id) REFERENCES branches(branch_id) ON DELETE RESTRICT,
 CONSTRAINT fk_order_driver FOREIGN KEY(driver_id) REFERENCES drivers(driver_id) ON DELETE SET NULL,
 CONSTRAINT fk_order_address FOREIGN KEY(delivery_address_id) REFERENCES customer_addresses(address_id) ON DELETE RESTRICT,
 CONSTRAINT chk_order_status CHECK(order_status IN('PENDING','CONFIRMED','PREPARING','READY_FOR_PICKUP','PICKED_UP','DELIVERED','CANCELLED')),
 CONSTRAINT chk_order_money CHECK(subtotal_amount>=0 AND delivery_fee>=0 AND service_fee>=0 AND discount_amount>=0 AND total_amount=subtotal_amount+delivery_fee+service_fee-discount_amount),
 CONSTRAINT chk_order_coords CHECK(delivery_latitude_snapshot BETWEEN -90 AND 90 AND delivery_longitude_snapshot BETWEEN -180 AND 180)
) ENGINE=InnoDB;
CREATE TABLE order_items(
 order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,order_id BIGINT NOT NULL,item_id BIGINT NULL,item_name_snapshot VARCHAR(150) NOT NULL,
 unit_price_snapshot DECIMAL(12,2) NOT NULL,quantity INT NOT NULL,subtotal DECIMAL(12,2) NOT NULL,
 CONSTRAINT fk_order_item_order FOREIGN KEY(order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
 CONSTRAINT fk_order_item_item FOREIGN KEY(item_id) REFERENCES items(item_id) ON DELETE SET NULL,
 CONSTRAINT chk_order_item_qty CHECK(quantity>0),CONSTRAINT chk_order_item_money CHECK(unit_price_snapshot>=0 AND subtotal>=0)
) ENGINE=InnoDB;
CREATE TABLE order_item_options(
 order_item_option_id BIGINT AUTO_INCREMENT PRIMARY KEY,order_item_id BIGINT NOT NULL,option_item_id BIGINT NULL,option_name_snapshot VARCHAR(120) NOT NULL,extra_price_snapshot DECIMAL(12,2) NOT NULL,
 CONSTRAINT fk_oio_order_item FOREIGN KEY(order_item_id) REFERENCES order_items(order_item_id) ON DELETE CASCADE,
 CONSTRAINT fk_oio_option FOREIGN KEY(option_item_id) REFERENCES option_items(option_item_id) ON DELETE SET NULL,
 CONSTRAINT chk_oio_price CHECK(extra_price_snapshot>=0)
) ENGINE=InnoDB;
CREATE TABLE deliveries(
 delivery_id BIGINT AUTO_INCREMENT PRIMARY KEY,order_id BIGINT NOT NULL UNIQUE,delivery_status VARCHAR(30) NOT NULL DEFAULT 'WAITING_ASSIGNMENT',
 pickup_at DATETIME(6),delivered_at DATETIME(6),failed_at DATETIME(6),failure_reason TEXT,
 CONSTRAINT fk_delivery_order FOREIGN KEY(order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,
 CONSTRAINT chk_delivery_status CHECK(delivery_status IN('WAITING_ASSIGNMENT','ASSIGNED','TO_PICKUP','PICKED_UP','DELIVERING','DELIVERED','FAILED','CANCELLED')),
 CONSTRAINT chk_delivery_failure CHECK((delivery_status='FAILED' AND failure_reason IS NOT NULL AND failed_at IS NOT NULL) OR delivery_status<>'FAILED')
) ENGINE=InnoDB;
CREATE TABLE delivery_assignments(
 assignment_id BIGINT AUTO_INCREMENT PRIMARY KEY,delivery_id BIGINT NOT NULL,driver_id BIGINT NOT NULL,assigned_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),ended_at DATETIME(6),end_reason VARCHAR(30),
 active_delivery_guard BIGINT GENERATED ALWAYS AS(CASE WHEN ended_at IS NULL THEN delivery_id ELSE NULL END) STORED,
 CONSTRAINT fk_assignment_delivery FOREIGN KEY(delivery_id) REFERENCES deliveries(delivery_id) ON DELETE RESTRICT,
 CONSTRAINT fk_assignment_driver FOREIGN KEY(driver_id) REFERENCES drivers(driver_id) ON DELETE RESTRICT,
 CONSTRAINT uq_active_assignment UNIQUE(active_delivery_guard),CONSTRAINT chk_assignment_time CHECK(ended_at IS NULL OR ended_at>=assigned_at),
 CONSTRAINT chk_assignment_reason CHECK(end_reason IS NULL OR end_reason IN('COMPLETED','REASSIGNED','REJECTED','CANCELLED','FAILED'))
) ENGINE=InnoDB;
CREATE TABLE driver_location_history(
 location_id BIGINT AUTO_INCREMENT PRIMARY KEY,driver_id BIGINT NOT NULL,assignment_id BIGINT NULL,latitude DECIMAL(10,8) NOT NULL,longitude DECIMAL(11,8) NOT NULL,
 captured_at DATETIME(6) NOT NULL,recorded_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),accuracy_m DECIMAL(8,2),
 CONSTRAINT fk_location_driver FOREIGN KEY(driver_id) REFERENCES drivers(driver_id) ON DELETE RESTRICT,
 CONSTRAINT fk_location_assignment FOREIGN KEY(assignment_id) REFERENCES delivery_assignments(assignment_id) ON DELETE SET NULL,
 CONSTRAINT uq_location_sample UNIQUE(driver_id,captured_at),CONSTRAINT chk_location_coords CHECK(latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180),
 CONSTRAINT chk_location_accuracy CHECK(accuracy_m IS NULL OR accuracy_m>=0)
) ENGINE=InnoDB;
CREATE TABLE payments(
 payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,order_id BIGINT NOT NULL,amount DECIMAL(12,2) NOT NULL,payment_method VARCHAR(20) NOT NULL,payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
 paid_at DATETIME(6),created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 success_order_guard BIGINT GENERATED ALWAYS AS(CASE WHEN payment_status='SUCCESS' THEN order_id ELSE NULL END) STORED,
 CONSTRAINT fk_payment_order FOREIGN KEY(order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,
 CONSTRAINT uq_one_success UNIQUE(success_order_guard),CONSTRAINT chk_payment_amount CHECK(amount>=0),
 CONSTRAINT chk_payment_method CHECK(payment_method IN('CASH','CARD','EWALLET')),CONSTRAINT chk_payment_status CHECK(payment_status IN('PENDING','SUCCESS','FAILED','REFUNDED'))
) ENGINE=InnoDB;
CREATE TABLE cash_payments(payment_id BIGINT PRIMARY KEY,change_amount_for DECIMAL(12,2),CONSTRAINT fk_cash_payment FOREIGN KEY(payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE,CONSTRAINT chk_cash_change CHECK(change_amount_for IS NULL OR change_amount_for>=0)) ENGINE=InnoDB;
CREATE TABLE card_payments(payment_id BIGINT PRIMARY KEY,card_last4 CHAR(4) NOT NULL,card_brand VARCHAR(20) NOT NULL,transaction_ref VARCHAR(100) NOT NULL UNIQUE,CONSTRAINT fk_card_payment FOREIGN KEY(payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE,CONSTRAINT chk_card_last4 CHECK(REGEXP_LIKE(card_last4,'^[0-9]{4}$')),CONSTRAINT chk_card_brand CHECK(card_brand IN('VISA','MASTERCARD','JCB','NAPAS'))) ENGINE=InnoDB;
CREATE TABLE ewallet_payments(payment_id BIGINT PRIMARY KEY,wallet_provider VARCHAR(20) NOT NULL,wallet_transaction_id VARCHAR(100) NOT NULL UNIQUE,CONSTRAINT fk_wallet_payment FOREIGN KEY(payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE,CONSTRAINT chk_wallet_provider CHECK(wallet_provider IN('MOMO','ZALOPAY','SHOPEEPAY'))) ENGINE=InnoDB;
CREATE TABLE order_status_logs(
 log_id BIGINT AUTO_INCREMENT PRIMARY KEY,order_id BIGINT NOT NULL,previous_status VARCHAR(30),new_status VARCHAR(30) NOT NULL,changed_by_user_id BIGINT NULL,note TEXT,created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 CONSTRAINT fk_log_order FOREIGN KEY(order_id) REFERENCES orders(order_id) ON DELETE CASCADE,CONSTRAINT fk_log_user FOREIGN KEY(changed_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;
CREATE TABLE restaurant_reviews(
 review_id BIGINT AUTO_INCREMENT PRIMARY KEY,order_id BIGINT NOT NULL UNIQUE,customer_id BIGINT NOT NULL,restaurant_id BIGINT NOT NULL,rating SMALLINT NOT NULL,comment TEXT,reply_from_merchant TEXT,created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 CONSTRAINT fk_rr_order FOREIGN KEY(order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,CONSTRAINT fk_rr_customer FOREIGN KEY(customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,CONSTRAINT fk_rr_restaurant FOREIGN KEY(restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE RESTRICT,CONSTRAINT chk_rr_rating CHECK(rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;
CREATE TABLE driver_reviews(
 review_id BIGINT AUTO_INCREMENT PRIMARY KEY,order_id BIGINT NOT NULL UNIQUE,customer_id BIGINT NOT NULL,driver_id BIGINT NOT NULL,rating SMALLINT NOT NULL,comment TEXT,tipping_amount DECIMAL(12,2) NOT NULL DEFAULT 0,created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 CONSTRAINT fk_dr_order FOREIGN KEY(order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,CONSTRAINT fk_dr_customer FOREIGN KEY(customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,CONSTRAINT fk_dr_driver FOREIGN KEY(driver_id) REFERENCES drivers(driver_id) ON DELETE RESTRICT,CONSTRAINT chk_dr_rating CHECK(rating BETWEEN 1 AND 5),CONSTRAINT chk_dr_tip CHECK(tipping_amount>=0)
) ENGINE=InnoDB;

DELIMITER $$
CREATE TRIGGER trg_order_item_branch_ins BEFORE INSERT ON order_items FOR EACH ROW
BEGIN IF NEW.item_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM orders o JOIN branches b ON b.branch_id=o.branch_id JOIN categories c ON c.restaurant_id=b.restaurant_id JOIN items i ON i.category_id=c.category_id WHERE o.order_id=NEW.order_id AND i.item_id=NEW.item_id) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Món không thuộc nhà hàng của chi nhánh xử lý đơn'; END IF; END$$
CREATE TRIGGER trg_order_item_branch_upd BEFORE UPDATE ON order_items FOR EACH ROW
BEGIN IF NEW.item_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM orders o JOIN branches b ON b.branch_id=o.branch_id JOIN categories c ON c.restaurant_id=b.restaurant_id JOIN items i ON i.category_id=c.category_id WHERE o.order_id=NEW.order_id AND i.item_id=NEW.item_id) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Món không thuộc nhà hàng của chi nhánh xử lý đơn'; END IF; END$$
CREATE TRIGGER trg_order_transition BEFORE UPDATE ON orders FOR EACH ROW
BEGIN
 IF NEW.order_status<>OLD.order_status THEN
  IF NOT((OLD.order_status='PENDING' AND NEW.order_status IN('CONFIRMED','CANCELLED')) OR (OLD.order_status='CONFIRMED' AND NEW.order_status IN('PREPARING','CANCELLED')) OR (OLD.order_status='PREPARING' AND NEW.order_status='READY_FOR_PICKUP') OR (OLD.order_status='READY_FOR_PICKUP' AND NEW.order_status='PICKED_UP') OR (OLD.order_status='PICKED_UP' AND NEW.order_status='DELIVERED')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Chuyển trạng thái đơn không hợp lệ'; END IF;
  INSERT INTO order_status_logs(order_id,previous_status,new_status,note) VALUES(OLD.order_id,OLD.order_status,NEW.order_status,'Tự động ghi bởi trigger MySQL');
 END IF;
END$$
CREATE TRIGGER trg_restaurant_review_ins BEFORE INSERT ON restaurant_reviews FOR EACH ROW
BEGIN IF NOT EXISTS(SELECT 1 FROM orders WHERE order_id=NEW.order_id AND customer_id=NEW.customer_id AND order_status='DELIVERED') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Chỉ khách của đơn DELIVERED mới được đánh giá'; END IF; END$$
CREATE TRIGGER trg_driver_review_ins BEFORE INSERT ON driver_reviews FOR EACH ROW
BEGIN IF NOT EXISTS(SELECT 1 FROM orders WHERE order_id=NEW.order_id AND customer_id=NEW.customer_id AND order_status='DELIVERED') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Chỉ khách của đơn DELIVERED mới được đánh giá'; END IF; END$$
DELIMITER ;
