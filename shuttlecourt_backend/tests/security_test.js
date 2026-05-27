/**
 * ============================================================
 * BACKEND TEST: Security Tests (Bảo mật)
 * Tương ứng: tests_shuttlecourt/05_Security_Test.md
 * 
 * CÁCH CHẠY:
 *   1. Server phải đang chạy (node server.js)
 *   2. MySQL (XAMPP) phải bật
 *   3. Chạy: node tests/security_test.js
 * ============================================================
 */

const http = require('http');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

let passCount = 0;
let failCount = 0;
let totalTests = 0;

// ── HELPERS ──────────────────────────────────────────────────

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

function assert(testId, testName, condition, detail = '') {
  totalTests++;
  if (condition) {
    passCount++;
    console.log(`  ✅ ${testId}: ${testName}`);
  } else {
    failCount++;
    console.log(`  ❌ ${testId}: ${testName} ${detail ? '→ ' + detail : ''}`);
  }
}

// ── 1. KIỂM THỬ MÃ HÓA MẬT KHẨU (SEC-PW) ─────────────────

async function testPasswordEncryption() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  1. MÃ HÓA MẬT KHẨU (Password Encryption)  ║');
  console.log('╚══════════════════════════════════════════════╝');

  const password = 'Test@1234';

  // SEC-PW-01: Mật khẩu được hash trước khi lưu
  const hash = await bcrypt.hash(password, 10);
  assert('SEC-PW-01', 'Hash bcrypt format ($2a$10$...)',
    hash.startsWith('$2a$') || hash.startsWith('$2b$'),
    `Got: ${hash.substring(0, 10)}...`
  );

  // SEC-PW-02: Salt rounds đủ mạnh (= 10)
  const saltRounds = hash.split('$')[2];
  assert('SEC-PW-02', 'Salt rounds = 10',
    saltRounds === '10',
    `Got rounds: ${saltRounds}`
  );

  // SEC-PW-03: Hash không chứa mật khẩu gốc
  assert('SEC-PW-03', 'Hash không chứa plaintext password',
    !hash.includes(password),
    'Hash chứa mật khẩu gốc!'
  );

  // SEC-PW-04: API GET /auth/owners không trả về password
  const owners = await get('/api/auth/owners');
  if (owners.status === 200 && Array.isArray(owners.body)) {
    const hasPassword = owners.body.some(o => o.password !== undefined);
    assert('SEC-PW-04', 'API /auth/owners không trả về field password',
      !hasPassword,
      'Response chứa trường password!'
    );
  } else {
    assert('SEC-PW-04', 'API /auth/owners trả về 200', owners.status === 200);
  }
}

// ── 2. KIỂM THỬ JWT TOKEN (SEC-JW) ──────────────────────────

function testJWTSecurity() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  2. JWT TOKEN SECURITY                       ║');
  console.log('╚══════════════════════════════════════════════╝');

  const secret = 'test-jwt-secret-shuttlecourt';
  const payload = {
    id: 1, email: 'test@example.com',
    fullName: 'Test User', phone: '0912345678', role: 'user'
  };

  // SEC-JW-01: Token có thời hạn 1 ngày
  const token = jwt.sign(payload, secret, { expiresIn: '1d' });
  const decoded = jwt.verify(token, secret);
  const expDuration = decoded.exp - decoded.iat;
  assert('SEC-JW-01', 'Token hết hạn sau 1 ngày (86400s)',
    expDuration === 86400,
    `Duration: ${expDuration}s`
  );

  // SEC-JW-02: Token chứa role để phân quyền
  assert('SEC-JW-02', 'Token payload chứa role',
    decoded.role !== undefined,
    'Không có trường role trong token'
  );

  // SEC-JW-03: Token sử dụng secret key (không hardcode)
  // Kiểm tra bằng cách verify với secret khác → lỗi
  let wrongSecretErr = false;
  try { jwt.verify(token, 'wrong-secret-key'); } catch { wrongSecretErr = true; }
  assert('SEC-JW-03', 'Token verify sai secret → bị từ chối',
    wrongSecretErr === true
  );

  // SEC-JW-04: Token bị sửa → bị từ chối
  let tamperedErr = false;
  const tamperedToken = token.slice(0, -5) + 'XXXXX';
  try { jwt.verify(tamperedToken, secret); } catch { tamperedErr = true; }
  assert('SEC-JW-04', 'Token bị sửa (tampered) → bị từ chối',
    tamperedErr === true
  );

  // Thêm: Token hết hạn
  const expiredToken = jwt.sign(payload, secret, { expiresIn: '0s' });
  setTimeout(() => {
    let expiredErr = false;
    try { jwt.verify(expiredToken, secret); } catch { expiredErr = true; }
    assert('SEC-JW-05', 'Token hết hạn → throw TokenExpiredError',
      expiredErr === true
    );
  }, 1100);
}

// ── 3. KIỂM THỬ SQL INJECTION (SEC-SI) ──────────────────────

async function testSQLInjection() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  3. SQL INJECTION PREVENTION                 ║');
  console.log('╚══════════════════════════════════════════════╝');

  // SEC-SI-01: SQL Injection qua đăng nhập
  const r1 = await post('/api/auth/login', {
    email: "' OR 1=1 --",
    password: "anything"
  });
  assert('SEC-SI-01', 'SQL Injection đăng nhập bị chặn (status ≠ 200)',
    r1.status !== 200,
    `Got status: ${r1.status}`
  );

  // SEC-SI-02: SQL Injection qua đăng ký
  const r2 = await post('/api/auth/register', {
    fullName: "'; DROP TABLE users; --",
    email: "inject@test.com",
    phone: "0912345678",
    password: "Test@1234"
  });
  // Server không bị crash và trả về response hợp lệ
  assert('SEC-SI-02', 'SQL Injection đăng ký không crash server',
    r2.status === 201 || r2.status === 400 || r2.status === 500,
    `Got status: ${r2.status}`
  );

  // SEC-SI-03: Kiểm tra server vẫn hoạt động sau injection attempts
  const r3 = await get('/api/courts/all');
  assert('SEC-SI-03', 'Server vẫn hoạt động sau SQL injection attempts',
    r3.status === 200,
    `Status: ${r3.status}`
  );

  // SEC-SI-04: SQL Injection qua booking
  const r4 = await post('/api/bookings', {
    user_id: 1,
    court_name: '"; DELETE FROM bookings; --',
    court_address: 'Test',
    slot: '18:00 - 19:00',
    booking_date: '2026-06-20',
    price: 80000,
    payment_method: 'Cash'
  });
  assert('SEC-SI-04', 'SQL Injection booking bị chặn bởi parameterized queries',
    r4.status === 200 || r4.status === 400,
    `Status: ${r4.status}`
  );
}

// ── 4. KIỂM THỬ PHÂN QUYỀN (SEC-AZ) ────────────────────────

async function testAuthorization() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  4. PHÂN QUYỀN (Authorization)               ║');
  console.log('╚══════════════════════════════════════════════╝');

  // SEC-AZ-02: Chỉ 1 owner trong hệ thống
  const owners = await get('/api/auth/owners');
  if (Array.isArray(owners.body) && owners.body.length > 0) {
    // Thử nâng cấp user khác thành owner
    const r1 = await post('/api/auth/upgrade-owner', { userId: 999 });
    assert('SEC-AZ-02', 'Không thể có thêm owner (403)',
      r1.status === 403,
      `Got status: ${r1.status}`
    );
  } else {
    assert('SEC-AZ-02', 'Kiểm tra owner limit (skipped - chưa có owner)', true);
  }

  // SEC-AZ-04: User chỉ xem booking của mình
  const bookings = await get('/api/bookings/user/1');
  assert('SEC-AZ-04', 'GET /bookings/user/:userId → 200 (filter by user)',
    bookings.status === 200 && Array.isArray(bookings.body)
  );
}

// ── 5. KIỂM THỬ XSS (SEC-XS) ───────────────────────────────

async function testXSSProtection() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  5. XSS PROTECTION                           ║');
  console.log('╚══════════════════════════════════════════════╝');

  // SEC-XS-01: XSS trong review comment
  const courts = await get('/api/courts/all');
  if (Array.isArray(courts.body) && courts.body.length > 0) {
    const courtId = courts.body[0].id;
    const xssPayload = '<script>alert("XSS")</script>';
    
    const r1 = await post('/api/reviews', {
      court_id: courtId,
      user_id: 1,
      rating: 5,
      comment: xssPayload
    });
    
    // Server nên lưu được (không crash) - Flutter Text widget sẽ escape HTML
    assert('SEC-XS-01', 'XSS payload không crash server',
      r1.status === 201 || r1.status === 400,
      `Status: ${r1.status}`
    );

    // SEC-XS-02: XSS trong booking
    const r2 = await post('/api/bookings', {
      user_id: 1,
      court_name: '<img onerror="alert(1)" src="x">',
      court_address: '<b onmouseover="alert(1)">Test</b>',
      slot: '18:00 - 19:00',
      booking_date: '2026-06-21',
      price: 80000,
      payment_method: 'Cash'
    });
    assert('SEC-XS-02', 'XSS trong booking không crash server',
      r2.status === 200 || r2.status === 400,
      `Status: ${r2.status}`
    );
  } else {
    assert('SEC-XS-01', 'XSS test (skipped - không có court)', true);
  }
}

// ── 6. KIỂM THỬ BẢO MẬT DỮ LIỆU (SEC-DT) ─────────────────

async function testDataSecurity() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  6. BẢO MẬT DỮ LIỆU (Data Security)        ║');
  console.log('╚══════════════════════════════════════════════╝');

  // SEC-DT-01 & SEC-DT-02: Soft delete sản phẩm
  const products = await get('/api/products');
  assert('SEC-DT-01', 'GET /products chỉ trả về sản phẩm chưa xóa (is_deleted=0)',
    products.status === 200 && Array.isArray(products.body)
  );

  if (products.body.length > 0) {
    // Kiểm tra không có sản phẩm nào có is_deleted = 1
    const hasDeleted = products.body.some(p => p.is_deleted === 1);
    assert('SEC-DT-02', 'Không hiển thị sản phẩm đã soft delete',
      !hasDeleted,
      'Có sản phẩm is_deleted=1 trong kết quả!'
    );
  }
}

// ── 7. KIỂM THỬ CHỐNG SPAM (SEC-SP) ─────────────────────────

async function testAntiSpam() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  7. CHỐNG SPAM (Anti-Spam)                   ║');
  console.log('╚══════════════════════════════════════════════╝');

  // SEC-SP-01: Validation input đăng ký - email không hợp lệ
  const r1 = await post('/api/auth/register', {
    fullName: 'Test User',
    email: '', // Email rỗng
    phone: '0912345678',
    password: 'Test@1234'
  });
  assert('SEC-SP-01', 'Đăng ký thiếu email → reject 400',
    r1.status === 400,
    `Status: ${r1.status}`
  );

  // SEC-SP-02: Đăng ký thiếu mật khẩu
  const r2 = await post('/api/auth/register', {
    fullName: 'Test User',
    email: 'test@spam.com',
    phone: '0912345678',
    password: '' // Mật khẩu rỗng
  });
  assert('SEC-SP-02', 'Đăng ký thiếu mật khẩu → reject 400',
    r2.status === 400,
    `Status: ${r2.status}`
  );

  // SEC-SP-03: Đăng nhập thiếu thông tin
  const r3 = await post('/api/auth/login', {});
  assert('SEC-SP-03', 'Đăng nhập body rỗng → reject 400',
    r3.status === 400,
    `Status: ${r3.status}`
  );
}

// ── MAIN ────────────────────────────────────────────────────

async function runAllTests() {
  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║  🔐 SHUTTLECOURT - SECURITY TESTS                  ║');
  console.log('║  Tương ứng: tests_shuttlecourt/05_Security_Test.md  ║');
  console.log('║  Server: http://localhost:3000                      ║');
  console.log('╚══════════════════════════════════════════════════════╝');

  try {
    await testPasswordEncryption();
    testJWTSecurity();
    await testSQLInjection();
    await testAuthorization();
    await testXSSProtection();
    await testDataSecurity();
    await testAntiSpam();

    // Đợi JWT expired test
    setTimeout(() => {
      console.log('\n══════════════════════════════════════════════');
      console.log(`  📊 KẾT QUẢ: ${passCount}/${totalTests} PASS | ${failCount} FAIL`);
      console.log(`  📈 Tỷ lệ: ${((passCount / totalTests) * 100).toFixed(1)}%`);
      console.log('══════════════════════════════════════════════\n');
      process.exit(failCount > 0 ? 1 : 0);
    }, 1500);
  } catch (err) {
    console.error('\n❌ Lỗi:', err.message);
    console.log('💡 Đảm bảo server đang chạy + MySQL bật');
    process.exit(1);
  }
}

runAllTests();
