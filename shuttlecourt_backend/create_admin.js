const db = require('./config/database');
const bcrypt = require('bcryptjs');
(async () => {
    const hash = await bcrypt.hash('123456', 10);
    const sql = `INSERT INTO users (full_name, email, phone, password, role) VALUES ('Admin', 'admin@gmail.com', '0123456789', ?, 'admin') ON DUPLICATE KEY UPDATE role='admin', password=?`;
    await db.query(sql, [hash, hash]);
    console.log('Admin account created/updated: admin@gmail.com / 123456');
    process.exit(0);
})();
