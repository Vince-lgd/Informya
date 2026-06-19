import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Détecte automatiquement la bonne URL selon la plateforme
String get baseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000'; // Émulateur Android
  } else {
    return 'http://localhost:8000'; // iOS simulateur Mac
  }
}

class ApiService {
  // ── Auth ──────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Register ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // ── Login ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // ── Feed ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getFeed({
    int page = 1,
    String? category,
  }) async {
    final headers = await _authHeaders();
    String url = '$baseUrl/feed?page=$page';
    if (category != null) url += '&category=$category';

    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  // ── Article ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getArticle(String id) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/articles/$id'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getArticleSummary(
    String articleId,
  ) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/articles/$articleId/summary'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ── Bookmarks ─────────────────────────────────────────────
  static Future<List<dynamic>> getBookmarks() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/bookmarks'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<void> addBookmark(String articleId) async {
    final headers = await _authHeaders();
    await http.post(
      Uri.parse('$baseUrl/users/bookmarks'),
      headers: headers,
      body: jsonEncode({'article_id': articleId}),
    );
  }

  static Future<void> removeBookmark(String articleId) async {
    final headers = await _authHeaders();
    await http.delete(
      Uri.parse('$baseUrl/users/bookmarks/$articleId'),
      headers: headers,
    );
  }

  // ── Profile ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMe() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateReadingStyle(String style) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/users/me'),
      headers: headers,
      body: jsonEncode({'reading_style': style}),
    );
    return jsonDecode(response.body);
  }
}
