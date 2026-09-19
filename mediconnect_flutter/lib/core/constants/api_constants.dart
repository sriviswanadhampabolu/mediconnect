import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Simulator mode allows full 100% offline functionality matching the GitHub Pages demo
  static bool isSimulatorMode = false;

  // Auto-detects Android emulator (10.0.2.2) vs Web/Desktop (127.0.0.1)
  static String _baseUrl = (!kIsWeb && Platform.isAndroid)
      ? "http://10.0.2.2:8000/api"
      : "http://127.0.0.1:8000/api";

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String url) {
    var cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (!cleaned.endsWith('/api')) {
      cleaned = '$cleaned/api';
    }
    _baseUrl = cleaned;
    isSimulatorMode = false;
  }

  static void enableSimulatorMode() {
    isSimulatorMode = true;
  }

  static String get triageMessage => "$baseUrl/triage/message";
  static String get nearbyPharmacies => "$baseUrl/pharmacy/nearby";
  static String get createOrder => "$baseUrl/pharmacy/orders/create";
  static String get emergencyTrigger => "$baseUrl/emergency/trigger";
  static String userProfile(String userId) => "$baseUrl/records/user/$userId";
  static String updateProfile(String userId) => "$baseUrl/records/user/$userId/profile";
  static String orderDetails(String orderId) => "$baseUrl/pharmacy/orders/$orderId";
  static String confirmOrderPayment(String orderId) => "$baseUrl/pharmacy/orders/$orderId/confirm_payment";
  
  static String get login => "$baseUrl/auth/login";
  static String get emailLogin => "$baseUrl/auth/email-login";
  static String get signup => "$baseUrl/auth/signup";
  static String get demoLogin => "$baseUrl/auth/demo-login";
  static String get ownerDemoLogin => "$baseUrl/auth/owner-demo-login";
  static String get forgotPassword => "$baseUrl/auth/forgot-password";
  static String get resetPassword => "$baseUrl/auth/reset-password";
  static String userOrders(String userId) => "$baseUrl/pharmacy/orders/user/$userId";
  static String ownerDashboard(String pharmacyId) => "$baseUrl/pharmacy/owner/dashboard/$pharmacyId";
  static String updateStock(String pharmacyId) => "$baseUrl/pharmacy/owner/inventory/$pharmacyId/update-stock";
  static String updateOrderStatus(String orderId) => "$baseUrl/pharmacy/owner/orders/$orderId/status";
  static String get chatMessages => "$baseUrl/pharmacy/chat/messages";
  static String get chatSend => "$baseUrl/pharmacy/chat/send";
  static String chatThreads(String pharmacyId) => "$baseUrl/pharmacy/chat/threads/$pharmacyId";

  // Default demo user ID
  static const String defaultUserId = "usr-sample-001";
  static const String defaultOwnerId = "usr-owner-001";
}
