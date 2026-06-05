import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Substitua pela URL do seu projeto na Vercel
  static const String baseUrl = 'https://felixadm.vercel.app/api';

  // --- CLIENTS ---
  static Future<List<dynamic>> getClients() async {
    final response = await http.get(Uri.parse('$baseUrl/clients'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load clients');
    }
  }

  static Future<dynamic> createClient(Map<String, dynamic> clientData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clients'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(clientData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create client');
    }
  }

  // --- PRODUCTS ---
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<dynamic> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(productData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create product');
    }
  }
}
