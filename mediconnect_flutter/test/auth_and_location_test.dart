import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect_flutter/providers/auth_provider.dart';
import 'package:mediconnect_flutter/providers/pharmacy_provider.dart';
import 'package:mediconnect_flutter/providers/cart_provider.dart';
import 'package:mediconnect_flutter/core/localization/app_localization.dart';
import 'package:mediconnect_flutter/core/services/voice_service.dart';

void main() {
  group('AuthProvider & Role Tests', () {
    test('UserSession serialization and role detection', () {
      final customerSession = UserSession(
        id: 'usr-customer-1',
        name: 'Test Customer',
        email: 'customer@test.com',
        role: 'customer',
        contact: '+91 9876543210',
        address: 'Sector 15, Gurgaon',
        paymentLimit: 1500.0,
      );

      expect(customerSession.isOwner, false);

      final ownerSession = UserSession(
        id: 'usr-owner-1',
        name: 'Test Owner',
        email: 'owner@test.com',
        role: 'pharmacy_owner',
        storeId: 'pharm-001',
        contact: '+91 9811223344',
        address: 'Shop 4, Market Complex',
        paymentLimit: 50000.0,
      );

      expect(ownerSession.isOwner, true);

      final json = {
        'id': ownerSession.id,
        'name': ownerSession.name,
        'contact': ownerSession.contact,
        'email': ownerSession.email,
        'role': ownerSession.role,
        'store_id': ownerSession.storeId,
        'address': ownerSession.address,
        'payment_limit': ownerSession.paymentLimit,
      };
      final revived = UserSession.fromJson(json);
      expect(revived.id, 'usr-owner-1');
      expect(revived.storeId, 'pharm-001');
      expect(revived.isOwner, true);
    });

    test('AuthProvider state toggling and clearError', () {
      final auth = AuthProvider();
      expect(auth.isLoggedIn, false);
      expect(auth.isOwner, false);
      expect(auth.selectedRole, 'customer');

      auth.setSelectedRole('pharmacy_owner');
      expect(auth.selectedRole, 'pharmacy_owner');

      auth.setSelectedRole('customer');
      expect(auth.selectedRole, 'customer');

      auth.clearError();
      expect(auth.errorMessage, isNull);
    });

    test('Safe Auto-Pay Limit Guardrail add and deduct funds', () {
      final auth = AuthProvider();
      expect(auth.safeAutoPayBalance, 1500.0);

      // Add amount
      auth.addAutoPayAmount(500.0);
      expect(auth.safeAutoPayBalance, 2000.0);

      auth.addAutoPayAmount(1000.0);
      expect(auth.safeAutoPayBalance, 3000.0);

      // Deduct order amount
      final ok = auth.deductAutoPayAmount(350.0);
      expect(ok, true);
      expect(auth.safeAutoPayBalance, 2650.0);

      // Attempting to deduct exceeding amount is blocked by guardrail
      final blocked = auth.deductAutoPayAmount(5000.0);
      expect(blocked, false);
      expect(auth.safeAutoPayBalance, 2650.0);

      // Deducting remaining balance sets to 0
      final cleared = auth.deductAutoPayAmount(2650.0);
      expect(cleared, true);
      expect(auth.safeAutoPayBalance, 0.0);
    });
  });

  group('Pharmacy Location & Manual Address Tests', () {
    test('Location presets exist with valid primary shop bindings', () {
      expect(PharmacyProvider.locationPresets.length, greaterThanOrEqualTo(5));

      final sec15 = PharmacyProvider.locationPresets.firstWhere((l) => l.id == 'loc-sec15');
      expect(sec15.expectedPrimaryShop, 'Sanjeevani Local Chemist');

      final cyber = PharmacyProvider.locationPresets.firstWhere((l) => l.id == 'loc-cyber');
      expect(cyber.expectedPrimaryShop, 'CyberMed Express & Wellness');

      final cp = PharmacyProvider.locationPresets.firstWhere((l) => l.id == 'loc-cp');
      expect(cp.name, contains('Connaught Place'));
    });

    test('Changing location to DLF Phase 2 Cyber Hub updates address and store', () {
      final prov = PharmacyProvider();
      final initialLoc = prov.currentLocation;
      expect(initialLoc.id, 'loc-sec15');

      // Manual address change to DLF Phase 2, Near Cyber Hub, Gurgaon - 122002
      prov.changeLocationWithDetails(
        preset: const LocationPreset(
          id: 'loc-dlf2',
          name: 'DLF Phase 2, Near Cyber Hub',
          area: 'DLF Cyber City, Sector 24, Gurgaon - 122002',
          latitude: 28.4905,
          longitude: 77.0898,
          expectedPrimaryShop: 'CyberMed Express & Wellness',
        ),
        fullAddress: 'DLF Phase 2, Near Cyber Hub, Gurgaon - 122002',
        village: 'DLF Cyber City, Sector 24',
      );

      expect(prov.currentAddress, 'DLF Phase 2, Near Cyber Hub, Gurgaon - 122002');
      expect(prov.currentVillage, 'DLF Cyber City, Sector 24');
      expect(prov.currentLocation.latitude, closeTo(28.4905, 0.001));
      expect(prov.currentLocation.longitude, closeTo(77.0898, 0.001));
      expect(prov.currentLocation.expectedPrimaryShop, 'CyberMed Express & Wellness');
    });
  });

  group('Cart Guardrail Limit Tests', () {
    test('checkExceedsLimit evaluates against user auto-pay guardrail', () {
      final cart = CartProvider();
      expect(cart.checkExceedsLimit(1500.0), false);
    });
  });

  group('Whole-App Multi-Language Localization Tests', () {
    test('AppLocalization switches language and returns translated strings', () {
      final loc = AppLocalization();

      // English default
      loc.setLanguage('en');
      expect(loc.currentLanguageCode, 'en');
      expect(loc.t('brandTitle'), 'MediConnect');
      expect(loc.t('btnAutoDetectGps'), '📍 Auto-Detect via GPS');
      expect(loc.t('safeAutoPayTitle'), 'Safe Auto-Pay Limit Guardrail');

      // Hindi
      loc.setLanguage('hi');
      expect(loc.currentLanguageCode, 'hi');
      expect(loc.t('brandTitle'), 'मेडीकनेक्ट');
      expect(loc.t('btnAutoDetectGps'), '📍 जीपीएस से मेरा स्थान खोजें');
      expect(loc.t('safeAutoPayTitle'), 'सुरक्षित ऑटो-पे सीमा (गार्डरेल)');

      // Telugu
      loc.setLanguage('te');
      expect(loc.currentLanguageCode, 'te');
      expect(loc.t('brandTitle'), 'మెడికనెక్ట్');
      expect(loc.t('safeAutoPayTitle'), 'సురక్షిత ఆటో-పే పరిమితి గార్డ్‌రైల్');

      // Tamil
      loc.setLanguage('ta');
      expect(loc.currentLanguageCode, 'ta');
      expect(loc.t('brandTitle'), 'மெடிகனெக்ட்');

      // Bengali
      loc.setLanguage('bn');
      expect(loc.currentLanguageCode, 'bn');
      expect(loc.t('brandTitle'), 'মেডিকানেক্ট');

      // Marathi
      loc.setLanguage('mr');
      expect(loc.currentLanguageCode, 'mr');
      expect(loc.t('brandTitle'), 'मेडीकनेक्ट');
    });
  });

  group('Real-Time VoiceService Tests', () {
    test('VoiceService starts, stops, and produces wave amplitudes', () {
      final voice = VoiceService();
      expect(voice.isListening, false);
      expect(voice.waveAmplitudes.length, greaterThanOrEqualTo(5));

      voice.setVoiceLanguage('hi-IN');
      expect(voice.voiceLanguageCode, 'hi-IN');

      String lastTranscript = '';
      voice.startListening(
        onTranscriptUpdate: (t) => lastTranscript = t,
        onComplete: (f) => lastTranscript = f,
      );

      expect(voice.isListening, true);
      voice.stopListening();
      expect(voice.isListening, false);
    });
  });
}

