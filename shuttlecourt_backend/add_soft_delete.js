const db = require('./config/database');

async function addSoftDelete() {
  console.log('--- ĐANG CÀI ĐẶT CHẾ ĐỘ XÓA MỀM ---');
  try {
    await db.query(`
      ALTER TABLE products 
      ADD COLUMN IF NOT EXISTS is_deleted TINYINT(1) DEFAULT 0;
    `);
    console.log('✅ Cài đặt thành công!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
    process.exit(1);
  }
}

addSoftDelete();
