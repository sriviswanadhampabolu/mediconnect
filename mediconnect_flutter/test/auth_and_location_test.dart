import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect_flutter/providers/auth_provider.dart';
import 'package:mediconnect_flutter/providers/pharmacy_provider.dart';

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
  });

  group('Pharmacy Location & Shop Switching Tests', () {
    test('Location presets exist with valid primary shop bindings', () {
      expect(PharmacyProvider.locationPresets.length, greaterThanOrEqualTo(5));

      final sec15 = PharmacyProvider.locationPresets.firstWhere((l) => l.id == 'loc-sec15');
      expect(sec15.expectedPrimaryShop, 'Sanjeevani Local Chemist');

      final cyber = PharmacyProvider.locationPresets.firstWhere((l) => l.id == 'loc-cyber');
      expect(cyber.expectedPrimaryShop, 'CyberMed Express & Wellness');

      final cp = PharmacyProvider.locationPresets.firstWhere((l) => l.id == 'loc-cp');
      expect(cp.name, contains('Connaught Place'));
    });

    test('Changing location updates coordinates and active preset', () {
      final prov = PharmacyProvider();
      final initialLoc = prov.currentLocation;
      expect(initialLoc.id, 'loc-sec15');

      final newLoc = PharmacyProvider.locationPresets.firstWhere((l) => l.id == 'loc-cyber');
      prov.changeLocation(newLoc);

      expect(prov.currentLocation.id, 'loc-cyber');
      expect(prov.currentLocation.expectedPrimaryShop, 'CyberMed Express & Wellness');
    });
  });
}
