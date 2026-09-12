import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/triage_model.dart';
import '../../models/pharmacy_model.dart';
import '../../models/order_model.dart';
import '../../models/medical_record_model.dart';

class ApiService {
  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  /// Send user symptom/health query to 12-agent orchestration pipeline
  Future<TriageResponse> processTriage({
    required String message,
    String? voiceTranscript,
    double latitude = 28.6139,
    double longitude = 77.2090,
    String userId = ApiConstants.defaultUserId,
  }) async {
    final uri = Uri.parse(ApiConstants.triageMessage);
    final body = jsonEncode({
      'user_id': userId,
      'message': message,
      'voice_transcript': voiceTranscript,
      'latitude': latitude,
      'longitude': longitude,
    });

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TriageResponse.fromJson(data);
    } else {
      throw Exception('Triage failed: ${response.statusCode} - ${response.body}');
    }
  }

  /// Discover nearby verified pharmacies with generic vs branded stock
  Future<List<Pharmacy>> getNearbyPharmacies({
    double latitude = 28.6139,
    double longitude = 77.2090,
    String? query,
  }) async {
    final queryParams = {
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      if (query != null && query.isNotEmpty) 'query': query,
    };

    final uri = Uri.parse(ApiConstants.nearbyPharmacies).replace(queryParameters: queryParams);
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Pharmacy.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch pharmacies: ${response.statusCode}');
    }
  }

  /// Create pharmacy order with transparent 6.5% commission cap and payment safety check
  Future<OrderResponse> createOrder(CreateOrderRequest request) async {
    final uri = Uri.parse(ApiConstants.createOrder);
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OrderResponse.fromJson(data);
    } else {
      throw Exception('Failed to create order: ${response.statusCode} - ${response.body}');
    }
  }

  /// One-tap manual emergency SOS trigger
  Future<Map<String, dynamic>> triggerEmergency({
    required String reason,
    double latitude = 28.6139,
    double longitude = 77.2090,
    String userId = ApiConstants.defaultUserId,
  }) async {
    final uri = Uri.parse(ApiConstants.emergencyTrigger);
    final body = jsonEncode({
      'user_id': userId,
      'reason': reason,
      'latitude': latitude,
      'longitude': longitude,
      'location_label': 'GPS Live Coordinates',
    });

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Emergency trigger failed: ${response.statusCode}');
    }
  }

  /// Get decrypted medical profile, allergies, and history
  Future<UserMedicalProfile> getUserProfile({
    String userId = ApiConstants.defaultUserId,
  }) async {
    final uri = Uri.parse(ApiConstants.userProfile(userId));
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserMedicalProfile.fromJson(data);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  /// Get live order details by order ID
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final uri = Uri.parse(ApiConstants.orderDetails(orderId));
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch order details: ${response.statusCode}');
    }
  }

  /// Explicit two-step manual payment confirmation when total exceeds auto-pay limit
  Future<Map<String, dynamic>> confirmOrderPayment({
    required String orderId,
    String userId = ApiConstants.defaultUserId,
  }) async {
    final uri = Uri.parse('${ApiConstants.confirmOrderPayment(orderId)}?user_id=$userId');
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to confirm order payment: ${response.statusCode}');
    }
  }

  /// Update user's server-side auto-pay limit
  Future<void> updatePaymentLimit({
    required double newLimit,
    String userId = ApiConstants.defaultUserId,
  }) async {
    final uri = Uri.parse(ApiConstants.updateProfile(userId));
    final body = jsonEncode({'payment_limit': newLimit});
    final response = await client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update payment limit: ${response.statusCode}');
    }
  }

  /// Authenticate user via email or phone
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String? expectedRole,
  }) async {
    final uri = Uri.parse(ApiConstants.login);
    final bodyMap = <String, dynamic>{
      'identifier': identifier,
      'password': password,
    };
    if (expectedRole != null) {
      bodyMap['expected_role'] = expectedRole;
    }
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bodyMap),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Login failed');
    }
  }

  /// Request 6-digit verification code to registered email
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final uri = Uri.parse(ApiConstants.forgotPassword);
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Failed to request reset code');
    }
  }

  /// Verify 6-digit code and set new password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final uri = Uri.parse(ApiConstants.resetPassword);
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'code': code.trim(),
        'new_password': newPassword.trim(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Failed to reset password');
    }
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

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Registration failed');
    }
  }

  /// 1-click fast customer login
  Future<Map<String, dynamic>> demoLogin() async {
    final uri = Uri.parse(ApiConstants.demoLogin);
    final response = await client.post(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Demo login failed: ${response.statusCode}');
    }
  }

  /// 1-click fast pharmacy owner login
  Future<Map<String, dynamic>> ownerDemoLogin() async {
    final uri = Uri.parse(ApiConstants.ownerDemoLogin);
    final response = await client.post(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Owner demo login failed: ${response.statusCode}');
    }
  }

  /// Get all past and active orders for user
  Future<List<Map<String, dynamic>>> getUserOrders({
    required String userId,
  }) async {
    final uri = Uri.parse(ApiConstants.userOrders(userId));
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
  }

  /// Get medical store owner dashboard analytics
  Future<Map<String, dynamic>> getOwnerDashboard(String pharmacyId) async {
    final uri = Uri.parse(ApiConstants.ownerDashboard(pharmacyId));
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load owner dashboard: ${response.statusCode}');
    }
  }

  /// Owner: update medicine stock quantity
  Future<void> updateStock({
    required String pharmacyId,
    required String medicineId,
    int? delta,
    int? newStock,
  }) async {
    final uri = Uri.parse(ApiConstants.updateStock(pharmacyId));
    final body = jsonEncode({
      'medicine_id': medicineId,
      'delta': delta,
      'new_stock': newStock,
    });

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update stock: ${response.statusCode}');
    }
  }

  /// Owner: update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final uri = Uri.parse(ApiConstants.updateOrderStatus(orderId));
    final body = jsonEncode({'status': status});

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update order status: ${response.statusCode}');
    }
  }

  /// Get chat messages between customer and chemist
  Future<List<Map<String, dynamic>>> getChatMessages({
    required String pharmacyId,
    required String userId,
  }) async {
    final uri = Uri.parse(ApiConstants.chatMessages).replace(queryParameters: {
      'pharmacy_id': pharmacyId,
      'user_id': userId,
    });
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch messages: ${response.statusCode}');
    }
  }

  /// Send chat message
  Future<Map<String, dynamic>> sendChatMessage({
    required String pharmacyId,
    required String userId,
    required String senderRole,
    required String senderName,
    required String message,
  }) async {
    final uri = Uri.parse(ApiConstants.chatSend);
    final body = jsonEncode({
      'pharmacy_id': pharmacyId,
      'user_id': userId,
      'sender_role': senderRole,
      'sender_name': senderName,
      'message': message,
    });

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  /// Owner: get active chat threads
  Future<List<Map<String, dynamic>>> getChatThreads(String pharmacyId) async {
    final uri = Uri.parse(ApiConstants.chatThreads(pharmacyId));
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load chat threads: ${response.statusCode}');
    }
  }
}
