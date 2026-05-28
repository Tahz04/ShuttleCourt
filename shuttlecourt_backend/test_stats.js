const db = require('./config/database');
(async () => {
    try {
        const [[shopRevenue]] = await db.query("SELECT SUM(total_price) as total FROM product_orders WHERE status = 'Đã giao' OR status = 'Đã duyệt' OR status = 'completed'");
        const [[bookingRevenue]] = await db.query("SELECT SUM(price) as total FROM bookings WHERE status = 'approved' OR status = 'paid' OR status = 'Đã duyệt' OR status = 'Đã thanh toán' OR status = 'Đã hoàn thành'");
        console.log(shopRevenue, bookingRevenue);
        process.exit(0);
    } catch(e) {
        console.error(e);
        process.exit(1);
    }
})();
