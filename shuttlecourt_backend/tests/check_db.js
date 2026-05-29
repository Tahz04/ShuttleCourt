const db = require('../config/database');

async function check() {
  try {
    const [products] = await db.query("SELECT id, name, owner_id, price FROM products");
    console.log("=== PRODUCTS ===");
    console.table(products);

    const [orders] = await db.query("SELECT id, user_id, total_price, created_at FROM product_orders");
    console.log("=== ORDERS ===");
    console.table(orders);

    const [orderItems] = await db.query(`
      SELECT oi.id, oi.order_id, oi.product_id, oi.quantity, oi.price, p.owner_id 
      FROM product_order_items oi
      JOIN products p ON oi.product_id = p.id
    `);
    console.log("=== ORDER ITEMS WITH PRODUCT OWNER ===");
    console.table(orderItems);

    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

check();
