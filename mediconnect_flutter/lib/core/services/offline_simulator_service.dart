import 'dart:async';
import '../constants/api_constants.dart';
import '../../models/triage_model.dart';
import '../../models/pharmacy_model.dart';
import '../../models/order_model.dart';
import '../../models/medical_record_model.dart';

/// Complete in-memory offline simulator service matching the GitHub Pages
/// web simulator (docs/app.js). Ensures the mobile APK functions 100% reliably
/// offline or when the local backend server is unreachable.
class OfflineSimulatorService {
  static final OfflineSimulatorService instance = OfflineSimulatorService._internal();

  OfflineSimulatorService._internal() {
    _initInitialData();
  }

  final List<Map<String, dynamic>> _registeredUsers = [];
  final List<Map<String, dynamic>> _orders = [];
  final List<Map<String, dynamic>> _chatMessages = [];
  late List<Map<String, dynamic>> _ownerInventory;
  double _userPaymentLimit = 1500.0;

  void _initInitialData() {
    _registeredUsers.addAll([
      {
        'id': 'usr-sample-001',
        'name': 'Rahul Sharma',
        'email': 'rahul@health.in',
        'contact': '+91 98765 43210',
        'password': 'Demo123!',
        'role': 'customer',
        'address': 'Sector 15, Gurgaon',
        'village': 'Sector 15',
        'latitude': 28.4680,
        'longitude': 77.0420,
        'payment_limit': 1500.0,
        'allergies': ['Aspirin', 'Penicillin'],
      },
      {
        'id': 'usr-owner-001',
        'name': 'Ramesh Gupta',
        'email': 'owner@sanjeevani.in',
        'contact': '+91 98101 23456',
        'password': 'Demo123!',
        'role': 'pharmacy_owner',
        'address': 'Shop #4, Sector 15 Market, Gurgaon',
        'village': 'Sector 15',
        'latitude': 28.4682,
        'longitude': 77.0425,
        'store_id': 'pharm-001',
        'store_name': 'Sanjeevani Local Chemist',
        'payment_limit': 1500.0,
        'allergies': <String>[],
      },
    ]);

    _ownerInventory = [
      {
        'id': 'med-1',
        'generic_name': 'Paracetamol 500mg Tablet',
        'branded_name': 'Crocin / Dolo 500',
        'generic_price': 18.0,
        'branded_price': 45.0,
        'stock': 140,
        'in_stock': true,
      },
      {
        'id': 'med-2',
        'generic_name': 'Cetirizine 10mg Tablet',
        'branded_name': 'Zyrtec / Cetzine',
        'generic_price': 15.0,
        'branded_price': 42.0,
        'stock': 110,
        'in_stock': true,
      },
      {
        'id': 'med-3',
        'generic_name': 'Pantoprazole 40mg Tablet',
        'branded_name': 'Pan 40',
        'generic_price': 28.0,
        'branded_price': 88.0,
        'stock': 95,
        'in_stock': true,
      },
      {
        'id': 'med-4',
        'generic_name': 'Oral Rehydration Salts (ORS) Sachet',
        'branded_name': 'Electral',
        'generic_price': 14.0,
        'branded_price': 22.0,
        'stock': 200,
        'in_stock': true,
      },
      {
        'id': 'med-5',
        'generic_name': 'Azithromycin 500mg Tablet',
        'branded_name': 'Azithral 500',
        'generic_price': 65.0,
        'branded_price': 135.0,
        'stock': 45,
        'in_stock': true,
      },
    ];

    // Initial simulated order
    _orders.add({
      'id': 'ord-sim-901',
      'order_id': 'ord-sim-901',
      'user_id': 'usr-sample-001',
      'customer_name': 'Rahul Sharma',
      'pharmacy_id': 'pharm-001',
      'pharmacy_name': 'Sanjeevani Local Chemist',
      'status': 'out_for_delivery',
      'created_at': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
      'subtotal': 61.0,
      'commission_amount': 3.96,
      'commission_rate': 6.5,
      'delivery_fee': 15.0,
      'total_amount': 76.0,
      'payment_method': 'UPI_AUTOPAY',
      'items': [
        {
          'medicine_name': 'Paracetamol 500mg Tablet',
          'is_generic': true,
          'unit_price': 18.0,
          'quantity': 2,
        },
        {
          'medicine_name': 'Cetirizine 10mg Tablet',
          'is_generic': true,
          'unit_price': 15.0,
          'quantity': 1,
        },
        {
          'medicine_name': 'Oral Rehydration Salts (ORS) Sachet',
          'is_generic': true,
          'unit_price': 14.0,
          'quantity': 1,
        },
      ],
      'tracking_steps': [
        {'title': 'Order Placed', 'time': '12 mins ago', 'completed': true},
        {'title': 'Confirmed by Sanjeevani Chemist', 'time': '10 mins ago', 'completed': true},
        {'title': 'Generic Batch Packed', 'time': '7 mins ago', 'completed': true},
        {'title': 'Out for Local Delivery (Delivery partner ~0.6 km away)', 'time': '2 mins ago', 'completed': true},
        {'title': 'Delivered', 'time': 'Est. in 3 mins', 'completed': false},
      ],
    });
  }

  // ================= AUTH SIMULATOR =================
  Future<Map<String, dynamic>> demoCustomerLogin() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = _registeredUsers.firstWhere((u) => u['id'] == 'usr-sample-001');
    return {'success': true, 'user': user, 'token': 'sim-token-cust-123'};
  }

  Future<Map<String, dynamic>> demoOwnerLogin() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = _registeredUsers.firstWhere((u) => u['id'] == 'usr-owner-001');
    return {'success': true, 'user': user, 'token': 'sim-token-owner-456'};
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String? expectedRole,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final cleanId = identifier.trim().toLowerCase();

    // Check existing or demo matches
    for (var u in _registeredUsers) {
      final matchPhone = (u['contact'] as String).replaceAll(' ', '').contains(cleanId.replaceAll(' ', ''));
      final matchEmail = (u['email'] as String?)?.toLowerCase() == cleanId;
      if (matchPhone || matchEmail || cleanId.contains('rahul') || cleanId.contains('owner')) {
        if (expectedRole != null && u['role'] != expectedRole) {
          continue;
        }
        return {'success': true, 'user': u, 'token': 'sim-token-${u['id']}'};
      }
    }

    // Auto-create/allow demo user for evaluation convenience
    final role = expectedRole ?? (cleanId.contains('owner') ? 'pharmacy_owner' : 'customer');
    final newUser = {
      'id': 'usr-gen-${DateTime.now().millisecondsSinceEpoch}',
      'name': identifier.contains('@') ? identifier.split('@')[0] : 'User ${identifier.substring(0, 4)}',
      'email': identifier.contains('@') ? identifier : '$identifier@health.in',
      'contact': identifier,
      'password': password,
      'role': role,
      'address': 'Sector 15, Gurgaon',
      'store_id': role == 'pharmacy_owner' ? 'pharm-001' : null,
      'store_name': role == 'pharmacy_owner' ? 'Sanjeevani Local Chemist' : null,
      'payment_limit': 1500.0,
      'allergies': ['Aspirin'],
    };
    _registeredUsers.add(newUser);
    return {'success': true, 'user': newUser, 'token': 'sim-token-${newUser['id']}'};
  }

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
    await Future.delayed(const Duration(milliseconds: 350));
    final newUser = {
      'id': 'usr-new-${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'contact': contact,
      'email': email ?? '$contact@health.in',
      'password': password,
      'role': role,
      'store_id': role == 'pharmacy_owner' ? 'pharm-001' : null,
      'store_name': storeName ?? (role == 'pharmacy_owner' ? '$name Pharmacy' : null),
      'address': address ?? 'Sector 15, Gurgaon',
      'payment_limit': 1500.0,
      'allergies': allergies ?? ['Aspirin'],
    };
    _registeredUsers.add(newUser);
    return {'success': true, 'user': newUser, 'token': 'sim-token-${newUser['id']}'};
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'success': true,
      'message': 'Verification code sent to $email',
      'dev_code': '123456',
    };
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (code == '123456' || code.length == 6) {
      return {'success': true, 'message': 'Password reset successfully'};
    }
    throw Exception('Invalid verification code. Please enter 123456');
  }

  // ================= 12-AGENT TRIAGE SIMULATOR =================
  Future<TriageResponse> processTriage({
    required String message,
    String? voiceTranscript,
    String userId = ApiConstants.defaultUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final lower = (message + (voiceTranscript ?? '')).toLowerCase();

    final isChestEmergency = lower.contains('chest pain') ||
        lower.contains('heart attack') ||
        lower.contains('breathing') ||
        lower.contains('stroke') ||
        lower.contains('unconscious');

    if (isChestEmergency) {
      return TriageResponse(
        sessionId: 'sim-ses-emergency-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        severity: 'emergency',
        emergencyDetected: true,
        summary: 'CRITICAL EMERGENCY: Severe symptoms requiring immediate medical trauma attention.',
        candidateCondition: 'Potential Acute Coronary / Respiratory Emergency',
        homeRemedies: ['Keep patient calm and seated upright', 'Loosen tight clothing around chest'],
        medicines: [],
        contraindicationWarnings: ['Safety Agent Veto: Oral self-medication prohibited during acute emergency!'],
        doctorReferralNeeded: true,
        routingPath: [
          AgentStepBreadcrumb(agentName: 'Master Agent', status: 'completed', details: 'Parsed acute cardiac distress intent'),
          AgentStepBreadcrumb(agentName: 'Safety Agent', status: 'veto', details: 'Triggered absolute emergency veto!'),
          AgentStepBreadcrumb(agentName: 'Emergency Agent', status: 'active', details: 'Dispatched 108 ambulance reservation token'),
        ],
        genericSavingsTotal: 0.0,
      );
    }

    final isHeadache = lower.contains('headache') || lower.contains('head ache') || lower.contains('migraine');
    final isStomach = lower.contains('stomach') || lower.contains('acidity') || lower.contains('gas') || lower.contains('digestion');
    final isCold = lower.contains('cold') || lower.contains('cough') || lower.contains('throat') || lower.contains('sneez');

    String condition = 'Mild Seasonal Viral Syndrome & Malaise';
    List<String> remedies = [
      'Drink warm water with ginger & honey 3 times daily',
      'Steam inhalation for 5 minutes morning and night',
      'Adequate restorative sleep (7–8 hours)',
    ];
    List<MedicineRecommendation> meds = [
      MedicineRecommendation(
        genericName: 'Paracetamol 500mg Tablet',
        brandedName: 'Crocin / Dolo 500',
        dosageAndUsage: '1 tablet after meals every 6–8 hours as needed for temperature/discomfort',
        rationale: 'First-line antipyretic with high safety profile. Verified non-NSAID safe for documented Aspirin allergy.',
        requiresPrescription: false,
        averageGenericPrice: 18.0,
        averageBrandedPrice: 45.0,
        savingsAmount: 27.0,
      ),
      MedicineRecommendation(
        genericName: 'Cetirizine 10mg Tablet',
        brandedName: 'Zyrtec / Cetzine',
        dosageAndUsage: '1 tablet at bedtime for runny nose and sneezing relief',
        rationale: 'Second-generation non-sedating antihistamine to reduce congestion.',
        requiresPrescription: false,
        averageGenericPrice: 15.0,
        averageBrandedPrice: 42.0,
        savingsAmount: 27.0,
      ),
      MedicineRecommendation(
        genericName: 'Oral Rehydration Salts (ORS) Sachet',
        brandedName: 'Electral',
        dosageAndUsage: 'Dissolve 1 sachet in 1 liter clean drinking water, sip throughout day',
        rationale: 'Maintains optimal electrolyte balance and prevents dehydration.',
        requiresPrescription: false,
        averageGenericPrice: 14.0,
        averageBrandedPrice: 22.0,
        savingsAmount: 8.0,
      ),
    ];

    if (isHeadache) {
      condition = 'Acute Tension Headache & Ocular Strain';
      remedies = [
        'Rest in a quiet, dark, well-ventilated room',
        'Apply cold compress to forehead and temples for 10 minutes',
        'Stay thoroughly hydrated (minimum 2.5L water)',
      ];
      meds = [
        MedicineRecommendation(
          genericName: 'Paracetamol 650mg Tablet',
          brandedName: 'Dolo 650 / Calpol',
          dosageAndUsage: '1 tablet after meals, max 3 times daily',
          rationale: 'Analgesic pain relief safely cleared against documented Aspirin/NSAID allergy.',
          requiresPrescription: false,
          averageGenericPrice: 24.0,
          averageBrandedPrice: 58.0,
          savingsAmount: 34.0,
        ),
      ];
    } else if (isStomach) {
      condition = 'Acid Peptic Indigestion & Reflux';
      remedies = [
        'Sip cold milk or coconut water for immediate esophageal soothing',
        'Avoid spicy, fried, and citrus foods for 48 hours',
        'Eat smaller, frequent meals and avoid lying down immediately after eating',
      ];
      meds = [
        MedicineRecommendation(
          genericName: 'Pantoprazole 40mg Tablet',
          brandedName: 'Pan 40 / Pantocid',
          dosageAndUsage: '1 tablet once daily 30 minutes before breakfast',
          rationale: 'Proton-pump inhibitor to reduce gastric acid production.',
          requiresPrescription: false,
          averageGenericPrice: 28.0,
          averageBrandedPrice: 88.0,
          savingsAmount: 60.0,
        ),
      ];
    } else if (isCold) {
      condition = 'Acute Viral Upper Respiratory Congestion & Cold';
      remedies = [
        'Steam inhalation with eucalyptus 2 times daily',
        'Warm salt water gargle every 4 hours',
        'Hydration with hot herbal ginger-honey tea',
      ];
    }

    return TriageResponse(
      sessionId: 'sim-ses-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      severity: 'routine',
      emergencyDetected: false,
      summary: 'Condition evaluated: $condition. Generic options save up to 65% compared to branded counterparts.',
      candidateCondition: condition,
      homeRemedies: remedies,
      medicines: meds,
      contraindicationWarnings: [
        '🛡️ Allergy Shield Active: Aspirin, Disprin & Ibuprofen strictly blocked based on your encrypted medical vault.'
      ],
      doctorReferralNeeded: false,
      routingPath: [
        AgentStepBreadcrumb(agentName: '1. Master Agent', status: 'completed', details: 'Parsed clinical query'),
        AgentStepBreadcrumb(agentName: '2. Safety Agent', status: 'cleared', details: 'Veto check passed (Non-emergency)'),
        AgentStepBreadcrumb(agentName: '4. Medical History Agent', status: 'completed', details: 'Decrypted active allergy denylist (Aspirin)'),
        AgentStepBreadcrumb(agentName: '3. Symptom Agent', status: 'completed', details: 'Condition matched: $condition'),
        AgentStepBreadcrumb(agentName: '5. Medicine Recommendation', status: 'completed', details: 'Selected safe generic formulations'),
        AgentStepBreadcrumb(agentName: '7. Pharmacy Agent', status: 'completed', details: 'Haversine distance calculated (<0.5 km)'),
      ],
      genericSavingsTotal: meds.fold(0.0, (acc, m) => acc + m.savingsAmount),
      bestDiscountPharmacy: BestDiscountPharmacy(
        pharmacyId: 'pharm-001',
        pharmacyName: 'Sanjeevani Local Chemist',
        address: 'Shop #4, Sector 15 Market, Gurgaon',
        phone: '+91 98101 23456',
        distanceKm: 0.4,
        medicineName: meds.first.genericName,
        genericPrice: meds.first.averageGenericPrice,
        brandedPrice: meds.first.averageBrandedPrice,
        savings: meds.first.savingsAmount,
        discountPercent: 62.0,
      ),
    );
  }

  // ================= NEARBY PHARMACIES =================
  Future<List<Pharmacy>> getNearbyPharmacies({String? query}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final all = [
      Pharmacy(
        id: 'pharm-001',
        name: 'Sanjeevani Local Chemist',
        address: 'Shop #4, Sector 15 Market, Gurgaon',
        phone: '+91 98101 23456',
        distanceKm: 0.4,
        responseTimeMin: 12,
        rating: 4.8,
        isSmallLocalBusiness: true,
        directChatPhone: '+91 98101 23456',
        inventory: _ownerInventory.map((i) => InventoryItem.fromJson({
          'generic_name': i['generic_name'],
          'branded_name': i['branded_name'],
          'generic_price': i['generic_price'],
          'branded_price': i['branded_price'],
          'stock_quantity': i['stock'],
          'in_stock': i['in_stock'],
        })).toList(),
      ),
      Pharmacy(
        id: 'pharm-002',
        name: 'Apollo Pharmacy — Sector 15',
        address: 'SCO 21, Ground Floor, Sector 15 Huda Market',
        phone: '+91 98234 56789',
        distanceKm: 0.8,
        responseTimeMin: 18,
        rating: 4.9,
        isSmallLocalBusiness: false,
        directChatPhone: '+91 98234 56789',
        inventory: [
          InventoryItem(
            genericName: 'Paracetamol 500mg Tablet',
            brandedName: 'Crocin / Dolo',
            genericPrice: 20.0,
            brandedPrice: 45.0,
            stockQuantity: 180,
            inStock: true,
          ),
          InventoryItem(
            genericName: 'Cetirizine 10mg Tablet',
            brandedName: 'Zyrtec',
            genericPrice: 16.0,
            brandedPrice: 42.0,
            stockQuantity: 90,
            inStock: true,
          ),
        ],
      ),
      Pharmacy(
        id: 'pharm-003',
        name: 'Pradhan Mantri Jan Aushadhi Kendra',
        address: 'Booth #12, Near Community Center, Sector 15',
        phone: '+91 98712 34560',
        distanceKm: 1.1,
        responseTimeMin: 25,
        rating: 4.7,
        isSmallLocalBusiness: true,
        directChatPhone: '+91 98712 34560',
        inventory: [
          InventoryItem(
            genericName: 'Paracetamol 500mg Tablet',
            brandedName: 'Generic Govt Lab',
            genericPrice: 12.0,
            brandedPrice: 45.0,
            stockQuantity: 300,
            inStock: true,
          ),
          InventoryItem(
            genericName: 'Pantoprazole 40mg Tablet',
            brandedName: 'Generic Govt Lab',
            genericPrice: 20.0,
            brandedPrice: 88.0,
            stockQuantity: 210,
            inStock: true,
          ),
        ],
      ),
    ];

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      return all.where((p) {
        final matchesName = p.name.toLowerCase().contains(q);
        final matchesMed = p.inventory.any((m) =>
            m.genericName.toLowerCase().contains(q) || m.brandedName.toLowerCase().contains(q));
        return matchesName || matchesMed;
      }).toList();
    }
    return all;
  }

  // ================= ORDERING & TRACKING =================
  Future<OrderResponse> createOrder(CreateOrderRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final subtotal = request.items.fold(0.0, (sum, i) => sum + i.totalPrice);
    final genericSavings = subtotal * 0.60;
    final commission = (subtotal * 0.065); // 6.5% capped commission
    const deliveryFee = 15.0;
    final total = subtotal + deliveryFee;

    final orderId = 'ord-sim-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final orderData = {
      'id': orderId,
      'order_id': orderId,
      'user_id': request.userId,
      'customer_name': 'Rahul Sharma',
      'pharmacy_id': request.pharmacyId,
      'pharmacy_name': 'Sanjeevani Local Chemist',
      'status': 'placed',
      'created_at': DateTime.now().toIso8601String(),
      'subtotal': subtotal,
      'generic_savings': genericSavings,
      'commission_amount': commission,
      'commission_rate': 6.5,
      'delivery_fee': deliveryFee,
      'total_amount': total,
      'payment_method': request.paymentMethod,
      'items': request.items.map((i) => i.toJson()).toList(),
      'tracking_steps': [
        {'title': 'Order Placed', 'time': 'Just now', 'completed': true},
        {'title': 'Waiting Chemist Confirmation', 'time': 'Pending', 'completed': false},
        {'title': 'Packing Generic Items', 'time': 'Pending', 'completed': false},
        {'title': 'Out for Delivery (~15 mins)', 'time': 'Pending', 'completed': false},
        {'title': 'Delivered', 'time': 'Pending', 'completed': false},
      ],
    };

    _orders.insert(0, orderData);

    return OrderResponse(
      orderId: orderId,
      pharmacyId: request.pharmacyId,
      pharmacyName: 'Sanjeevani Local Chemist',
      status: 'CONFIRMED',
      subtotal: subtotal,
      genericSavings: genericSavings,
      totalAmount: total,
      commissionRatePercent: 6.5,
      commissionAmount: commission,
      autoPayApproved: total <= _userPaymentLimit,
      requiresManualConfirmation: total > _userPaymentLimit && !request.bypassLimitConfirmation,
      message: total <= _userPaymentLimit
          ? 'Order confirmed via instant UPI AutoPay'
          : 'Order placed; requires manual limit confirmation',
    );
  }

  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List<Map<String, dynamic>>.from(_orders);
  }

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final match = _orders.firstWhere(
      (o) => o['order_id'] == orderId || o['id'] == orderId,
      orElse: () => _orders.isNotEmpty ? _orders.first : {},
    );
    return Map<String, dynamic>.from(match);
  }

  // ================= EMERGENCY SOS =================
  Future<Map<String, dynamic>> triggerEmergency({
    required String reason,
    double latitude = 28.4680,
    double longitude = 77.0420,
    String userId = ApiConstants.defaultUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'success': true,
      'ticket_id': 'SOS-EMERGENCY-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'ambulance_dispatch': {
        'service': '108 National Ambulance Service',
        'vehicle_no': 'DL-01-AMB-1082',
        'driver_name': 'Suresh Kumar',
        'driver_phone': '+91 98111 22334',
        'eta_minutes': 8,
        'status': 'En route to live GPS location',
      },
      'hospital_trauma_pass': {
        'hospital_name': 'Civil Hospital Trauma ER Center',
        'token_id': 'ER-PASS-8821',
        'distance_km': 1.8,
        'triage_priority': 'Level 1 Immediate Critical Bed Reserve',
      },
    };
  }

  // ================= MEDICAL RECORDS =================
  Future<UserMedicalProfile> getUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return UserMedicalProfile(
      userId: userId,
      name: 'Rahul Sharma',
      email: 'rahul@health.in',
      phone: '+91 98765 43210',
      maxAutoPayLimit: _userPaymentLimit,
      allergies: ['Aspirin', 'Penicillin', 'Sulfonamides'],
      chronicConditions: ['Seasonal Bronchial Allergy'],
      medications: [
        MedicationHistoryItem(
          id: 'med-hist-1',
          medicineName: 'Cetirizine 10mg',
          genericName: 'Cetirizine',
          dosage: '1 tablet at bedtime as needed',
          prescribedBy: 'Dr. Anita Mehta (Civil Hospital)',
          active: true,
        ),
      ],
      clinicalNotes: [
        ClinicalNote(
          date: '10 Aug 2026',
          condition: 'Allergic Rhinitis & Sinus Pressure',
          prescribingSource: 'MediConnect 12-Agent Triage',
          notes: 'Encrypted safety shield verified zero NSAID prescription due to confirmed Aspirin rash history.',
        ),
      ],
    );
  }

  Future<void> updatePaymentLimit(double newLimit) async {
    _userPaymentLimit = newLimit;
  }

  // ================= PHARMACY OWNER DASHBOARD =================
  Future<Map<String, dynamic>> getOwnerDashboard(String pharmacyId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final totalRev = _orders.fold(0.0, (s, o) => s + ((o['total_amount'] as num?)?.toDouble() ?? 0.0));
    final lowStock = _ownerInventory.where((i) => (i['stock'] as num? ?? 0) < 10).length;

    return {
      'pharmacy': {
        'id': pharmacyId,
        'name': 'Sanjeevani Local Chemist',
        'owner_name': 'Ramesh Gupta',
        'address': 'Shop #4, Sector 15 Market, Near Mother Dairy, Gurgaon',
        'phone': '+91 98101 23456',
        'rating': 4.9,
        'response_time_avg': 8,
        'verified': true,
      },
      'sales_summary': {
        'daily_sales': totalRev > 0 ? totalRev : 4250.0,
        'daily_order_count': _orders.isNotEmpty ? _orders.length : 14,
        'total_sales_all_time': totalRev > 0 ? totalRev + 12840.0 : 18500.0,
        'total_order_count': _orders.isNotEmpty ? _orders.length + 32 : 46,
        'average_order_value': 285.0,
        'commission_rate_percent': 6.5,
        'low_stock_items_count': lowStock,
      },
      'highest_ordered_medicines': [
        {'medicine_name': 'Paracetamol 500mg', 'order_count': 24, 'total_revenue': 432.0},
        {'medicine_name': 'Cetirizine 10mg', 'order_count': 18, 'total_revenue': 270.0},
        {'medicine_name': 'Omeprazole 20mg', 'order_count': 15, 'total_revenue': 375.0},
        {'medicine_name': 'Azithromycin 500mg', 'order_count': 11, 'total_revenue': 715.0},
      ],
      'inventory': List<Map<String, dynamic>>.from(_ownerInventory),
      'recent_orders': List<Map<String, dynamic>>.from(_orders),
    };
  }

  Future<void> updateStock({
    required String pharmacyId,
    required String medicineId,
    int? delta,
    int? newStock,
  }) async {
    for (var item in _ownerInventory) {
      if (item['id'] == medicineId || item['generic_name'] == medicineId) {
        if (newStock != null) {
          item['stock'] = newStock;
        } else if (delta != null) {
          item['stock'] = (item['stock'] as int) + delta;
          if (item['stock'] < 0) item['stock'] = 0;
        }
        item['in_stock'] = (item['stock'] as int) > 0;
        break;
      }
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    for (var o in _orders) {
      if (o['order_id'] == orderId || o['id'] == orderId) {
        o['status'] = status;
        break;
      }
    }
  }

  // ================= CHAT =================
  Future<List<Map<String, dynamic>>> getChatMessages(String pharmacyId, String userId) async {
    if (_chatMessages.isEmpty) {
      _chatMessages.addAll([
        {
          'id': 'msg-1',
          'sender_role': 'customer',
          'sender_name': 'Rahul Sharma',
          'message': 'Hello Ramesh ji, do you have Paracetamol 500mg generic strips in stock?',
          'timestamp': '10 mins ago',
        },
        {
          'id': 'msg-2',
          'sender_role': 'pharmacy_owner',
          'sender_name': 'Sanjeevani Chemist',
          'message': 'Yes Rahul ji! Fresh generic batch available at ₹18 per strip. Ready for immediate delivery.',
          'timestamp': '8 mins ago',
        },
      ]);
    }
    return List<Map<String, dynamic>>.from(_chatMessages);
  }

  Future<Map<String, dynamic>> sendChatMessage({
    required String pharmacyId,
    required String userId,
    required String senderRole,
    required String senderName,
    required String message,
  }) async {
    final newMsg = {
      'id': 'msg-${DateTime.now().millisecondsSinceEpoch}',
      'sender_role': senderRole,
      'sender_name': senderName,
      'message': message,
      'timestamp': 'Just now',
    };
    _chatMessages.add(newMsg);
    return {'success': true, 'message': newMsg};
  }

  Future<List<Map<String, dynamic>>> getChatThreads(String pharmacyId) async {
    return [
      {
        'user_id': 'usr-sample-001',
        'customer_name': 'Rahul Sharma',
        'last_message': _chatMessages.isNotEmpty ? _chatMessages.last['message'] : 'Enquiring about generic strip',
        'time': 'Just now',
      }
    ];
  }
}
