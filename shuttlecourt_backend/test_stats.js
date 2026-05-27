const db = require('./config/database');
(async () => {
    try {
        const [[shopRevenue]] = await db.query("SELECT SUM(total_price) as total FROM product_orders WHERE status = 'Đã giao' OR status = 'Đã duyệt'");
        const [[bookingRevenue]] = await db.query("SELECT SUM(price) as total FROM bookings WHERE status = 'approved' OR status = 'paid'");
        console.log(shopRevenue, bookingRevenue);
        process.exit(0);
    } catch(e) {
        console.error(e);
        process.exit(1);
    }
})();
