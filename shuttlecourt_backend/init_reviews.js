const db = require('./config/database');

async function createReviewsTable() {
    try {
        const query = `
            CREATE TABLE IF NOT EXISTS reviews (
                id INT AUTO_INCREMENT PRIMARY KEY,
                court_id INT NOT NULL,
                user_id INT NOT NULL,
                booking_id INT,
                rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
                comment TEXT,
                photos JSON,
                owner_reply TEXT,
                owner_reply_at TIMESTAMP NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (court_id) REFERENCES courts(id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        `;
        
        await db.execute(query);
        console.log("✅ Reviews table created or already exists.");

        // Add columns if they don't exist
        try { await db.execute("ALTER TABLE reviews ADD COLUMN IF NOT EXISTS owner_reply TEXT"); } catch (e) {}
        try { await db.execute("ALTER TABLE reviews ADD COLUMN IF NOT EXISTS owner_reply_at TIMESTAMP NULL"); } catch (e) {}
        
        console.log("✅ Columns owner_reply and owner_reply_at ensure.");
        process.exit(0);
    } catch (error) {
        console.error("❌ Error creating/updating reviews table:", error);
        process.exit(1);
    }
}

createReviewsTable();
