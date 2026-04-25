const db = require('../config/database');

exports.getProducts = async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM products WHERE is_deleted = 0 ORDER BY created_at DESC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.addProduct = async (req, res) => {
  const { name, category, price, stock, image_url, description } = req.body;
  try {
    const [result] = await db.query(
      'INSERT INTO products (name, category, price, stock, image_url, description) VALUES (?, ?, ?, ?, ?, ?)',
      [name, category, price, stock, image_url, description]
    );
    res.status(201).json({ message: 'Thêm sản phẩm thành công', productId: result.insertId });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.updateProduct = async (req, res) => {
  const { id } = req.params;
  const { name, category, price, stock, image_url, description } = req.body;
  try {
    await db.query(
      'UPDATE products SET name = ?, category = ?, price = ?, stock = ?, image_url = ?, description = ? WHERE id = ?',
      [name, category, price, stock, image_url, description, id]
    );
    res.json({ message: 'Cập nhật sản phẩm thành công' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.deleteProduct = async (req, res) => {
  const { id } = req.params;
  try {
    await db.query('UPDATE products SET is_deleted = 1 WHERE id = ?', [id]);
    res.json({ message: 'Xóa sản phẩm thành công' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.getOrders = async (req, res) => {
  try {
    const sql = `
      SELECT o.*, u.full_name, u.phone, 
             GROUP_CONCAT(CONCAT(p.name, ' (x', oi.quantity, ')') SEPARATOR ', ') as items
      FROM product_orders o
      JOIN users u ON o.user_id = u.id
      JOIN product_order_items oi ON o.id = oi.order_id
      JOIN products p ON oi.product_id = p.id
      GROUP BY o.id
      ORDER BY o.created_at DESC
    `;
    const [rows] = await db.query(sql);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.updateOrderStatus = async (req, res) => {
  const { orderId } = req.params;
  const { status } = req.body;
  try {
    // 1. Cập nhật trạng thái
    await db.query('UPDATE product_orders SET status = ? WHERE id = ?', [status, orderId]);

    // 2. Lấy user_id để gửi thông báo cho khách hàng
    const [[order]] = await db.query('SELECT user_id, total_price FROM product_orders WHERE id = ?', [orderId]);
    
    if (order) {
      const icon = status === 'Đã duyệt' || status === 'Đã giao' ? '📦' : '❌';
      await db.query(
        "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
        [
          order.user_id,
          `${icon} Cập nhật đơn hàng`,
          `Đơn hàng trị giá ${order.total_price.toLocaleString()}đ của bạn đã được ${status.toLowerCase()}.`,
          "order_status"
        ]
      );
    }

    res.json({ message: 'Cập nhật trạng thái thành công' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
};

exports.placeOrder = async (req, res) => {
  const { userId, items, totalPrice, address, paymentMethod, discountCode, subtotal, discountAmount } = req.body;

  // LOG ĐỂ KIỂM TRA DỮ LIỆU NHẬN ĐƯỢC
  console.log('--- NHẬN ĐƠN HÀNG MỚI ---');
  console.log('User ID:', userId);
  console.log('Địa chỉ:', address);
  console.log('Thanh toán:', paymentMethod);

  const connection = await db.getConnection();
  try {
    await connection.beginTransaction();

    // 1. Tạo đơn hàng chính với các trường mở rộng
    const [orderRes] = await connection.query(
      'INSERT INTO product_orders (user_id, total_price, address, payment_method, discount_code, subtotal, discount_amount) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [userId, totalPrice, address, paymentMethod, discountCode, subtotal, discountAmount]
    );
    const orderId = orderRes.insertId;

    // 2. Thêm chi tiết từng món hàng
    for (const item of items) {
      await connection.query(
        'INSERT INTO product_order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
        [orderId, item.productId, item.quantity, item.price]
      );

      // 3. Giảm số lượng trong kho
      await connection.query(
        'UPDATE products SET stock = stock - ? WHERE id = ?',
        [item.quantity, item.productId]
      );
    }

    // 4. THÊM THÔNG BÁO CHO CHỦ SÂN (OWNER)
    const [owners] = await connection.query("SELECT id FROM users WHERE role = 'owner'");
    for (const owner of owners) {
      await connection.query(
        "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, ?)",
        [
          owner.id,
          "📦 Đơn hàng mới!",
          `Bạn nhận được đơn hàng mới giá trị ${totalPrice.toLocaleString()}đ từ khách hàng.`,
          "order"
        ]
      );
    }

    await connection.commit();
    res.status(201).json({ message: 'Đặt hàng thành công!', orderId });
  } catch (err) {
    await connection.rollback();
    res.status(500).json({ message: 'Lỗi khi đặt hàng', error: err.message });
  } finally {
    connection.release();
  }
};
