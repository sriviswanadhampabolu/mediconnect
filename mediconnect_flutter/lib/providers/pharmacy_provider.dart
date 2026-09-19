import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../models/pharmacy_model.dart';

class LocationPreset {
  final String id;
  final String name;
  final String area;
  final double latitude;
  final double longitude;
  final String expectedPrimaryShop;

  const LocationPreset({
    required this.id,
    required this.name,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.expectedPrimaryShop,
  });
}

class ChemistChatMessage {
  final String sender; // 'user' or 'chemist'
  final String text;
  final DateTime timestamp;

  ChemistChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}

class PharmacyProvider extends ChangeNotifier {
  final ApiService _apiService;

  PharmacyProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService() {
    fetchNearbyPharmacies();
  }

  // Pre-configured Verified NCR Hyperlocal Clusters
  static const List<LocationPreset> locationPresets = [
    LocationPreset(
      id: 'loc-sec15',
      name: 'Sector 15, Gurgaon',
      area: 'Old Gurgaon / Civil Lines',
      latitude: 28.4682,
      longitude: 77.0425,
      expectedPrimaryShop: 'Sanjeevani Local Chemist',
    ),
    LocationPreset(
      id: 'loc-cyber',
      name: 'DLF Cyber Hub / Phase 2',
      area: 'Cyber City, Gurgaon',
      latitude: 28.4952,
      longitude: 77.0895,
      expectedPrimaryShop: 'CyberMed Express & Wellness',
    ),
    LocationPreset(
      id: 'loc-sec29',
      name: 'Sector 29 Leisure Valley',
      area: 'IFFCO Chowk, Gurgaon',
      latitude: 28.4675,
      longitude: 77.0655,
      expectedPrimaryShop: 'Sector 29 Wellness Chemist',
    ),
    LocationPreset(
      id: 'loc-golf',
      name: 'Golf Course Road / Sector 54',
      area: 'Golf Course Ext, Gurgaon',
      latitude: 28.4415,
      longitude: 77.1085,
      expectedPrimaryShop: 'Golf Course MedZone Chemist',
    ),
    LocationPreset(
      id: 'loc-sohna',
      name: 'Sohna Road / Sector 48',
      area: 'Subhash Chowk, Gurgaon',
      latitude: 28.4195,
      longitude: 77.0395,
      expectedPrimaryShop: 'Sohna Road LifeLine Medicos',
    ),
    LocationPreset(
      id: 'loc-cp',
      name: 'Connaught Place, New Delhi',
      area: 'Central Delhi',
      latitude: 28.6318,
      longitude: 77.2170,
      expectedPrimaryShop: 'CP Central Chemist & Surgical',
    ),
  ];

  LocationPreset _currentLocation = locationPresets[0];
  LocationPreset get currentLocation => _currentLocation;

  String _currentAddress = 'Sector 15, Gurgaon';
  String get currentAddress => _currentAddress;

  String _currentVillage = 'Sector 15';
  String get currentVillage => _currentVillage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Pharmacy> _pharmacies = [];
  List<Pharmacy> get pharmacies => _pharmacies;
  List<Pharmacy> get nearbyPharmacies => _pharmacies;

  Pharmacy? _selectedPharmacy;
  Pharmacy? get selectedPharmacy => _selectedPharmacy;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Chemist direct chat messages per pharmacyId
  final Map<String, List<ChemistChatMessage>> _chatMessages = {};

  /// Change active location and immediately update nearby pharmacies and nearest shop name
  Future<void> changeLocation(LocationPreset newLocation) async {
    _currentLocation = newLocation;
    _currentAddress = newLocation.area;
    _currentVillage = newLocation.name;
    _selectedPharmacy = null;
    notifyListeners();

    await fetchNearbyPharmacies();
  }

  /// Change location with full address and village details
  Future<void> changeLocationWithDetails({
    required LocationPreset preset,
    required String fullAddress,
    required String village,
  }) async {
    _currentLocation = preset;
    _currentAddress = fullAddress;
    _currentVillage = village;
    _selectedPharmacy = null;
    notifyListeners();

    await fetchNearbyPharmacies(address: fullAddress, village: village);
  }

  Future<void> fetchNearbyPharmacies({String? query, String? address, String? village}) async {
    _isLoading = true;
    _errorMessage = null;
    _searchQuery = query ?? '';
    notifyListeners();

    try {
      final results = await _apiService.getNearbyPharmacies(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        query: query,
        address: address ?? _currentAddress,
        village: village ?? _currentVillage,
      );
      _pharmacies = results;
      if (_pharmacies.isNotEmpty) {
        _selectedPharmacy = _pharmacies.first;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPharmacy(Pharmacy pharmacy) {
    _selectedPharmacy = pharmacy;
    notifyListeners();
  }

  List<ChemistChatMessage> getMessagesFor(String pharmacyId) {
    if (!_chatMessages.containsKey(pharmacyId)) {
      _chatMessages[pharmacyId] = [
        ChemistChatMessage(
          sender: 'chemist',
          text: 'Hello! Welcome to ${_selectedPharmacy?.name ?? "the neighborhood chemist"}. How can we assist you with medicines or generic savings today?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
      // Asynchronously fetch persistent chats if available
      _loadServerMessages(pharmacyId);
    }
    return _chatMessages[pharmacyId]!;
  }

  Future<void> _loadServerMessages(String pharmacyId, {String userId = "usr-sample-001"}) async {
    try {
      final msgs = await _apiService.getChatMessages(pharmacyId: pharmacyId, userId: userId);
      if (msgs.isNotEmpty) {
        _chatMessages[pharmacyId] = msgs.map((m) {
          DateTime dt;
          try {
            dt = DateTime.parse(m['created_at']);
          } catch (_) {
            dt = DateTime.now();
          }
          return ChemistChatMessage(
            sender: m['sender_role'] == 'owner' ? 'chemist' : 'user',
            text: m['message'] ?? '',
            timestamp: dt,
          );
        }).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  void sendChemistMessage(String pharmacyId, String text, {String userId = "usr-sample-001", String userName = "Patient"}) {
    if (text.trim().isEmpty) return;

    if (!_chatMessages.containsKey(pharmacyId)) {
      getMessagesFor(pharmacyId);
    }

    _chatMessages[pharmacyId]!.add(
      ChemistChatMessage(
        sender: 'user',
        text: text.trim(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    // Persist to server in background
    _apiService.sendChatMessage(
      pharmacyId: pharmacyId,
      userId: userId,
      senderRole: 'customer',
      senderName: userName,
      message: text.trim(),
    ).catchError((_) => <String, dynamic>{});

    // Simulate instant local chemist reply if owner isn't actively replying right now
    Future.delayed(const Duration(seconds: 1), () {
      final replyText = 'Received! We have that in stock at ${_selectedPharmacy?.name ?? "our store"}. Generic is ₹18, branded is ₹45. We can dispatch it right away.';
      _chatMessages[pharmacyId]?.add(
        ChemistChatMessage(
          sender: 'chemist',
          text: replyText,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();

      // Persist simulation to server so owner sees it in their inbox too
      _apiService.sendChatMessage(
        pharmacyId: pharmacyId,
        userId: userId,
        senderRole: 'owner',
        senderName: _selectedPharmacy?.name ?? 'Chemist',
        message: replyText,
      ).catchError((_) => <String, dynamic>{});
    });
  }
}
