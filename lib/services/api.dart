import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── Safe HTTP helpers ──────────────────────────────────────────────────
  static Future<http.Response?> _safeGet(Uri uri, {Map<String, String>? headers}) async {
    try {
      return await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response?> _safePost(Uri uri, {Map<String, String>? headers, String? body}) async {
    try {
      return await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response?> _safePut(Uri uri, {Map<String, String>? headers, String? body}) async {
    try {
      return await http.put(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response?> _safeDelete(Uri uri, {Map<String, String>? headers}) async {
    try {
      return await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password, String role) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _headers(auth: false),
        body: jsonEncode({'email': email, 'password': password, 'loginAs': role}),
      ).timeout(const Duration(seconds: 15));
      return {'status': res.statusCode, 'data': jsonDecode(res.body)};
    } catch (e) {
      return {'status': 0, 'data': {'message': 'Cannot connect to server. Check your network.'}};
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await _headers(auth: false),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return {'status': res.statusCode, 'data': jsonDecode(res.body)};
    } catch (e) {
      return {'status': 0, 'data': {'message': 'Cannot connect to server. Check your network.'}};
    }
  }

  // ─── DOCUMENTS ─────────────────────────────────────────────────────────
  static Future<List<dynamic>> getDocuments() async {
    final res = await _safeGet(Uri.parse('$baseUrl/documents'), headers: await _headers());
    if (res != null && res.statusCode == 200) {
      try { return jsonDecode(res.body); } catch (_) {}
    }
    return [];
  }

  static Future<List<dynamic>> getExpiringDocuments() async {
    final res = await _safeGet(Uri.parse('$baseUrl/documents/expiring'), headers: await _headers());
    if (res != null && res.statusCode == 200) {
      try { return jsonDecode(res.body); } catch (_) {}
    }
    return [];
  }

  static Future<bool> deleteDocument(String id) async {
    final res = await _safeDelete(Uri.parse('$baseUrl/documents/$id'), headers: await _headers());
    return res?.statusCode == 200;
  }

  static Future<Map<String, dynamic>> shareDocument(String id) async {
    final res = await _safePost(Uri.parse('$baseUrl/documents/share/$id'), headers: await _headers());
    if (res != null) {
      try { return jsonDecode(res.body); } catch (_) {}
    }
    return {};
  }

  static Future<Map<String, dynamic>> shareFolder(String folderId) async {
    final res = await _safePost(Uri.parse('$baseUrl/folders/$folderId/share'), headers: await _headers());
    if (res != null) {
      try { return jsonDecode(res.body); } catch (_) {}
    }
    return {};
  }

  // ─── FOLDERS ───────────────────────────────────────────────────────────
  static Future<List<dynamic>> getFolders() async {
    final res = await _safeGet(Uri.parse('$baseUrl/folders'), headers: await _headers());
    if (res != null && res.statusCode == 200) {
      try { return jsonDecode(res.body); } catch (_) {}
    }
    return [];
  }

  static Future<Map<String, dynamic>?> createFolder(String name, String color) async {
    final res = await _safePost(
      Uri.parse('$baseUrl/folders'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'color': color}),
    );
    if (res != null && res.statusCode == 201) {
      try { return jsonDecode(res.body); } catch (_) {}
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getFolderDocuments(String folderId) async {
    final res = await _safeGet(Uri.parse('$baseUrl/folders/$folderId/documents'), headers: await _headers());
    if (res != null && res.statusCode == 200) {
      try { return jsonDecode(res.body); } catch (_) {}
    }
    return null;
  }

  static Future<bool> addDocToFolder(String folderId, String docId) async {
    final res = await _safePut(Uri.parse('$baseUrl/folders/$folderId/add/$docId'), headers: await _headers());
    return res?.statusCode == 200;
  }

  static Future<bool> removeDocFromFolder(String docId) async {
    final res = await _safePut(Uri.parse('$baseUrl/folders/remove/$docId'), headers: await _headers());
    return res?.statusCode == 200;
  }

  static Future<bool> deleteFolder(String id) async {
    final res = await _safeDelete(Uri.parse('$baseUrl/folders/$id'), headers: await _headers());
    return res?.statusCode == 200;
  }

  // ─── ACCESS REQUESTS ───────────────────────────────────────────────────
  static Future<List<dynamic>> getPendingAccessRequests() async {
    final res = await _safeGet(Uri.parse('$baseUrl/access/pending'), headers: await _headers());
    if (res != null && res.statusCode == 200) {
      try { return jsonDecode(res.body); } catch (_) {}
    }
    return [];
  }

  static Future<bool> respondToRequest(String id, String action) async {
    final res = await _safePut(
      Uri.parse('$baseUrl/access/$id/respond'),
      headers: await _headers(),
      body: jsonEncode({'action': action}),
    );
    return res?.statusCode == 200;
  }

  // ─── AI ────────────────────────────────────────────────────────────────
  static Future<String> queryAI(String question) async {
    final res = await _safePost(
      Uri.parse('$baseUrl/ai/query'),
      headers: await _headers(),
      body: jsonEncode({'question': question}),
    );
    if (res != null && res.statusCode == 200) {
      try { return jsonDecode(res.body)['reply'] ?? 'No response.'; } catch (_) {}
    }
    return 'Error contacting AI service.';
  }
}
