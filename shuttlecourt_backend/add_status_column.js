const db = require('./config/database');
db.query("ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active'")
  .then(() => { console.log('Column added'); process.exit(0); })
  .catch(e => { console.log('Error or already exists:', e.message); process.exit(0); });
