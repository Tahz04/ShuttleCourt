/**
 * ============================================================
 * BACKEND TEST: Algorithm & Flow Tests
 * Test thuật toán nội bộ (bcrypt, JWT, validation, transaction)
 * 
 * CÁCH CHẠY: node tests/algorithm_test.js
 * ============================================================
 */

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

let passCount = 0;
let failCount = 0;
let totalTests = 0;

function assert(testName, condition, detail = '') {
  totalTests++;
  if (condition) {
    passCount++;
    console.log(`  ✅ PASS: ${testName}`);
  } else {
    failCount++;
    console.log(`  ❌ FAIL: ${testName} ${detail ? '→ ' + detail : ''}`);
  }
}

// ── 1. BCRYPT HASH TESTS ─────────────────────────────────────

async function testBcrypt() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  1. BCRYPT HASH ALGORITHM TESTS              ║');
  console.log('╚══════════════════════════════════════════════╝');

  const password = 'Test@1234';

  // Test: Hash tạo ra chuỗi đúng format
  const hash = await bcrypt.hash(password, 10);
  assert('Hash trả về chuỗi', typeof hash === 'string');
  assert('Hash bắt đầu bằng $2a$ hoặc $2b$', hash.startsWith('$2a$') || hash.startsWith('$2b$'));
  assert('Hash dài 60 ký tự', hash.length === 60);

  // Test: 2 hash khác nhau cho cùng input (random salt)
  const hash2 = await bcrypt.hash(password, 10);
  assert('2 hash khác nhau cho cùng password', hash !== hash2);

  // Test: Compare đúng
  const match = await bcrypt.compare(password, hash);
  assert('bcrypt.compare(đúng) → true', match === true);

  // Test: Compare sai
  const noMatch = await bcrypt.compare('WrongPassword', hash);
  assert('bcrypt.compare(sai) → false', noMatch === false);

  // Test: Compare rỗng
  const emptyMatch = await bcrypt.compare('', hash);
  assert('bcrypt.compare(rỗng) → false', emptyMatch === false);

  // Test: Salt rounds ảnh hưởng thời gian
  const start = Date.now();
  await bcrypt.hash(password, 10);
  const duration = Date.now() - start;
  assert('Hash hoàn thành trong < 2000ms', duration < 2000, `${duration}ms`);
}

// ── 2. JWT TOKEN TESTS ──────────────────────────────────────

function testJWT() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  2. JWT TOKEN ALGORITHM TESTS                ║');
  console.log('╚══════════════════════════════════════════════╝');

  const secret = 'test-secret-key-for-shuttlecourt';
  const payload = {
    id: 1,
    email: 'test@example.com',
    fullName: 'Nguyễn Văn Test',
    phone: '0912345678',
    role: 'user',
  };

  // Test: Tạo token
  const token = jwt.sign(payload, secret, { expiresIn: '1d' });
  assert('Token là string', typeof token === 'string');
  assert('Token có 3 phần (xxx.yyy.zzz)', token.split('.').length === 3);

  // Test: Decode payload
  const decoded = jwt.verify(token, secret);
  assert('Decoded chứa id', decoded.id === 1);
  assert('Decoded chứa email', decoded.email === 'test@example.com');
  assert('Decoded chứa fullName', decoded.fullName === 'Nguyễn Văn Test');
  assert('Decoded chứa phone', decoded.phone === '0912345678');
  assert('Decoded chứa role', decoded.role === 'user');
  assert('Decoded có exp (expiration)', decoded.exp !== undefined);
  assert('Decoded có iat (issued at)', decoded.iat !== undefined);

  // Test: Token role = owner
  const ownerPayload = { ...payload, role: 'owner' };
  const ownerToken = jwt.sign(ownerPayload, secret, { expiresIn: '1d' });
  const ownerDecoded = jwt.verify(ownerToken, secret);
  assert('Owner token có role = owner', ownerDecoded.role === 'owner');

  // Test: Token sai secret → lỗi
  let invalidErr = false;
  try { jwt.verify(token, 'wrong-secret'); } catch { invalidErr = true; }
  assert('Token verify sai secret → throw error', invalidErr === true);

  // Test: Token bị sửa → lỗi
  let tamperedErr = false;
  try { jwt.verify(token + 'x', secret); } catch { tamperedErr = true; }
  assert('Token bị sửa → throw error', tamperedErr === true);

  // Test: Token hết hạn
  const expiredToken = jwt.sign(payload, secret, { expiresIn: '0s' });
  let expiredErr = false;
  // Đợi 1 giây để token hết hạn
  setTimeout(() => {
    try { jwt.verify(expiredToken, secret); } catch { expiredErr = true; }
    assert('Token hết hạn → throw error', expiredErr === true);
  }, 1100);
}

// ── 3. AVERAGE RATING ALGORITHM ──────────────────────────────

function testAverageRating() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  3. AVERAGE RATING ALGORITHM TESTS           ║');
  console.log('╚══════════════════════════════════════════════╝');

  function calcAverage(reviews) {
    if (reviews.length === 0) return 0;
    const sum = reviews.reduce((acc, r) => acc + r.rating, 0);
    return parseFloat((sum / reviews.length).toFixed(1));
  }

  assert('[5,4,3,2,1] → 3.0', calcAverage([{rating:5},{rating:4},{rating:3},{rating:2},{rating:1}]) === 3.0);
  assert('[5,5,5,5] → 5.0', calcAverage([{rating:5},{rating:5},{rating:5},{rating:5}]) === 5.0);
  assert('[1] → 1.0', calcAverage([{rating:1}]) === 1.0);
  assert('[4,5,3,4,5] → 4.2', calcAverage([{rating:4},{rating:5},{rating:3},{rating:4},{rating:5}]) === 4.2);
  assert('[] → 0', calcAverage([]) === 0);
  assert('[3,3,4] → 3.3', calcAverage([{rating:3},{rating:3},{rating:4}]) === 3.3);
}

// ── 4. CAPACITY CHECK ALGORITHM ──────────────────────────────

function testCapacityCheck() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  4. CAPACITY CHECK ALGORITHM TESTS           ║');
  console.log('╚══════════════════════════════════════════════╝');

  function canJoin(joinedCount, capacity) {
    return joinedCount < capacity;
  }

  assert('capacity=4, joined=0 → có thể join', canJoin(0, 4) === true);
  assert('capacity=4, joined=3 → có thể join', canJoin(3, 4) === true);
  assert('capacity=4, joined=4 → KHÔNG thể join', canJoin(4, 4) === false);
  assert('capacity=2, joined=2 → KHÔNG thể join', canJoin(2, 2) === false);
  assert('capacity=10, joined=5 → có thể join', canJoin(5, 10) === true);
}

// ── 5. INPUT VALIDATION ALGORITHM ────────────────────────────

function testInputValidation() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  5. INPUT VALIDATION ALGORITHM TESTS         ║');
  console.log('╚══════════════════════════════════════════════╝');

  // Simulate backend validation
  function validateBookingInput(data) {
    const { user_id, court_name, court_address, slot, booking_date, price, payment_method } = data;
    if (!user_id || !court_name || !court_address || !slot || !booking_date || !price || !payment_method) {
      return false;
    }
    return true;
  }

  assert('Booking đầy đủ fields → valid', validateBookingInput({
    user_id: 1, court_name: 'Test', court_address: 'Addr',
    slot: '18:00', booking_date: '2026-05-28', price: 80000, payment_method: 'Cash'
  }) === true);

  assert('Booking thiếu user_id → invalid', validateBookingInput({
    court_name: 'Test', court_address: 'Addr',
    slot: '18:00', booking_date: '2026-05-28', price: 80000, payment_method: 'Cash'
  }) === false);

  assert('Booking thiếu court_name → invalid', validateBookingInput({
    user_id: 1, court_address: 'Addr',
    slot: '18:00', booking_date: '2026-05-28', price: 80000, payment_method: 'Cash'
  }) === false);

  assert('Booking rỗng → invalid', validateBookingInput({}) === false);

  // Match validation
  function validateMatchInput(data) {
    const { hostId, courtName, level, matchDate, startTime, capacity, price } = data;
    if (!hostId || !courtName || !level || !matchDate || !startTime || !capacity || !price) return false;
    return true;
  }

  assert('Match đầy đủ → valid', validateMatchInput({
    hostId: 1, courtName: 'Test', level: 'TB', matchDate: '2026-06-01',
    startTime: '18:00', capacity: 4, price: 50000
  }) === true);

  assert('Match thiếu hostId → invalid', validateMatchInput({
    courtName: 'Test', level: 'TB', matchDate: '2026-06-01',
    startTime: '18:00', capacity: 4, price: 50000
  }) === false);
}

// ── 6. SEARCH FILTER ALGORITHM ───────────────────────────────

function testSearchFilter() {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║  6. SEARCH FILTER ALGORITHM TESTS            ║');
  console.log('╚══════════════════════════════════════════════╝');

  const courts = [
    { name: 'Duy Hung Badminton Center', address: 'Cầu Giấy, Hà Nội' },
    { name: 'JQK Badminton', address: 'Thanh Trì, Hà Nội' },
    { name: 'Sân Minh Khai', address: 'Hai Bà Trưng, Hà Nội' },
    { name: 'Royal City Court', address: 'Royal City' },
  ];

  function search(query) {
    const q = query.toLowerCase();
    return courts.filter(c =>
      c.name.toLowerCase().includes(q) || c.address.toLowerCase().includes(q)
    );
  }

  assert('Tìm "" → tất cả sân', search('').length === 4);
  assert('Tìm "Duy Hung" → 1 sân', search('Duy Hung').length === 1);
  assert('Tìm "duy hung" (lowercase) → 1 sân', search('duy hung').length === 1);
  assert('Tìm "Hà Nội" → 3 sân', search('Hà Nội').length === 3);
  assert('Tìm "xyzabc" → 0 sân', search('xyzabc').length === 0);
  assert('Tìm "Badminton" → 2 sân', search('Badminton').length === 2);
  assert('Tìm "Court" → 1 sân', search('Court').length === 1);
}

// ── MAIN ────────────────────────────────────────────────────

async function runAllTests() {
  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║  🧮 SHUTTLECOURT - ALGORITHM & LOGIC TESTS         ║');
  console.log('╚══════════════════════════════════════════════════════╝');

  await testBcrypt();
  testJWT();
  testAverageRating();
  testCapacityCheck();
  testInputValidation();
  testSearchFilter();

  // Đợi JWT expired test
  setTimeout(() => {
    console.log('\n══════════════════════════════════════════════');
    console.log(`  📊 KẾT QUẢ: ${passCount}/${totalTests} PASS | ${failCount} FAIL`);
    console.log(`  📈 Tỷ lệ: ${((passCount / totalTests) * 100).toFixed(1)}%`);
    console.log('══════════════════════════════════════════════\n');
    process.exit(failCount > 0 ? 1 : 0);
  }, 1500);
}

runAllTests();
