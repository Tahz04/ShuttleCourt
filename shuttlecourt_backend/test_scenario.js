const http = require('http');

const post = (path, data) => {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    };
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, body: JSON.parse(body) }));
    });
    req.on('error', reject);
    req.write(JSON.stringify(data));
    req.end();
  });
};

const get = (path) => {
  return new Promise((resolve, reject) => {
    http.get(`http://localhost:3000${path}`, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, body: JSON.parse(body) }));
    }).on('error', reject);
  });
};

async function runTestScript() {
  console.log('--- BẮT ĐẦU KIỂM THỬ KỊCH BẢN ĐẶT HÀNG ---');

  try {
    // 1. Thêm sản phẩm (Chủ sân)
    console.log('\n1. Chủ sân thêm sản phẩm mới...');
    const addProductRes = await post('/api/products/add', {
      name: 'Vợt Test Kịch Bản',
      category: 'Vợt',
      price: 1500000,
      stock: 10,
      description: 'Sản phẩm dùng để kiểm thử hệ thống'
    });
    console.log('Kết quả:', addProductRes.body.message);
    const productId = addProductRes.body.productId;

    // 2. Người dùng đặt hàng
    console.log('\n2. Người dùng đặt hàng (User ID: 1)...');
    const orderRes = await post('/api/products/order', {
      userId: 1, // Giả sử user id 1 tồn tại
      totalPrice: 1500000,
      items: [{ productId, quantity: 1, price: 1500000 }]
    });
    console.log('Kết quả:', orderRes.body.message, '- Order ID:', orderRes.body.orderId);
    const orderId = orderRes.body.orderId;

    // 3. Kiểm tra tồn kho sau khi đặt
    console.log('\n3. Kiểm tra tồn kho sản phẩm...');
    const products = await get('/api/products');
    const testProduct = products.body.find(p => p.id === productId);
    console.log(`Số lượng trong kho hiện tại: ${testProduct.stock} (Mong đợi: 9)`);

    // 4. Chủ sân xác nhận đơn hàng
    console.log('\n4. Chủ sân xác nhận hoàn tất đơn hàng...');
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: `/api/products/orders/${orderId}`,
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
    };
    const updateRes = await new Promise((resolve) => {
      const req = http.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => body += chunk);
        res.on('end', () => resolve(JSON.parse(body)));
      });
      req.write(JSON.stringify({ status: 'completed' }));
      req.end();
    });
    console.log('Kết quả:', updateRes.message);

    console.log('\n--- KỊCH BẢN KIỂM THỬ THÀNH CÔNG RỰC RỠ! ---');
  } catch (error) {
    console.error('\n❌ Lỗi trong quá trình kiểm thử:', error.message);
    console.log('Lưu ý: Đảm bảo bạn đã chạy SQL tạo bảng và trong bảng users có user với id = 1.');
  }
}

runTestScript();
