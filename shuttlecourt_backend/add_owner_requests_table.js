const db = require('./config/database');

async function addOwnerRequestsTable() {
  const sql = `
    CREATE TABLE IF NOT EXISTS owner_requests (
      id INT(11) NOT NULL AUTO_INCREMENT,
      user_id INT(11) NOT NULL,
      full_name VARCHAR(100) NOT NULL,
      id_number VARCHAR(30) NOT NULL,
      cccd_front TEXT NOT NULL,
      cccd_back TEXT NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'pending',
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      KEY user_id (user_id),
      KEY status (status),
      CONSTRAINT owner_requests_ibfk_1 FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
  `;

  await db.query(sql);
}

addOwnerRequestsTable()
  .then(() => {
    console.log('owner_requests table is ready.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Failed to create owner_requests table:', err);
    process.exit(1);
  });
