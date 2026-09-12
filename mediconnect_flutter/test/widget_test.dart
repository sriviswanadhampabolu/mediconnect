import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect_flutter/models/triage_model.dart';
import 'package:mediconnect_flutter/models/pharmacy_model.dart';
import 'package:mediconnect_flutter/models/medical_record_model.dart';
import 'package:mediconnect_flutter/providers/cart_provider.dart';

void main() {
  group('MediConnect Flutter Unit Tests', () {
    test('MedicineRecommendation and savings calculation', () {
      final med = MedicineRecommendation(
        genericName: 'Paracetamol 500mg',
        brandedName: 'Crocin 500mg',
        dosageAndUsage: '1 tablet after meals',
        rationale: 'Analgesic and antipyretic',
        requiresPrescription: false,
        averageGenericPrice: 18.0,
        averageBrandedPrice: 38.0,
        savingsAmount: 20.0,
      );

      expect(med.genericName, 'Paracetamol 500mg');
      expect(med.savingsAmount, 20.0);
      expect(med.averageBrandedPrice - med.averageGenericPrice, 20.0);
    });

    test('InventoryItem savings property', () {
      final item = InventoryItem(
        genericName: 'Cetirizine 10mg',
        brandedName: 'Zyrtec 10mg',
        genericPrice: 12.0,
        brandedPrice: 42.0,
        stockQuantity: 50,
        inStock: true,
      );

      expect(item.potentialSavings, 30.0);
    });

    test('CartProvider capped commission (6.5%) and limit check', () {
      final cart = CartProvider();
      final item = InventoryItem(
        genericName: 'Paracetamol 500mg',
        brandedName: 'Crocin 500mg',
        genericPrice: 100.0,
        brandedPrice: 200.0,
        stockQuantity: 10,
        inStock: true,
      );

      final pharmacy = Pharmacy(
        id: 'p1',
        name: 'Neighborhood Chemist',
        address: '123 Health St',
        phone: '9999999999',
        distanceKm: 0.5,
        responseTimeMin: 10,
        rating: 4.8,
        isSmallLocalBusiness: true,
        inventory: [item],
        directChatPhone: '9999999999',
      );

      cart.addItemFromInventory(item, pharmacy, useGeneric: true);
      expect(cart.items.length, 1);
      expect(cart.subtotal, 100.0);
      expect(cart.commissionAmount, closeTo(6.5, 0.01));
      expect(cart.finalTotal, closeTo(106.5, 0.01));
      expect(cart.exceedsPaymentLimit, false);

      // Now add large quantity to exceed ₹1,500 limit
      cart.updateQuantity(0, 20); // 20 * 100 = 2000
      expect(cart.subtotal, 2000.0);
      expect(cart.exceedsPaymentLimit, true);
    });

    test('UserMedicalProfile paymentLimit getter and parsing', () {
      final json = {
        'user_id': 'usr-101',
        'name': 'Rahul Sharma',
        'email': 'rahul@example.com',
        'phone': '+91 98765 43210',
        'payment_limit': 2000.0,
        'allergies': ['Aspirin', 'NSAIDs'],
        'chronic_conditions': ['Mild Gastritis'],
        'medications': [],
        'clinical_notes': [],
      };

      final profile = UserMedicalProfile.fromJson(json);
      expect(profile.paymentLimit, 2000.0);
      expect(profile.maxAutoPayLimit, 2000.0);
      expect(profile.allergies.contains('Aspirin'), true);
    });

    test('TriageResponse hospital appointment details parsing', () {
      final json = {
        'session_id': 'sess-123',
        'user_id': 'usr-101',
        'severity': 'critical_emergency',
        'emergency_detected': true,
        'summary': 'Emergency detected',
        'candidate_condition': 'Acute Cardiac Event',
        'home_remedies': [],
        'medicines': [],
        'contraindication_warnings': [],
        'doctor_referral_needed': true,
        'routing_path': [],
        'generic_savings_total': 0.0,
        'hospital_appointment_suggested': true,
        'hospital_appointment_details': {
          'hospital_name': 'Metro Trauma Center',
          'token_id': 'ER-9912',
          'slot': 'IMMEDIATE PRIORITY ADMISSION',
        },
      };

      final triage = TriageResponse.fromJson(json);
      expect(triage.hospitalAppointmentSuggested, true);
      expect(triage.hospitalAppointmentDetails?['token_id'], 'ER-9912');
      expect(triage.hospitalAppointmentDetails?['hospital_name'], 'Metro Trauma Center');
    });
  });
}
