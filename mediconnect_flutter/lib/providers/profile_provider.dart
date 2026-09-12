import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../models/medical_record_model.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiService _apiService;

  ProfileProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserMedicalProfile? _profile;
  UserMedicalProfile? get profile => _profile;

  Future<void> fetchProfile({String userId = ApiConstants.defaultUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.getUserProfile(userId: userId);
      _profile = data;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
