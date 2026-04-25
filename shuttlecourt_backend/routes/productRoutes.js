const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

router.get('/', productController.getProducts);
router.post('/add', productController.addProduct);
router.put('/:id', productController.updateProduct);
router.delete('/:id', productController.deleteProduct);
router.get('/orders', productController.getOrders);
router.put('/orders/:orderId', productController.updateOrderStatus);
router.post('/order', productController.placeOrder); // NEW

module.exports = router;
