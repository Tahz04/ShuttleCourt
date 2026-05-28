const db = require('./config/database');

async function addReviewReportsTable() {
  const sql = `
    CREATE TABLE IF NOT EXISTS review_reports (
      id INT(11) NOT NULL AUTO_INCREMENT,
      review_id INT(11) NOT NULL,
      owner_id INT(11) NOT NULL,
      reason TEXT DEFAULT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'pending',
      action VARCHAR(20) DEFAULT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      resolved_at TIMESTAMP NULL DEFAULT NULL,
      resolved_by INT(11) DEFAULT NULL,
      PRIMARY KEY (id),
      KEY review_id (review_id),
      KEY owner_id (owner_id),
      KEY status (status),
      KEY resolved_by (resolved_by),
      CONSTRAINT review_reports_ibfk_1 FOREIGN KEY (review_id)
        REFERENCES reviews (id)
        ON DELETE CASCADE,
      CONSTRAINT review_reports_ibfk_2 FOREIGN KEY (owner_id)
        REFERENCES users (id)
        ON DELETE CASCADE,
      CONSTRAINT review_reports_ibfk_3 FOREIGN KEY (resolved_by)
        REFERENCES users (id)
        ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `;

  await db.query(sql);
}

addReviewReportsTable()
  .then(() => {
    console.log('review_reports table is ready.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Failed to create review_reports table:', err);
    process.exit(1);
  });
