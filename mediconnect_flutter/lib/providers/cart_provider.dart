import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../models/order_model.dart';
import '../models/pharmacy_model.dart';

class CartItem {
  final String genericName;
  final String brandedName;
  bool useGeneric;
  final double genericPrice;
  final double brandedPrice;
  int quantity;

  CartItem({
    required this.genericName,
    required this.brandedName,
    this.useGeneric = true,
    required this.genericPrice,
    required this.brandedPrice,
    this.quantity = 1,
  });

  String get activeMedicineName => useGeneric ? genericName : brandedName;
  double get unitPrice => useGeneric ? genericPrice : brandedPrice;
  double get totalPrice => unitPrice * quantity;
  double get savings => (brandedPrice - genericPrice).clamp(0.0, double.infinity) * quantity;
}

class CartProvider extends ChangeNotifier {
  final ApiService _apiService;

  CartProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  String? _selectedPharmacyId;
  String? _selectedPharmacyName;
  String? get selectedPharmacyId => _selectedPharmacyId;
  String? get selectedPharmacyName => _selectedPharmacyName;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _orderError;
  String? get orderError => _orderError;

  OrderResponse? _lastOrder;
  OrderResponse? get lastOrder => _lastOrder;

  // Capped commission rate: 6.5% constant matching backend
  static const double commissionRate = 0.065;
  static const double defaultMaxLimit = 1500.0;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get totalSavings {
    return _items.fold(0.0, (sum, item) => sum + (item.useGeneric ? item.savings : 0.0));
  }

  double get commissionAmount {
    return (subtotal * commissionRate);
  }

  double get finalTotal {
    return subtotal + commissionAmount;
  }

  bool get exceedsPaymentLimit => finalTotal > defaultMaxLimit;

  void addItemFromInventory(InventoryItem item, Pharmacy pharmacy, {bool useGeneric = true}) {
    if (_selectedPharmacyId != null && _selectedPharmacyId != pharmacy.id) {
      // Clear cart if switching pharmacy
      _items.clear();
    }
    _selectedPharmacyId = pharmacy.id;
    _selectedPharmacyName = pharmacy.name;

    final existingIndex = _items.indexWhere((i) => i.genericName == item.genericName);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(CartItem(
        genericName: item.genericName,
        brandedName: item.brandedName,
        useGeneric: useGeneric,
        genericPrice: item.genericPrice,
        brandedPrice: item.brandedPrice,
        quantity: 1,
      ));
    }
    notifyListeners();
  }

  void toggleGeneric(int index, bool value) {
    if (index >= 0 && index < _items.length) {
      _items[index].useGeneric = value;
      notifyListeners();
    }
  }

  void updateQuantity(int index, int qty) {
    if (index >= 0 && index < _items.length) {
      if (qty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = qty;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _selectedPharmacyId = null;
    _selectedPharmacyName = null;
    notifyListeners();
  }

  List<Map<String, dynamic>> _userOrders = [];
  List<Map<String, dynamic>> get userOrders => _userOrders;

  bool _isLoadingOrders = false;
  bool get isLoadingOrders => _isLoadingOrders;

  Future<void> fetchUserOrders(String userId) async {
    _isLoadingOrders = true;
    notifyListeners();
    try {
      final orders = await _apiService.getUserOrders(userId: userId);
      _userOrders = orders;
    } catch (_) {
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  Future<OrderResponse?> submitOrder({bool bypassLimit = false, String userId = ApiConstants.defaultUserId}) async {
    if (_items.isEmpty || _selectedPharmacyId == null) return null;

    _isSubmitting = true;
    _orderError = null;
    notifyListeners();

    try {
      final orderItems = _items.map((i) => OrderItem(
        medicineName: i.activeMedicineName,
        isGeneric: i.useGeneric,
        unitPrice: i.unitPrice,
        quantity: i.quantity,
      )).toList();

      final request = CreateOrderRequest(
        userId: userId,
        pharmacyId: _selectedPharmacyId!,
        items: orderItems,
        bypassLimitConfirmation: bypassLimit,
      );

      final response = await _apiService.createOrder(request);
      _lastOrder = response;
      _items.clear();
      
      // Refresh user orders
      fetchUserOrders(userId);

      return response;
    } catch (e) {
      _orderError = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> confirmPayment(String orderId) async {
    _isSubmitting = true;
    _orderError = null;
    notifyListeners();

    try {
      final res = await _apiService.confirmOrderPayment(
        orderId: orderId,
        userId: ApiConstants.defaultUserId,
      );
      if (_lastOrder != null && _lastOrder!.orderId == orderId) {
        _lastOrder = OrderResponse(
          orderId: _lastOrder!.orderId,
          pharmacyId: _lastOrder!.pharmacyId,
          pharmacyName: _lastOrder!.pharmacyName,
          status: 'CONFIRMED',
          subtotal: _lastOrder!.subtotal,
          genericSavings: _lastOrder!.genericSavings,
          totalAmount: _lastOrder!.totalAmount,
          commissionRatePercent: _lastOrder!.commissionRatePercent,
          commissionAmount: _lastOrder!.commissionAmount,
          autoPayApproved: true,
          requiresManualConfirmation: false,
          message: res['message'] ?? 'Payment confirmed successfully.',
        );
      }
      return true;
    } catch (e) {
      _orderError = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void dismissActiveOrder() {
    _lastOrder = null;
    notifyListeners();
  }
}
