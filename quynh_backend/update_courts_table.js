const db = require('./config/database');

async function updateTable() {
    try {
        console.log('--- Updating courts table ---');
        
        // Add image columns
        await db.query(`ALTER TABLE courts ADD COLUMN IF NOT EXISTS main_image VARCHAR(255) DEFAULT NULL`);
        await db.query(`ALTER TABLE courts ADD COLUMN IF NOT EXISTS desc_image1 VARCHAR(255) DEFAULT NULL`);
        await db.query(`ALTER TABLE courts ADD COLUMN IF NOT EXISTS desc_image2 VARCHAR(255) DEFAULT NULL`);
        
        // Add status column for maintenance
        await db.query(`ALTER TABLE courts ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'active'`);
        
        console.log('✅ Courts table updated successfully');
        process.exit(0);
    } catch (err) {
        console.error('❌ Error updating table:', err);
        process.exit(1);
    }
}

updateTable();
