const db = require('./config/database');
db.query("SELECT full_name, email, phone FROM users WHERE role='owner'")
  .then(([res]) => { console.log(JSON.stringify(res, null, 2)); process.exit(0); })
  .catch(e => { console.error(e); process.exit(1); });
