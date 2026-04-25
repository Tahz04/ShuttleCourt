const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');
const multer = require('multer');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ limit: '100mb', extended: true }));

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Serve uploaded files statically
app.use('/uploads', express.static(uploadDir));

// Multer storage config
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'court-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ 
    storage: storage,
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// Upload endpoint
app.post('/api/upload', upload.single('image'), (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }
        
        // Build URL dynamically based on request host to handle both localhost and IP
        const protocol = req.protocol;
        const host = req.get('host');
        const imageUrl = `${protocol}://${host}/uploads/${req.file.filename}`;
        
        console.log(`✅ File uploaded: ${req.file.filename} -> ${imageUrl}`);
        res.json({ imageUrl: imageUrl });
    } catch (error) {
        console.error('❌ Upload error:', error);
        res.status(500).json({ message: 'Internal server error during upload' });
    }
});

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

const reviewRoutes = require('./routes/reviewRoutes');
app.use('/api/reviews', reviewRoutes);

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`📁 Uploads directory: ${uploadDir}`);
});
