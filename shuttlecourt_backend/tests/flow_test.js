/**
 * ============================================================
 * BACKEND TEST: Booking & Shop Flow Test
 * Test luồng đặt sân + mua hàng end-to-end
 * 
 * CÁCH CHẠY:
 *   1. Server phải đang chạy (node server.js)
 *   2. MySQL (XAMPP) phải bật, có user id=1
 *   3. Chạy: node tests/flow_test.js
 * ============================================================
 */

const http = require('http');

let passCount = 0;
let failCount = 0;
let totalTests = 0;

function post(path, data) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(data);
    const options = {
      hostname: 'localhost', port: 3000, path, method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    };
    const req = http.request(options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => responseBody += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(responseBody) }); }
        catch { resolve({ status: res.statusCode, body: responseBody }); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function get(path) {
  return new Promise((resolve, reject) => {
    http.get(`http://localhost:3000${path}`, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(body) }); }
        catch { resolve({ status: res.statusCode, body }); }
      });
    }).on('error', reject);
  });
}

function put(path, data) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(data);
    const options = {
      hostname: 'localhost', port: 3000, path, method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    };
    const req = http.request(options, (res) => {
      let rb = '';
      res.on('data', (chunk) => rb += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(rb) }); }
        catch { resolve({ status: res.statusCode, body: rb }); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function assert(testName, condition, detail = '') {
  totalTests++;
  if (condition) {
    passCount++;
    console.log(`  ✅ ${testName}`);
  } else {
    failCount++;
    console.log(`  ❌ ${testName} ${detail ? '→ ' + detail : ''}`);
  }
}

// ── FLOW 1: ĐẶT SÂN END-TO-END ──────────────────────────────

async function testBookingFlow() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  FLOW 1: ĐẶT SÂN CẦU LÔNG                  ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Bước 1: Lấy danh sách sân
  console.log('\n  📌 Bước 1: Lấy danh sách sân');
  const courts = await get('/api/courts/all');
  assert('API trả về 200', courts.status === 200);
  assert('Có danh sách sân', Array.isArray(courts.body) && courts.body.length > 0);

  if (courts.body.length === 0) {
    console.log('  ⚠️ Không có sân nào trong DB, bỏ qua flow test');
    return;
  }

  const court = courts.body[0];
  console.log(`  📍 Chọn sân: ${court.name}`);

  // Bước 2: Tạo booking
  console.log('\n  📌 Bước 2: Tạo booking');
  const randomDay = Math.floor(Math.random() * 28) + 1;
  const randomMonth = Math.floor(Math.random() * 5) + 7; // Month 7 to 11
  const bookingDate = `2026-${randomMonth.toString().padStart(2, '0')}-${randomDay.toString().padStart(2, '0')}`;

  const bookingData = {
    user_id: 1,
    court_name: court.name,
    court_address: court.address,
    slot: '18:00 - 19:00',
    booking_date: bookingDate,
    price: court.price_per_hour || 80000,
    payment_method: 'Tiền mặt',
  };

  const bookRes = await post('/api/bookings', bookingData);
  console.log("  [DEBUG] bookRes:", JSON.stringify(bookRes));
  assert('Booking tạo thành công (200)', bookRes.status === 200);
  assert('Trả về booking ID', bookRes.body && bookRes.body.id !== undefined);

  const bookingId = bookRes.body.id;
  console.log(`  🎫 Booking ID: ${bookingId}`);

  // Bước 3: Kiểm tra booking trong lịch sử
  console.log('\n  📌 Bước 3: Kiểm tra lịch sử booking');
  const history = await get('/api/bookings/user/1');
  assert('Lấy lịch sử booking thành công', history.status === 200);
  const foundBooking = history.body.find(b => b.id === bookingId);
  assert('Booking mới có trong lịch sử', foundBooking !== undefined);

  if (foundBooking) {
    assert('Court name khớp', foundBooking.court_name === court.name);
    assert('Slot khớp', foundBooking.slot === '18:00 - 19:00');
    assert('Status mặc định "Chờ duyệt"', foundBooking.status === 'Chờ duyệt');
  }

  // Bước 4: Owner duyệt booking
  console.log('\n  📌 Bước 4: Owner duyệt booking');
  const approveRes = await put(`/api/bookings/${bookingId}/status`, { status: 'Đã duyệt' });
  assert('Duyệt booking thành công', approveRes.status === 200);

  // Bước 5: Kiểm tra status đã cập nhật
  console.log('\n  📌 Bước 5: Kiểm tra status');
  const updated = await get('/api/bookings/user/1');
  const updatedBooking = updated.body.find(b => b.id === bookingId);
  assert('Status đã chuyển thành "Đã duyệt"', updatedBooking && updatedBooking.status === 'Đã duyệt');
}

// ── FLOW 2: MUA HÀNG SHOP ────────────────────────────────────

async function testShopFlow() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  FLOW 2: MUA HÀNG SHOP                       ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Bước 1: Lấy danh sách sản phẩm
  console.log('\n  📌 Bước 1: Lấy danh sách sản phẩm');
  const products = await get('/api/products');
  assert('API trả về 200', products.status === 200);

  if (!Array.isArray(products.body) || products.body.length === 0) {
    console.log('  ⚠️ Không có sản phẩm, tạo sản phẩm test...');
    const addRes = await post('/api/products/add', {
      name: 'Vợt Test Flow', category: 'Vợt',
      price: 500000, stock: 20, description: 'Test flow'
    });
    assert('Thêm sản phẩm test thành công', addRes.status === 201);
  }

  // Lấy lại danh sách
  const refreshed = await get('/api/products');
  if (refreshed.body.length === 0) {
    console.log('  ⚠️ Vẫn không có sản phẩm, bỏ qua');
    return;
  }

  const product = refreshed.body[0];
  const stockBefore = product.stock;
  console.log(`  📦 Sản phẩm: ${product.name} (Stock: ${stockBefore})`);

  // Bước 2: Đặt hàng
  console.log('\n  📌 Bước 2: Đặt hàng');
  const orderRes = await post('/api/products/order', {
    userId: 1,
    items: [{ productId: product.id, quantity: 1, price: product.price }],
    totalPrice: product.price,
    address: 'Hà Nội',
    paymentMethod: 'Tiền mặt',
  });
  assert('Đặt hàng thành công (201)', orderRes.status === 201);
  assert('Trả về order ID', orderRes.body.orderId !== undefined);

  // Bước 3: Kiểm tra stock giảm
  console.log('\n  📌 Bước 3: Kiểm tra tồn kho');
  const afterOrder = await get('/api/products');
  const updatedProduct = afterOrder.body.find(p => p.id === product.id);
  if (updatedProduct) {
    assert(`Stock giảm từ ${stockBefore} → ${updatedProduct.stock}`, updatedProduct.stock === stockBefore - 1);
  }
}

// ── FLOW 3: ĐÁNH GIÁ SÂN ────────────────────────────────────

async function testReviewFlow() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  FLOW 3: ĐÁNH GIÁ SÂN                        ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Lấy court đầu tiên
  const courts = await get('/api/courts/all');
  if (courts.body.length === 0) {
    console.log('  ⚠️ Không có sân, bỏ qua');
    return;
  }
  const courtId = courts.body[0].id;

  // Bước 1: Tạo review
  console.log('\n  📌 Bước 1: User viết đánh giá');
  const reviewRes = await post('/api/reviews', {
    court_id: courtId, user_id: 1, rating: 5,
    comment: 'Sân rất đẹp, dịch vụ tốt!',
  });
  assert('Tạo review thành công (201)', reviewRes.status === 201);

  // Bước 2: Kiểm tra review xuất hiện
  console.log('\n  📌 Bước 2: Kiểm tra review');
  const reviews = await get(`/api/reviews/court/${courtId}`);
  assert('Lấy reviews thành công', reviews.status === 200);
  assert('Có reviews trong danh sách', reviews.body.reviews && reviews.body.reviews.length > 0);
  assert('Có averageRating', reviews.body.averageRating !== undefined);
  assert('Có total count', reviews.body.total !== undefined);
}

// ── MAIN ────────────────────────────────────────────────────

async function runAllTests() {
  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║  🔄 SHUTTLECOURT - FLOW INTEGRATION TESTS          ║');
  console.log('║  Server: http://localhost:3000                      ║');
  console.log('╚══════════════════════════════════════════════════════╝');

  try {
    await testBookingFlow();
    await testShopFlow();
    await testReviewFlow();

    console.log('\n══════════════════════════════════════════════');
    console.log(`  📊 KẾT QUẢ: ${passCount}/${totalTests} PASS | ${failCount} FAIL`);
    console.log(`  📈 Tỷ lệ: ${((passCount / totalTests) * 100).toFixed(1)}%`);
    console.log('══════════════════════════════════════════════\n');

    process.exit(failCount > 0 ? 1 : 0);
  } catch (err) {
    console.error('\n❌ Lỗi:', err.message);
    console.log('💡 Đảm bảo server đang chạy + MySQL bật + có user id=1');
    process.exit(1);
  }
}

runAllTests();
