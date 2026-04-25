const db = require('./config/database');

async function addBookingStatus() {
  console.log('--- ĐANG NÂNG CẤP BẢNG ĐẶT SÂN ---');
  try {
    await db.query(`
      ALTER TABLE bookings 
      ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'Chờ duyệt';
    `);
    console.log('✅ Cài đặt trạng thái Đặt sân thành công!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
    process.exit(1);
  }
}

addBookingStatus();
