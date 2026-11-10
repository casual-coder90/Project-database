const test = require('node:test');
const assert = require('node:assert/strict');
const base = process.env.BASE_URL || 'http://localhost:3000/api';
async function call(path, method='GET', body) { const r=await fetch(base+path,{method,headers:{'content-type':'application/json'},body:body&&JSON.stringify(body)}); const d=await r.json(); assert.equal(r.ok,true,d.error); return d; }
test('luồng đặt món đến giao thành công dùng MySQL/InnoDB', async()=>{
  const health=await call('/health'); assert.equal(health.ok,true);
  const branches=await call('/restaurants'); const branchId=Number(branches[0].branch_id);
  const menu=await call(`/branches/${branchId}/menu`); const itemId=Number(menu[0].item_id);
  const invalid=await fetch(base+'/orders',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({customerId:1,branchId,recipientName:'Sai',recipientPhone:'0909',address:'Test',latitude:10,longitude:106,items:[{itemId,quantity:0}]})});
  assert.equal(invalid.status,400,'Số lượng 0 phải bị từ chối');
  const order=await call('/orders','POST',{customerId:1,branchId,recipientName:'API Test',recipientPhone:'0909000001',address:'Địa chỉ API test',latitude:10.775,longitude:106.704,items:[{itemId,quantity:1}]});
  for(const status of ['CONFIRMED','PREPARING','READY_FOR_PICKUP']) await call(`/orders/${order.order_id}/restaurant-status`,'POST',{userId:3,status});
  const drivers=await call('/drivers'); const driver=drivers.find(x=>x.driver_status==='AVAILABLE'); assert.ok(driver,'Cần một tài xế AVAILABLE');
  await call(`/orders/${order.order_id}/assign`,'POST',{userId:3,driverId:Number(driver.driver_id)});
  await call(`/orders/${order.order_id}/driver-status`,'POST',{userId:Number(driver.driver_id),action:'PICKUP'});
  await call(`/orders/${order.order_id}/location`,'POST',{userId:Number(driver.driver_id),latitude:10.776,longitude:106.705});
  await call(`/orders/${order.order_id}/driver-status`,'POST',{userId:Number(driver.driver_id),action:'DELIVER'});
  const final=await call(`/orders/${order.order_id}`); assert.equal(final.order.order_status,'DELIVERED'); assert.equal(final.order.delivery_status,'DELIVERED'); assert.equal(Number(final.order.driver_id),Number(driver.driver_id)); assert.equal(final.history.length,6);
  assert.equal(final.assignments.length,1); assert.equal(final.locations.length,1); assert.equal(final.payments[0].payment_status,'SUCCESS');
  const audit=await call(`/audit/orders?code=${encodeURIComponent(order.order_code)}`); assert.equal(audit.order.order_code,order.order_code);
  const badTransition=await fetch(base+`/orders/${order.order_id}/restaurant-status`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({userId:3,status:'CONFIRMED'})});
  assert.equal(badTransition.status,400,'DELIVERED -> CONFIRMED phải bị từ chối');
});
