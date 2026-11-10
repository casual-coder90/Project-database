require('dotenv').config();
const express = require('express');
const path = require('path');
const mysql = require('mysql2/promise');

const app = express();
const rawPool = mysql.createPool({
  uri: process.env.DATABASE_URL || 'mysql://food_app:food_app_password@localhost:3306/food_delivery_db',
  ssl: process.env.DB_SSL === 'true' ? {} : undefined,
  waitForConnections: true, connectionLimit: 10, decimalNumbers: false
});
function mysqlParams(sql, params=[]) {
  if(!/\$\d+/.test(sql)) return [sql,params];
  const ordered=[];
  const text=sql.replace(/\$(\d+)/g,(_m,n)=>{ordered.push(params[Number(n)-1]);return '?'});
  return [text,ordered];
}
function wrap(connection) { return { query: async(sql,params=[])=>{ const [text,ordered]=mysqlParams(sql,params); const [result]=await connection.query(text,ordered); return {rows:Array.isArray(result)?result:[],rowCount:result.affectedRows??result.length,insertId:result.insertId}; } }; }
const pool={query:(sql,params)=>wrap(rawPool).query(sql,params),connect:async()=>{const c=await rawPool.getConnection();const w=wrap(c);return {...w,release:()=>c.release()}}};
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const asyncRoute = fn => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
const fail = (status, message) => Object.assign(new Error(message), { status });
async function tx(work) {
  const client = await pool.connect();
  try { await client.query('START TRANSACTION'); const result = await work(client); await client.query('COMMIT'); return result; }
  catch (e) { await client.query('ROLLBACK'); throw e; }
  finally { client.release(); }
}
async function actor(client, userId, type) {
  const { rows } = await client.query('SELECT user_id,user_type,full_name FROM users WHERE user_id=$1 AND status=$2', [userId, 'ACTIVE']);
  if (!rows[0] || (type && rows[0].user_type !== type)) throw fail(403, 'Tài khoản mẫu không có quyền thực hiện thao tác này.');
  return rows[0];
}
async function orderDetail(orderId) {
  const order = await pool.query(`SELECT o.*,b.branch_name,r.restaurant_name,u.full_name customer_name,de.delivery_id,de.delivery_status,
    da.driver_id,du.full_name driver_name FROM orders o JOIN branches b USING(branch_id) JOIN restaurants r USING(restaurant_id)
    JOIN users u ON u.user_id=o.customer_id LEFT JOIN deliveries de USING(order_id)
    LEFT JOIN LATERAL (SELECT a.* FROM delivery_assignments a WHERE a.delivery_id=de.delivery_id ORDER BY a.assigned_at DESC LIMIT 1) da ON TRUE
    LEFT JOIN users du ON du.user_id=da.driver_id WHERE o.order_id=$1`, [orderId]);
  if (!order.rows[0]) throw fail(404, 'Không tìm thấy đơn.');
  const [items, history, assignments, locations, payments] = await Promise.all([
    pool.query('SELECT item_name_snapshot,unit_price_snapshot,quantity,subtotal FROM order_items WHERE order_id=$1 ORDER BY order_item_id', [orderId]),
    pool.query(`SELECT previous_status,new_status,created_at,note FROM order_status_logs WHERE order_id=$1 ORDER BY created_at,log_id`, [orderId]),
    pool.query(`SELECT da.assignment_id,da.driver_id,u.full_name driver_name,da.assigned_at,da.ended_at,da.end_reason
      FROM deliveries de JOIN delivery_assignments da USING(delivery_id) JOIN users u ON u.user_id=da.driver_id
      WHERE de.order_id=$1 ORDER BY da.assigned_at`, [orderId]),
    pool.query(`SELECT h.latitude,h.longitude,h.captured_at,h.recorded_at,h.accuracy_m,u.full_name driver_name
      FROM deliveries de JOIN delivery_assignments da USING(delivery_id) JOIN driver_location_history h USING(assignment_id)
      JOIN users u ON u.user_id=h.driver_id WHERE de.order_id=$1 ORDER BY h.captured_at`, [orderId]),
    pool.query(`SELECT payment_id,amount,payment_method,payment_status,paid_at,created_at FROM payments WHERE order_id=$1 ORDER BY created_at,payment_id`, [orderId])
  ]);
  return { order: order.rows[0], items: items.rows, history: history.rows, assignments: assignments.rows, locations: locations.rows, payments: payments.rows };
}

app.get('/api/health', asyncRoute(async (_req, res) => {
  const { rows } = await pool.query('SELECT DATABASE() AS db_name, VERSION() AS version'); res.json({ ok: true, database: rows[0].db_name, version: rows[0].version });
}));
app.get('/api/accounts', asyncRoute(async (_req, res) => {
  const { rows } = await pool.query(`SELECT user_id,full_name,user_type FROM users WHERE status='ACTIVE' ORDER BY user_type,user_id`); res.json(rows);
}));
app.get('/api/restaurants', asyncRoute(async (_req, res) => {
  const { rows } = await pool.query(`SELECT r.restaurant_id,r.restaurant_name,b.branch_id,b.branch_name,b.district,b.city
    FROM restaurants r JOIN branches b USING(restaurant_id) WHERE r.is_active AND b.is_active ORDER BY r.restaurant_name`); res.json(rows);
}));
app.get('/api/branches/:id/menu', asyncRoute(async (req, res) => {
  const { rows } = await pool.query(`SELECT i.item_id,i.item_name,i.description,i.base_price,c.category_name
    FROM branches b JOIN categories c USING(restaurant_id) JOIN items i USING(category_id)
    WHERE b.branch_id=$1 AND i.is_available AND c.is_active ORDER BY c.display_order,i.item_name`, [req.params.id]); res.json(rows);
}));

app.post('/api/orders', asyncRoute(async (req, res) => {
  const { customerId, branchId, recipientName, recipientPhone, address, latitude, longitude, items } = req.body;
  if (!Number.isInteger(customerId) || !Number.isInteger(branchId) || !Array.isArray(items) || !items.length) throw fail(400, 'Thiếu khách hàng, chi nhánh hoặc món.');
  if (!recipientName?.trim() || !recipientPhone?.trim() || !address?.trim()) throw fail(400, 'Thông tin nhận hàng chưa đầy đủ.');
  if (!Number.isFinite(+latitude) || +latitude < -90 || +latitude > 90 || !Number.isFinite(+longitude) || +longitude < -180 || +longitude > 180) throw fail(400, 'Tọa độ không hợp lệ.');
  const result = await tx(async client => {
    await actor(client, customerId, 'CUSTOMER');
    const normalized = items.map(x => ({ itemId: Number(x.itemId), quantity: Number(x.quantity) }));
    if (normalized.some(x => !Number.isInteger(x.itemId) || !Number.isInteger(x.quantity) || x.quantity < 1 || x.quantity > 20)) throw fail(400, 'Số lượng món phải từ 1 đến 20.');
    const ids = normalized.map(x => x.itemId);
    const marks=ids.map(()=>'?').join(',');
    const menu=await client.query(`SELECT i.item_id,i.item_name,i.base_price FROM branches b JOIN categories c USING(restaurant_id)
      JOIN items i USING(category_id) WHERE b.branch_id=? AND i.item_id IN (${marks}) AND i.is_available=1`, [branchId,...ids]);
    if (menu.rows.length !== new Set(ids).size) throw fail(400, 'Có món không thuộc chi nhánh hoặc đã ngừng bán.');
    const map = new Map(menu.rows.map(x => [Number(x.item_id), x]));
    const subtotal = normalized.reduce((sum, x) => sum + Number(map.get(x.itemId).base_price) * x.quantity, 0);
    const deliveryFee = 15000, serviceFee = 3000, total = subtotal + deliveryFee + serviceFee;
    const addr = await client.query(`INSERT INTO customer_addresses(customer_id,recipient_name,recipient_phone,street_address,district,city,latitude,longitude,address_label,is_default)
      VALUES($1,$2,$3,$4,'Demo','TP.HCM',$5,$6,'Địa chỉ đơn demo',FALSE)`,
      [customerId, recipientName.trim(), recipientPhone.trim(), address.trim(), +latitude, +longitude]);
    const code = `DEMO-${Date.now()}`;
    const order = await client.query(`INSERT INTO orders(order_code,customer_id,branch_id,delivery_address_id,recipient_name_snapshot,recipient_phone_snapshot,
      delivery_address_snapshot,delivery_latitude_snapshot,delivery_longitude_snapshot,order_status,subtotal_amount,delivery_fee,service_fee,discount_amount,total_amount)
      VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,'PENDING',$10,$11,$12,0,$13)`,
      [code, customerId, branchId, addr.insertId, recipientName.trim(), recipientPhone.trim(), address.trim(), +latitude, +longitude, subtotal, deliveryFee, serviceFee, total]);
    const orderId=order.insertId;
    for (const line of normalized) {
      const m = map.get(line.itemId); const lineTotal = Number(m.base_price) * line.quantity;
      await client.query(`INSERT INTO order_items(order_id,item_id,item_name_snapshot,unit_price_snapshot,quantity,subtotal) VALUES($1,$2,$3,$4,$5,$6)`,
        [orderId, line.itemId, m.item_name, m.base_price, line.quantity, lineTotal]);
    }
    const pay = await client.query(`INSERT INTO payments(order_id,amount,payment_method,payment_status) VALUES($1,$2,'CASH','PENDING')`, [orderId, total]);
    await client.query(`INSERT INTO cash_payments(payment_id) VALUES($1)`, [pay.insertId]);
    await client.query(`INSERT INTO order_status_logs(order_id,new_status,changed_by_user_id,note) VALUES($1,'PENDING',$2,'Khách hàng đặt đơn trên ứng dụng demo')`, [orderId, customerId]);
    return {order_id:orderId,order_code:code,total_amount:total};
  }); res.status(201).json(result);
}));

app.get('/api/orders', asyncRoute(async (req, res) => {
  const userId = Number(req.query.userId); if (!Number.isInteger(userId)) throw fail(400, 'Thiếu userId.');
  const { rows: users } = await pool.query('SELECT user_type FROM users WHERE user_id=$1', [userId]); if (!users[0]) throw fail(404, 'Không có tài khoản.');
  let filter = '', params = [];
  if (users[0].user_type === 'CUSTOMER') { filter = 'WHERE o.customer_id=$1'; params=[userId]; }
  else if (users[0].user_type === 'MERCHANT_OWNER') { filter='WHERE r.owner_id=$1'; params=[userId]; }
  else if (users[0].user_type === 'DRIVER') { filter='WHERE da.driver_id=$1'; params=[userId]; }
  const { rows } = await pool.query(`SELECT DISTINCT o.order_id,o.order_code,o.order_status,o.total_amount,o.created_at,b.branch_name,u.full_name customer_name,
    de.delivery_status,da.driver_id,du.full_name driver_name FROM orders o JOIN branches b USING(branch_id) JOIN restaurants r USING(restaurant_id)
    JOIN users u ON u.user_id=o.customer_id LEFT JOIN deliveries de USING(order_id)
    LEFT JOIN LATERAL (SELECT a.* FROM delivery_assignments a WHERE a.delivery_id=de.delivery_id ORDER BY a.assigned_at DESC LIMIT 1) da ON TRUE
    LEFT JOIN users du ON du.user_id=da.driver_id
    ${filter} ORDER BY o.created_at DESC`, params); res.json(rows);
}));

app.get('/api/orders/:id', asyncRoute(async (req, res) => {
  res.json(await orderDetail(req.params.id));
}));
app.get('/api/audit/orders', asyncRoute(async (req,res)=>{
  const code=String(req.query.code||'').trim(); if(!code) throw fail(400,'Hãy nhập mã đơn.');
  const found=await pool.query('SELECT order_id FROM orders WHERE order_code=$1',[code]); if(!found.rowCount) throw fail(404,'Không tìm thấy mã đơn.');
  res.json(await orderDetail(found.rows[0].order_id));
}));

app.post('/api/orders/:id/restaurant-status', asyncRoute(async (req, res) => {
  const { userId, status } = req.body; if (!['CONFIRMED','PREPARING','READY_FOR_PICKUP'].includes(status)) throw fail(400, 'Trạng thái nhà hàng không hợp lệ.');
  await tx(async client => { await actor(client, Number(userId), 'MERCHANT_OWNER');
    const own=await client.query(`SELECT o.order_id FROM orders o JOIN branches b ON b.branch_id=o.branch_id JOIN restaurants r ON r.restaurant_id=b.restaurant_id
      WHERE o.order_id=$1 AND r.owner_id=$2 FOR UPDATE`,[req.params.id,userId]);
    if (!own.rowCount) throw fail(403, 'Đơn không thuộc nhà hàng của tài khoản.');
    await client.query(`UPDATE orders SET order_status=$1,updated_at=CURRENT_TIMESTAMP(6) WHERE order_id=$2`,[status,req.params.id]);
  }); res.json({ ok:true });
}));

app.get('/api/drivers', asyncRoute(async (_req,res) => { const {rows}=await pool.query(`SELECT d.driver_id,u.full_name,d.vehicle_plate,d.driver_status FROM drivers d JOIN users u ON u.user_id=d.driver_id WHERE d.is_active ORDER BY u.full_name`); res.json(rows); }));
app.post('/api/orders/:id/assign', asyncRoute(async (req,res) => {
  const { userId, driverId }=req.body; await tx(async client => { await actor(client,Number(userId),'MERCHANT_OWNER');
    const own=await client.query(`SELECT o.order_id FROM orders o JOIN branches b USING(branch_id) JOIN restaurants r USING(restaurant_id) WHERE o.order_id=$1 AND r.owner_id=$2 AND o.order_status='READY_FOR_PICKUP'`,[req.params.id,userId]);
    if(!own.rowCount) throw fail(400,'Chỉ điều phối đơn sẵn sàng bàn giao của nhà hàng mình.');
    const d=await client.query(`SELECT driver_id FROM drivers WHERE driver_id=$1 AND is_active AND driver_status='AVAILABLE' FOR UPDATE`,[driverId]); if(!d.rowCount) throw fail(400,'Tài xế không sẵn sàng.');
    await client.query(`INSERT INTO deliveries(order_id,delivery_status) VALUES($1,'ASSIGNED') ON DUPLICATE KEY UPDATE delivery_status='ASSIGNED'`,[req.params.id]);
    const de=await client.query(`SELECT delivery_id FROM deliveries WHERE order_id=$1`,[req.params.id]);
    await client.query(`UPDATE delivery_assignments SET ended_at=CURRENT_TIMESTAMP(6),end_reason='REASSIGNED' WHERE delivery_id=$1 AND ended_at IS NULL`,[de.rows[0].delivery_id]);
    await client.query(`INSERT INTO delivery_assignments(delivery_id,driver_id) VALUES($1,$2)`,[de.rows[0].delivery_id,driverId]);
    await client.query(`UPDATE drivers SET driver_status='DELIVERING' WHERE driver_id=$1`,[driverId]);
  }); res.json({ok:true});
}));

app.post('/api/orders/:id/driver-status', asyncRoute(async (req,res) => {
  const { userId, action }=req.body; if(!['PICKUP','DELIVER'].includes(action)) throw fail(400,'Thao tác tài xế không hợp lệ.');
  await tx(async client=>{ await actor(client,Number(userId),'DRIVER');
    const q=await client.query(`SELECT o.order_id,o.order_status,de.delivery_id,de.delivery_status FROM orders o JOIN deliveries de USING(order_id)
      JOIN delivery_assignments da USING(delivery_id) WHERE o.order_id=$1 AND da.driver_id=$2 AND da.ended_at IS NULL FOR UPDATE`,[req.params.id,userId]);
    if(!q.rowCount) throw fail(403,'Đơn không được phân công cho tài xế.');
    if(action==='PICKUP') { await client.query(`UPDATE orders SET order_status='PICKED_UP' WHERE order_id=$1`,[req.params.id]); await client.query(`UPDATE deliveries SET delivery_status='DELIVERING',pickup_at=CURRENT_TIMESTAMP(6) WHERE delivery_id=$1`,[q.rows[0].delivery_id]); }
    else { await client.query(`UPDATE orders SET order_status='DELIVERED' WHERE order_id=$1`,[req.params.id]); await client.query(`UPDATE deliveries SET delivery_status='DELIVERED',delivered_at=CURRENT_TIMESTAMP(6) WHERE delivery_id=$1`,[q.rows[0].delivery_id]); await client.query(`UPDATE delivery_assignments SET ended_at=CURRENT_TIMESTAMP(6),end_reason='COMPLETED' WHERE delivery_id=$1 AND ended_at IS NULL`,[q.rows[0].delivery_id]); await client.query(`UPDATE drivers SET driver_status='AVAILABLE' WHERE driver_id=$1`,[userId]); await client.query(`UPDATE payments SET payment_status='SUCCESS',paid_at=CURRENT_TIMESTAMP(6) WHERE order_id=$1 AND payment_method='CASH'`,[req.params.id]); }
  }); res.json({ok:true});
}));

app.post('/api/orders/:id/location', asyncRoute(async(req,res)=>{ const {userId,latitude,longitude}=req.body; await tx(async client=>{ await actor(client,Number(userId),'DRIVER');
  if(!Number.isFinite(+latitude)||+latitude < -90||+latitude > 90||!Number.isFinite(+longitude)||+longitude < -180||+longitude > 180) throw fail(400,'Tọa độ không hợp lệ.');
  const q=await client.query(`SELECT da.assignment_id FROM deliveries de JOIN delivery_assignments da USING(delivery_id) WHERE de.order_id=$1 AND da.driver_id=$2 AND da.ended_at IS NULL`,[req.params.id,userId]); if(!q.rowCount) throw fail(403,'Không có phân công hiệu lực.');
  await client.query(`INSERT INTO driver_location_history(driver_id,assignment_id,latitude,longitude,captured_at,accuracy_m) VALUES($1,$2,$3,$4,CURRENT_TIMESTAMP(6),10)`,[userId,q.rows[0].assignment_id,latitude,longitude]);
  await client.query(`UPDATE drivers SET current_lat=$2,current_long=$3 WHERE driver_id=$1`,[userId,latitude,longitude]);
}); res.json({ok:true,simulation:true}); }));

app.use((err,_req,res,_next)=>{ console.error(err); const databaseRuleError=err.sqlState?.startsWith('23')||err.sqlState==='45000'; const known=err.status || (databaseRuleError ? 400 : 500); res.status(known).json({error: known===500?'Lỗi máy chủ. Xem log để biết chi tiết.':err.message}); });
const port=Number(process.env.PORT||3000); const server=app.listen(port,()=>console.log(`Demo: http://localhost:${port}`));
module.exports={app,server,pool};
