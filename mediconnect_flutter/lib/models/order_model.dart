class OrderItem {
  final String medicineName;
  final bool isGeneric;
  final double unitPrice;
  int quantity;

  OrderItem({
    required this.medicineName,
    required this.isGeneric,
    required this.unitPrice,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'medicine_name': medicineName,
    'is_generic': isGeneric,
    'unit_price': unitPrice,
    'quantity': quantity,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      medicineName: json['medicine_name'] ?? '',
      isGeneric: json['is_generic'] ?? true,
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  double get totalPrice => unitPrice * quantity;
}

class CreateOrderRequest {
  final String userId;
  final String pharmacyId;
  final List<OrderItem> items;
  final String paymentMethod;
  final bool bypassLimitConfirmation;

  CreateOrderRequest({
    required this.userId,
    required this.pharmacyId,
    required this.items,
    this.paymentMethod = 'UPI_AUTOPAY',
    this.bypassLimitConfirmation = false,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'pharmacy_id': pharmacyId,
    'items': items.map((i) => i.toJson()).toList(),
    'payment_method': paymentMethod,
    'bypass_limit_confirmation': bypassLimitConfirmation,
  };
}

class OrderResponse {
  final String orderId;
  final String pharmacyId;
  final String pharmacyName;
  final String status;
  final double subtotal;
  final double genericSavings;
  final double totalAmount;
  final double commissionRatePercent;
  final double commissionAmount;
  final bool autoPayApproved;
  final bool requiresManualConfirmation;
  final String message;

  OrderResponse({
    required this.orderId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.status,
    required this.subtotal,
    required this.genericSavings,
    required this.totalAmount,
    required this.commissionRatePercent,
    required this.commissionAmount,
    required this.autoPayApproved,
    required this.requiresManualConfirmation,
    required this.message,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      orderId: json['order_id'] ?? '',
      pharmacyId: json['pharmacy_id'] ?? '',
      pharmacyName: json['pharmacy_name'] ?? '',
      status: json['status'] ?? 'PENDING',
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      genericSavings: (json['generic_savings'] ?? 0.0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      commissionRatePercent: (json['commission_rate_percent'] ?? 6.5).toDouble(),
      commissionAmount: (json['commission_amount'] ?? 0.0).toDouble(),
      autoPayApproved: json['auto_pay_approved'] ?? true,
      requiresManualConfirmation: json['requires_manual_confirmation'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
