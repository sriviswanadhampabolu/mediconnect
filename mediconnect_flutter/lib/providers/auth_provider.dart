import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';

class UserSession {
  final String id;
  final String name;
  final String contact;
  final String? email;
  final String role; // 'customer' or 'pharmacy_owner'
  final String? storeId;
  final String address;
  final double paymentLimit;

  UserSession({
    required this.id,
    required this.name,
    required this.contact,
    this.email,
    required this.role,
    this.storeId,
    required this.address,
    required this.paymentLimit,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User',
      contact: json['contact'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'customer',
      storeId: json['store_id'] ?? (json['role'] == 'pharmacy_owner' ? 'pharm-001' : null),
      address: json['address'] ?? 'Sector 15, Gurgaon',
      paymentLimit: (json['payment_limit'] as num?)?.toDouble() ?? 1500.0,
    );
  }

  bool get isOwner => role == 'pharmacy_owner';
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;

  AuthProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  UserSession? _currentUser;
  UserSession? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;
  bool get isOwner => _currentUser?.isOwner ?? false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Selected role tab for auth screen
  String _selectedRole = 'customer'; // 'customer' or 'pharmacy_owner'
  String get selectedRole => _selectedRole;

  void setSelectedRole(String role) {
    _selectedRole = role;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password, {bool enforceRole = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.login(
        identifier: identifier,
        password: password,
        expectedRole: enforceRole ? _selectedRole : null,
      );
      if (res['success'] == true && res['user'] != null) {
        _currentUser = UserSession.fromJson(res['user']);
        _selectedRole = _currentUser!.role;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Login response did not return valid user data');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request 6-digit reset code to email
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Submit verification code and reset password
  Future<bool> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return res['success'] == true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String contact,
    String? email,
    required String password,
    required String role,
    String? storeName,
    String? address,
    List<String>? allergies,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.signup(
        name: name,
        contact: contact,
        email: email,
        password: password,
        role: role,
        storeName: storeName,
        address: address,
        allergies: allergies,
      );
      if (res['success'] == true && res['user'] != null) {
        _currentUser = UserSession.fromJson(res['user']);
        _selectedRole = _currentUser!.role;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Signup response did not return valid user data');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> demoCustomerLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.demoLogin();
      if (res['success'] == true && res['user'] != null) {
        _currentUser = UserSession.fromJson(res['user']);
        _selectedRole = 'customer';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> demoOwnerLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.ownerDemoLogin();
      if (res['success'] == true && res['user'] != null) {
        _currentUser = UserSession.fromJson(res['user']);
        _selectedRole = 'pharmacy_owner';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
