const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');
const multer = require('multer');

dotenv.config();

// Khởi tạo các cron jobs chạy ngầm (ví dụ: tự động xóa đơn cũ qua ngày)
require('./services/cronJob');

const app = express();
const http = require('http');
const { Server } = require('socket.io');

const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: '*', // Allows connections from any origin (Flutter apps)
        methods: ["GET", "POST"]
    }
});

// Setup DB Socket.IO hooks
const db = require('./config/database');
db.setIo(io);

io.on('connection', (socket) => {
    console.log('🔗 New socket connected:', socket.id);
    
    // Join a room for a specific court's bookings
    socket.on('join_court', (courtName) => {
        socket.join(courtName);
        console.log(`Socket ${socket.id} joined room: ${courtName}`);
    });

    // Join a user-specific room for notifications
    socket.on('join_user', (userId) => {
        socket.join(`user_${userId}`);
        console.log(`Socket ${socket.id} joined user room: user_${userId}`);
    });

    socket.on('disconnect', () => {
        console.log('🔌 Socket disconnected:', socket.id);
    });
});

// Attach io to req object for controllers to use
app.use((req, res, next) => {
    req.io = io;
    next();
});

// Middleware to dynamically fix localhost image URLs for mobile devices
app.use((req, res, next) => {
    const originalJson = res.json;
    res.json = function (obj) {
        const host = req.get('host');
        if (host && host !== 'localhost:3000' && obj) {
            const replaceLocalhost = (data) => {
                if (typeof data === 'string') {
                    return data.replace(/localhost:3000/g, host);
                } else if (Array.isArray(data)) {
                    return data.map(replaceLocalhost);
                } else if (data !== null && typeof data === 'object') {
                    const newObj = {};
                    for (const key in data) {
                        if (Object.prototype.hasOwnProperty.call(data, key)) {
                            newObj[key] = replaceLocalhost(data[key]);
                        }
                    }
                    return newObj;
                }
                return data;
            };
            try {
                obj = replaceLocalhost(obj);
            } catch (e) {
                console.error('Error replacing localhost in JSON:', e);
            }
        }
        return originalJson.call(this, obj);
    };
    next();
});

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
const ownerRequestRoutes = require('./routes/ownerRequestRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const adminRoutes = require('./routes/adminRoutes');

app.use('/api/products', productRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/owner-requests', ownerRequestRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/admin', adminRoutes);

const PORT = 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`📁 Uploads directory: ${uploadDir}`);
});
