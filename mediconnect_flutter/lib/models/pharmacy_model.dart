class InventoryItem {
  final String genericName;
  final String brandedName;
  final double genericPrice;
  final double brandedPrice;
  final int stockQuantity;
  final bool inStock;

  InventoryItem({
    required this.genericName,
    required this.brandedName,
    required this.genericPrice,
    required this.brandedPrice,
    required this.stockQuantity,
    required this.inStock,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      genericName: json['generic_name'] ?? '',
      brandedName: json['branded_name'] ?? '',
      genericPrice: (json['generic_price'] ?? 0.0).toDouble(),
      brandedPrice: (json['branded_price'] ?? 0.0).toDouble(),
      stockQuantity: json['stock_quantity'] ?? 0,
      inStock: json['in_stock'] ?? ((json['stock_quantity'] ?? 0) > 0),
    );
  }

  double get potentialSavings => (brandedPrice - genericPrice).clamp(0.0, double.infinity);
}

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double distanceKm;
  final int responseTimeMin;
  final double rating;
  final bool isSmallLocalBusiness;
  final List<InventoryItem> inventory;
  final String directChatPhone;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.distanceKm,
    required this.responseTimeMin,
    required this.rating,
    required this.isSmallLocalBusiness,
    required this.inventory,
    required this.directChatPhone,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    var rawInv = json['inventory'] as List? ?? [];
    List<InventoryItem> invList =
        rawInv.map((item) => InventoryItem.fromJson(item)).toList();

    return Pharmacy(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
      responseTimeMin: json['response_time_min'] ?? 15,
      rating: (json['rating'] ?? 4.5).toDouble(),
      isSmallLocalBusiness: json['is_small_local_business'] ?? true,
      inventory: invList,
      directChatPhone: json['direct_chat_phone'] ?? (json['phone'] ?? ''),
    );
  }
}
