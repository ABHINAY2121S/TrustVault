import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _loading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;
  bool get loading => _loading;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userStr = prefs.getString('user');
    if (userStr != null) {
      _user = Map<String, dynamic>.from(
        (userStr.startsWith('{'))
            ? {}
            : {},
      );
    }
    notifyListeners();
  }

  Future<String?> loginUser(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await ApiService.login(email, password, 'user');
      if (result['status'] == 200) {
        _token = result['data']['token'];
        _user = result['data']['user'] ?? result['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        notifyListeners();
        return null;
      }
      return result['data']['message'] ?? 'Login failed';
    } catch (e) {
      return 'Cannot connect to server. Check your network.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> registerUser(Map<String, dynamic> body) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await ApiService.register({...body, 'role': 'user'});
      if (result['status'] == 201) {
        _token = result['data']['token'];
        _user = result['data']['user'] ?? result['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        notifyListeners();
        return null;
      }
      return result['data']['message'] ?? 'Registration failed';
    } catch (e) {
      return 'Cannot connect to server. Check your network.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await ApiService.clearToken();
    notifyListeners();
  }
}
