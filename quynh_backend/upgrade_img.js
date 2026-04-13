const db = require('./config/database');

async function upgradeProductsTable() {
  console.log('--- ĐANG NÂNG CẤP DUNG LƯỢNG LƯU TRỮ ẢNH ---');
  try {
    // Nâng cấp cột image_url lên LONGTEXT để chứa được ảnh lớn
    await db.query(`
      ALTER TABLE products 
      MODIFY COLUMN image_url LONGTEXT;
    `);
    
    console.log('✅ Nâng cấp dung lượng thành công!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Lỗi khi nâng cấp:', err.message);
    process.exit(1);
  }
}

upgradeProductsTable();
