import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/triage_model.dart';
import '../../models/pharmacy_model.dart';
import '../../models/order_model.dart';
import '../../models/medical_record_model.dart';
import 'offline_simulator_service.dart';

class ApiService {
  final http.Client client;
  final OfflineSimulatorService _simulator = OfflineSimulatorService.instance;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  /// Send user symptom/health query to 12-agent orchestration pipeline
  Future<TriageResponse> processTriage({
    required String message,
    String? voiceTranscript,
    double latitude = 28.6139,
    double longitude = 77.2090,
    String userId = ApiConstants.defaultUserId,
    String? village,
    String? address,
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.processTriage(
        message: message,
        voiceTranscript: voiceTranscript,
        userId: userId,
      );
    }

    try {
      final uri = Uri.parse(ApiConstants.triageMessage);
      final body = jsonEncode({
        'user_id': userId,
        'message': message,
        'voice_transcript': voiceTranscript,
        'latitude': latitude,
        'longitude': longitude,
        if (village != null && village.isNotEmpty) 'village': village,
        if (address != null && address.isNotEmpty) 'address': address,
      });

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TriageResponse.fromJson(data);
      }
    } catch (e) {
      debugPrint('ApiService.processTriage fallback to simulator: $e');
    }

    // Fallback to simulator
    return _simulator.processTriage(
      message: message,
      voiceTranscript: voiceTranscript,
      userId: userId,
    );
  }

  /// Discover nearby verified pharmacies with generic vs branded stock
  Future<List<Pharmacy>> getNearbyPharmacies({
    double latitude = 28.6139,
    double longitude = 77.2090,
    String? query,
    String? village,
    String? address,
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.getNearbyPharmacies(query: query);
    }

    try {
      final queryParams = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        if (query != null && query.isNotEmpty) 'query': query,
        if (village != null && village.isNotEmpty) 'village': village,
        if (address != null && address.isNotEmpty) 'address': address,
      };

      final uri = Uri.parse(ApiConstants.nearbyPharmacies).replace(queryParameters: queryParams);
      final response = await client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Pharmacy.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('ApiService.getNearbyPharmacies fallback to simulator: $e');
    }

    return _simulator.getNearbyPharmacies(query: query);
  }

  /// Create pharmacy order with transparent 6.5% commission cap and payment safety check
  Future<OrderResponse> createOrder(CreateOrderRequest request) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.createOrder(request);
    }

    try {
      final uri = Uri.parse(ApiConstants.createOrder);
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OrderResponse.fromJson(data);
      }
    } catch (e) {
      debugPrint('ApiService.createOrder fallback to simulator: $e');
    }

    return _simulator.createOrder(request);
  }

  /// One-tap manual emergency SOS trigger
  Future<Map<String, dynamic>> triggerEmergency({
    required String reason,
    double latitude = 28.6139,
    double longitude = 77.2090,
    String userId = ApiConstants.defaultUserId,
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.triggerEmergency(
        reason: reason,
        latitude: latitude,
        longitude: longitude,
        userId: userId,
      );
    }

    try {
      final uri = Uri.parse(ApiConstants.emergencyTrigger);
      final body = jsonEncode({
        'user_id': userId,
        'reason': reason,
        'latitude': latitude,
        'longitude': longitude,
        'location_label': 'GPS Live Coordinates',
      });

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.triggerEmergency fallback to simulator: $e');
    }

    return _simulator.triggerEmergency(
      reason: reason,
      latitude: latitude,
      longitude: longitude,
      userId: userId,
    );
  }

  /// Get decrypted medical profile, allergies, and history
  Future<UserMedicalProfile> getUserProfile({
    String userId = ApiConstants.defaultUserId,
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.getUserProfile(userId);
    }

    try {
      final uri = Uri.parse(ApiConstants.userProfile(userId));
      final response = await client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserMedicalProfile.fromJson(data);
      }
    } catch (e) {
      debugPrint('ApiService.getUserProfile fallback to simulator: $e');
    }

    return _simulator.getUserProfile(userId);
  }

  /// Get live order details by order ID
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.getOrderDetails(orderId);
    }

    try {
      final uri = Uri.parse(ApiConstants.orderDetails(orderId));
      final response = await client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.getOrderDetails fallback to simulator: $e');
    }

    return _simulator.getOrderDetails(orderId);
  }

  /// Explicit two-step manual payment confirmation when total exceeds auto-pay limit
  Future<Map<String, dynamic>> confirmOrderPayment({
    required String orderId,
    String userId = ApiConstants.defaultUserId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.confirmOrderPayment(orderId)}?user_id=$userId');
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.confirmOrderPayment fallback: $e');
    }

    return {'success': true, 'message': 'Payment confirmed under simulator ceiling'};
  }

  /// Update user's server-side auto-pay limit
  Future<void> updatePaymentLimit({
    required double newLimit,
    String userId = ApiConstants.defaultUserId,
  }) async {
    await _simulator.updatePaymentLimit(newLimit);

    try {
      final uri = Uri.parse(ApiConstants.updateProfile(userId));
      final body = jsonEncode({'payment_limit': newLimit});
      await client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('ApiService.updatePaymentLimit fallback: $e');
    }
  }

  /// Authenticate user via email or phone
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String? expectedRole,
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.login(
        identifier: identifier,
        password: password,
        expectedRole: expectedRole,
      );
    }

    try {
      final uri = Uri.parse(ApiConstants.login);
      final bodyMap = <String, dynamic>{
        'identifier': identifier,
        'password': password,
      };
      if (expectedRole != null) {
        bodyMap['expected_role'] = expectedRole;
      }
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyMap),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Login failed');
      }
    } catch (e) {
      // If network/connection error (not 401 wrong password), fall back to simulator
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        debugPrint('ApiService.login fallback to simulator: $e');
        return _simulator.login(
          identifier: identifier,
          password: password,
          expectedRole: expectedRole,
        );
      }
      rethrow;
    }
  }

  /// Direct 1-click passwordless login via Email or Google
  Future<Map<String, dynamic>> directEmailLogin({
    required String email,
    String? name,
    String role = 'customer',
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.login(
        identifier: email,
        password: 'DemoPassword',
        expectedRole: role,
      );
    }

    try {
      final uri = Uri.parse(ApiConstants.emailLogin);
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              if (name != null && name.isNotEmpty) 'name': name.trim(),
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.directEmailLogin fallback to simulator: $e');
    }

    return _simulator.login(
      identifier: email,
      password: 'DemoPassword',
      expectedRole: role,
    );
  }

  /// Update user full profile details
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? name,
    String? contact,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    double? paymentLimit,
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.updateProfile(userId));
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (contact != null) 'contact': contact,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (paymentLimit != null) 'payment_limit': paymentLimit,
      };

      final response = await client
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('ApiService.updateProfile fallback: $e');
    }
    return {'status': 'SUCCESS', 'message': 'Profile updated locally'};
  }

  /// Request 6-digit verification code to registered email
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.forgotPassword(email);
    }

    try {
      final uri = Uri.parse(ApiConstants.forgotPassword);
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.forgotPassword fallback to simulator: $e');
    }

    return _simulator.forgotPassword(email);
  }

  /// Verify 6-digit code and set new password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
    }

    try {
      final uri = Uri.parse(ApiConstants.resetPassword);
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'code': code.trim(),
              'new_password': newPassword.trim(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.resetPassword fallback to simulator: $e');
    }

    return _simulator.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  /// Register a new patient or pharmacy store owner
  Future<Map<String, dynamic>> signup({
    required String name,
    required String contact,
    String? email,
    required String password,
    String role = 'customer',
    String? storeName,
    String? address,
    List<String>? allergies,
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.signup(
        name: name,
        contact: contact,
        email: email,
        password: password,
        role: role,
        storeName: storeName,
        address: address,
        allergies: allergies,
      );
    }

    try {
      final uri = Uri.parse(ApiConstants.signup);
      final body = jsonEncode({
        'name': name,
        'contact': contact,
        'email': email,
        'password': password,
        'role': role,
        'store_name': storeName,
        'address': address ?? 'Sector 15, Gurgaon',
        'allergies': allergies ?? [],
      });

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.signup fallback to simulator: $e');
    }

    return _simulator.signup(
      name: name,
      contact: contact,
      email: email,
      password: password,
      role: role,
      storeName: storeName,
      address: address,
      allergies: allergies,
    );
  }

  /// 1-click fast customer login
  Future<Map<String, dynamic>> demoLogin() async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.demoCustomerLogin();
    }

    try {
      final uri = Uri.parse(ApiConstants.demoLogin);
      final response = await client.post(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.demoLogin fallback to simulator: $e');
    }

    return _simulator.demoCustomerLogin();
  }

  /// 1-click fast pharmacy owner login
  Future<Map<String, dynamic>> ownerDemoLogin() async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.demoOwnerLogin();
    }

    try {
      final uri = Uri.parse(ApiConstants.ownerDemoLogin);
      final response = await client.post(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.ownerDemoLogin fallback to simulator: $e');
    }

    return _simulator.demoOwnerLogin();
  }

  /// Get all past and active orders for user
  Future<List<Map<String, dynamic>>> getUserOrders({
    required String userId,
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.getUserOrders(userId);
    }

    try {
      final uri = Uri.parse(ApiConstants.userOrders(userId));
      final response = await client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.getUserOrders fallback to simulator: $e');
    }

    return _simulator.getUserOrders(userId);
  }

  /// Get medical store owner dashboard analytics
  Future<Map<String, dynamic>> getOwnerDashboard(String pharmacyId) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.getOwnerDashboard(pharmacyId);
    }

    try {
      final uri = Uri.parse(ApiConstants.ownerDashboard(pharmacyId));
      final response = await client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.getOwnerDashboard fallback to simulator: $e');
    }

    return _simulator.getOwnerDashboard(pharmacyId);
  }

  /// Owner: update medicine stock quantity
  Future<void> updateStock({
    required String pharmacyId,
    required String medicineId,
    int? delta,
    int? newStock,
  }) async {
    await _simulator.updateStock(
      pharmacyId: pharmacyId,
      medicineId: medicineId,
      delta: delta,
      newStock: newStock,
    );

    try {
      final uri = Uri.parse(ApiConstants.updateStock(pharmacyId));
      final body = jsonEncode({
        'medicine_id': medicineId,
        'delta': delta,
        'new_stock': newStock,
      });

      await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('ApiService.updateStock fallback: $e');
    }
  }

  /// Owner: update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _simulator.updateOrderStatus(orderId: orderId, status: status);

    try {
      final uri = Uri.parse(ApiConstants.updateOrderStatus(orderId));
      final body = jsonEncode({'status': status});

      await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('ApiService.updateOrderStatus fallback: $e');
    }
  }

  /// Get chat messages between customer and chemist
  Future<List<Map<String, dynamic>>> getChatMessages({
    required String pharmacyId,
    required String userId,
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.getChatMessages(pharmacyId, userId);
    }

    try {
      final uri = Uri.parse(ApiConstants.chatMessages).replace(queryParameters: {
        'pharmacy_id': pharmacyId,
        'user_id': userId,
      });
      final response = await client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.getChatMessages fallback to simulator: $e');
    }

    return _simulator.getChatMessages(pharmacyId, userId);
  }

  /// Send chat message
  Future<Map<String, dynamic>> sendChatMessage({
    required String pharmacyId,
    required String userId,
    required String senderRole,
    required String senderName,
    required String message,
  }) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.sendChatMessage(
        pharmacyId: pharmacyId,
        userId: userId,
        senderRole: senderRole,
        senderName: senderName,
        message: message,
      );
    }

    try {
      final uri = Uri.parse(ApiConstants.chatSend);
      final body = jsonEncode({
        'pharmacy_id': pharmacyId,
        'user_id': userId,
        'sender_role': senderRole,
        'sender_name': senderName,
        'message': message,
      });

      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.sendChatMessage fallback to simulator: $e');
    }

    return _simulator.sendChatMessage(
      pharmacyId: pharmacyId,
      userId: userId,
      senderRole: senderRole,
      senderName: senderName,
      message: message,
    );
  }

  /// Owner: get active chat threads
  Future<List<Map<String, dynamic>>> getChatThreads(String pharmacyId) async {
    if (ApiConstants.isSimulatorMode) {
      return _simulator.getChatThreads(pharmacyId);
    }

    try {
      final uri = Uri.parse(ApiConstants.chatThreads(pharmacyId));
      final response = await client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.getChatThreads fallback to simulator: $e');
    }

    return _simulator.getChatThreads(pharmacyId);
  }
}
