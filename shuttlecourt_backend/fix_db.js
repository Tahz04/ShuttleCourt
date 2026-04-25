const db = require('./config/database');

async function updateDatabase() {
  console.log('--- ĐANG CẬP NHẬT CẤU TRÚC DATABASE ---');
  try {
    // Thêm các cột mới vào bảng product_orders nếu chưa có
    await db.query(`
      ALTER TABLE product_orders 
      ADD COLUMN IF NOT EXISTS address TEXT DEFAULT NULL,
      ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'Tiền mặt',
      ADD COLUMN IF NOT EXISTS discount_code VARCHAR(50) DEFAULT NULL,
      ADD COLUMN IF NOT EXISTS subtotal DECIMAL(15,2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(15,2) DEFAULT 0;
    `);
    
    console.log('✅ Cập nhật Database thành công!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Lỗi khi cập nhật Database:', err.message);
    process.exit(1);
  }
}

updateDatabase();
