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
  final List<String> allergies;
  final double latitude;
  final double longitude;

  UserSession({
    required this.id,
    required this.name,
    required this.contact,
    this.email,
    required this.role,
    this.storeId,
    required this.address,
    required this.paymentLimit,
    this.allergies = const ['Aspirin (Strict Block)', 'Penicillin'],
    this.latitude = 28.4680,
    this.longitude = 77.0420,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    var rawAllergies = json['allergies'] as List<dynamic>? ?? ['Aspirin (Strict Block)', 'Penicillin'];
    List<String> allergiesList = rawAllergies.map((e) => e.toString()).toList();

    return UserSession(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User',
      contact: json['contact'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'customer',
      storeId: json['store_id'] ?? (json['role'] == 'pharmacy_owner' ? 'pharm-001' : null),
      address: json['address'] ?? 'Sector 15, Gurgaon',
      paymentLimit: (json['payment_limit'] as num?)?.toDouble() ?? 1500.0,
      allergies: allergiesList,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 28.4680,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.0420,
    );
  }

  bool get isOwner => role == 'pharmacy_owner';

  UserSession copyWith({
    String? id,
    String? name,
    String? contact,
    String? email,
    String? role,
    String? storeId,
    String? address,
    double? paymentLimit,
    List<String>? allergies,
    double? latitude,
    double? longitude,
  }) {
    return UserSession(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      address: address ?? this.address,
      paymentLimit: paymentLimit ?? this.paymentLimit,
      allergies: allergies ?? this.allergies,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
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

  void switchRole(String role) {
    _selectedRole = role;
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: role);
    }
    _errorMessage = null;
    notifyListeners();
  }

  // =========================================================================
  // SAFE AUTO-PAY LIMIT GUARDRAIL (WALLET / BALANCE & DEDUCTIONS)
  // =========================================================================
  double _customAutoPayBalance = 1500.0;
  double get safeAutoPayBalance => _currentUser?.paymentLimit ?? _customAutoPayBalance;

  void updatePaymentLimit(double newLimit) {
    _customAutoPayBalance = newLimit;
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(paymentLimit: newLimit);
      _apiService.updatePaymentLimit(newLimit: newLimit, userId: _currentUser!.id);
    }
    notifyListeners();
  }

  /// Add amount (Top-up) to Safe Auto-Pay Limit Guardrail
  void addAutoPayAmount(double topUpAmount) {
    if (topUpAmount <= 0) return;
    final current = safeAutoPayBalance;
    final updated = current + topUpAmount;
    updatePaymentLimit(updated);
  }

  /// Deduct ordered medicine amount from Safe Auto-Pay Limit Guardrail
  bool deductAutoPayAmount(double amount) {
    if (amount <= 0) return true;
    final current = safeAutoPayBalance;
    if (amount > current) {
      // Exceeds guardrail limit! Blocked server-side and client-side
      return false;
    }
    final remaining = (current - amount).clamp(0.0, double.infinity);
    updatePaymentLimit(remaining);
    return true;
  }

  void updateUserLocation({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
    }
  }

  void updateUserProfile({
    required String name,
    required String contact,
    required String email,
    required String address,
    double? paymentLimit,
    List<String>? allergies,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        contact: contact,
        email: email,
        address: address,
        paymentLimit: paymentLimit ?? _currentUser!.paymentLimit,
        allergies: allergies ?? _currentUser!.allergies,
      );
      notifyListeners();

      _apiService.updateProfile(
        userId: _currentUser!.id,
        name: name,
        contact: contact,
        email: email,
        address: address,
        paymentLimit: paymentLimit,
      ).catchError((_) => {});
    }
  }

  void addAllergy(String newAllergy) {
    if (_currentUser != null && newAllergy.trim().isNotEmpty) {
      final currentAllergies = List<String>.from(_currentUser!.allergies);
      if (!currentAllergies.contains(newAllergy.trim())) {
        currentAllergies.add(newAllergy.trim());
        _currentUser = _currentUser!.copyWith(allergies: currentAllergies);
        notifyListeners();
      }
    }
  }

  void removeAllergy(String allergy) {
    if (_currentUser != null) {
      final currentAllergies = List<String>.from(_currentUser!.allergies);
      currentAllergies.remove(allergy);
      _currentUser = _currentUser!.copyWith(allergies: currentAllergies);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> directEmailLogin({required String email, String? name, String role = 'customer'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.directEmailLogin(email: email, name: name, role: role);
      if (res['success'] == true && res['user'] != null) {
        _currentUser = UserSession.fromJson(res['user']);
        _selectedRole = _currentUser!.role;
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
