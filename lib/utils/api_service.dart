import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Substitua pela URL do seu projeto na Vercel
  static const String baseUrl = 'https://felixadm.vercel.app/api';

  // --- CLIENTS ---
  static Future<List<dynamic>> getClients() async {
    final response = await http.get(Uri.parse('$baseUrl/clients'));
    return _handleResponse(response);
  }

  static Future<dynamic> createClient(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clients'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // --- PRODUCTS ---
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    return _handleResponse(response);
  }

  static Future<dynamic> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // --- SALES ---
  static Future<List<dynamic>> getSales() async {
    final response = await http.get(Uri.parse('$baseUrl/sales'));
    return _handleResponse(response);
  }

  static Future<dynamic> createSale(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sales'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // --- DASHBOARD ---
  static Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(Uri.parse('$baseUrl/stats'));
    final dynamic data = _handleResponse(response);
    return data as Map<String, dynamic>;
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
