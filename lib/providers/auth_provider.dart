import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _user?.isAdmin ?? false;

  /// Cek status login saat app start
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loggedIn = await _authService.isLoggedIn();
      if (loggedIn) {
        _user = await _authService.getUser();
        _isLoggedIn = _user != null;
      } else {
        _isLoggedIn = false;
        _user = null;
      }
    } catch (_) {
      _isLoggedIn = false;
      _user = null;
      await _authService.deleteToken();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login
  Future<Map<String, dynamic>> login(String emailOrName, String password) async {
    // KITA HAPUS _isLoading = true di sini agar LoginScreen tidak di-unmount oleh sistem main.dart
    try {
      final result = await _authService.login(emailOrName, password);

      if (result['success'] == true) {
        _user = result['user'];
        _isLoggedIn = true;
        // Hanya panggil notifyListeners JIKA sukses login agar aplikasi berpindah ke HomeScreen
        notifyListeners(); 
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan sistem internal.'
      };
    }
  }

  /// Register
  Future<Map<String, dynamic>> register(
      String name, String email, String password, String passwordConfirmation) async {
    try {
      final result = await _authService.register(name, email, password, passwordConfirmation);

      if (result['success'] == true) {
        _user = result['user'];
        _isLoggedIn = true;
        notifyListeners(); 
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan sistem internal.'
      };
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _user = null;
    _isLoggedIn = false;

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    _user = await _authService.getUser();
    notifyListeners();
  }
}