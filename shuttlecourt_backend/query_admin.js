const db = require('./config/database');
db.query("SELECT email FROM users WHERE role='admin'")
  .then(([res]) => { console.log(res); process.exit(0); })
  .catch(e => { console.error(e); process.exit(1); });
