import 'package:flutter/material.dart';
import 'package:shuttlecourt/services/shop_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Vợt';
  bool _isLoading = false;
  File? _selectedImage;
  String? _imageBase64;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toInt().toString();
      _stockController.text = widget.product!.stock.toString();
      _descController.text = widget.product!.description ?? '';
      _selectedCategory = widget.product!.category;
      _imageBase64 = widget.product!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = File(image.path);
        _imageBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')));
      return;
    }

    setState(() => _isLoading = true);

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text,
      category: _selectedCategory,
      price: double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0,
      stock: int.tryParse(_stockController.text) ?? 0,
      imageUrl: _imageBase64,
      description: _descController.text,
    );

    bool success;
    if (widget.product != null) {
      success = await ShopService.updateProduct(product);
    } else {
      success = await ShopService.addProduct(product);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.product != null ? '✅ Cập nhật thành công!' : '✅ Thêm thành công!'), 
          backgroundColor: AppTheme.success
        ));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Lỗi thao tác.'), backgroundColor: AppTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product != null ? 'CHỈNH SỬA SẢN PHẨM' : 'THÊM SẢN PHẨM MỚI', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                    image: (_selectedImage != null)
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                      : (_imageBase64 != null && _imageBase64!.startsWith('data:image'))
                        ? DecorationImage(
                            image: (() {
                              try {
                                String b64 = _imageBase64!.split(',').last;
                                while (b64.length % 4 != 0) { b64 += '='; }
                                return MemoryImage(base64Decode(b64));
                              } catch (e) {
                                return const AssetImage('assets/placeholder.png') as ImageProvider; // Fallback
                              }
                            }()), 
                            fit: BoxFit.cover
                          )
                        : null,
                  ),
                  child: _selectedImage == null 
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: AppTheme.primary, size: 30),
                          SizedBox(height: 8),
                          Text('Thêm hình ảnh', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : null,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildLabel('Tên sản phẩm'),
            _buildTextField('Ví dụ: Vợt Yonex Astrox...', _nameController),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Giá tiền (VNĐ)'),
                      _buildTextField('4,500,000', _priceController, keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Số lượng kho'),
                      _buildTextField('10', _stockController, keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel('Danh mục'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                  items: ['Vợt', 'Quả cầu', 'Giày', 'Phụ kiện'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Mô tả sản phẩm'),
            _buildTextField('Nhập thông tin sản phẩm...', _descController, maxLines: 4),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('LƯU SẢN PHẨM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
      ),
    );
  }
}
