import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../models/triage_model.dart';

class TriageProvider extends ChangeNotifier {
  final ApiService _apiService;

  TriageProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  TriageResponse? _currentTriage;
  TriageResponse? get currentTriage => _currentTriage;

  bool _isEmergencyActive = false;
  bool get isEmergencyActive => _isEmergencyActive;

  String _lastUserQuery = '';
  String get lastUserQuery => _lastUserQuery;

  // Active allergy shield description
  final String _activeAllergyGuard = 'Aspirin / NSAIDs (Allergy Protection Active)';
  String get activeAllergyGuard => _activeAllergyGuard;

  Future<void> submitSymptom({
    required String query,
    String? voiceTranscript,
    double latitude = 28.6139,
    double longitude = 77.2090,
    String? village,
    String? address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastUserQuery = query;
    notifyListeners();

    try {
      final response = await _apiService.processTriage(
        message: query,
        voiceTranscript: voiceTranscript,
        latitude: latitude,
        longitude: longitude,
        village: village,
        address: address,
      );

      _currentTriage = response;
      if (response.emergencyDetected || response.severity == 'critical_emergency') {
        _isEmergencyActive = true;
      } else {
        _isEmergencyActive = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetTriage() {
    _currentTriage = null;
    _errorMessage = null;
    _isEmergencyActive = false;
    _lastUserQuery = '';
    notifyListeners();
  }

  void dismissEmergency() {
    _isEmergencyActive = false;
    notifyListeners();
  }
}
