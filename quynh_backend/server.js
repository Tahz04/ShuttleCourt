const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

const authRoutes = require('./routes/authRoutes');
app.use('/api/auth', authRoutes);

const bookingRoutes = require('./routes/bookingRoutes');
app.use('/api/bookings', bookingRoutes);

const courtRoutes = require('./routes/courtRoutes');
app.use('/api/courts', courtRoutes);

const matchmakingRoutes = require('./routes/matchmakingRoutes');
app.use('/api/matchmaking', matchmakingRoutes);


const productRoutes = require('./routes/productRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
app.use('/api/products', productRoutes);
app.use('/api/notifications', notificationRoutes);

const ownerRequestRoutes = require('./routes/ownerRequestRoutes');
app.use('/api/owner-requests', ownerRequestRoutes);

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

