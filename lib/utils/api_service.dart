import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Se estiver na Web, usa o domínio atual. Se for App (Android/iOS), usa a URL completa.
  // IMPORTANTE: Substitua pela sua URL final da Vercel para quando rodar como App Nativo.
  static String get baseUrl {
    if (kIsWeb) {
      return '/api';
    } else {
      return 'https://felixadm.vercel.app/api';
    }
  }

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

  static Future<dynamic> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/products/$id'));
    return _handleResponse(response);
  }

  // --- SALES ---
  static Future<dynamic> getSaleById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/sales/$id'));
    return _handleResponse(response);
  }

  static Future<dynamic> registerPayment(int saleId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sales/$saleId/payments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return _handleResponse(response);
  }
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
