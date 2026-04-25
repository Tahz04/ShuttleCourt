import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shuttlecourt/config/api_config.dart';

class Product {
  final int? id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String? imageUrl;
  final String? description;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'price': price,
    'stock': stock,
    'image_url': imageUrl,
    'description': description,
  };
}

class ShopService {
  static Future<List<Product>> getProducts({bool showAll = false}) async {
    try {
      final url = showAll ? '${ApiConfig.productsUrl}?all=true' : ApiConfig.productsUrl;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  static Future<bool> addProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.productsUrl + '/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  static Future<bool> updateProduct(Product product) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.productsUrl + '/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  static Future<bool> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.productsUrl + '/$id'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  static Future<bool> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String address,
    required String paymentMethod,
    String? discountCode,
    double? subtotal,
    double? discountAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.productsUrl + '/order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'items': items,
          'totalPrice': totalPrice,
          'address': address,
          'paymentMethod': paymentMethod,
          'discountCode': discountCode,
          'subtotal': subtotal,
          'discountAmount': discountAmount,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }
  static Future<List<dynamic>> getOrders() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.productsUrl + '/orders'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }
}
