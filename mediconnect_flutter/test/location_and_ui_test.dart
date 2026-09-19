import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mediconnect_flutter/providers/auth_provider.dart';
import 'package:mediconnect_flutter/providers/triage_provider.dart';
import 'package:mediconnect_flutter/providers/pharmacy_provider.dart';
import 'package:mediconnect_flutter/providers/cart_provider.dart';
import 'package:mediconnect_flutter/providers/profile_provider.dart';
import 'package:mediconnect_flutter/core/localization/app_localization.dart';
import 'package:mediconnect_flutter/screens/home_screen.dart';

void main() {
  testWidgets('Test Location modal open, GPS detect, manual address entry, banner update, and auto-pay guardrail', (WidgetTester tester) async {
    // Set screen size for standard mobile phone
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() => tester.view.resetPhysicalSize());

    final authProvider = AuthProvider();
    final triageProvider = TriageProvider();
    final pharmacyProvider = PharmacyProvider();
    final cartProvider = CartProvider();
    final profileProvider = ProfileProvider();
    final localization = AppLocalization();

    // Create a logged in user
    authProvider.switchRole('customer');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localization),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: triageProvider),
          ChangeNotifierProvider.value(value: pharmacyProvider),
          ChangeNotifierProvider.value(value: cartProvider),
          ChangeNotifierProvider.value(value: profileProvider),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify openLocationModalBtn exists
    final openModalBtn = find.byKey(const Key('openLocationModalBtn'));
    expect(openModalBtn, findsOneWidget);

    // 2. Tap openLocationModalBtn to open Location modal
    await tester.tap(openModalBtn);
    await tester.pumpAndSettle();

    // Verify modal title is visible
    expect(find.text('Select Location'), findsOneWidget);

    // Switch to Auto GPS Tab
    final gpsTab = find.text('🛰️ Auto GPS');
    expect(gpsTab, findsOneWidget);
    await tester.tap(gpsTab);
    await tester.pumpAndSettle();

    // 3. Test GPS Auto-detect button
    expect(find.byKey(const Key('btnAutoDetectGps')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btnAutoDetectGps')));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));

    // Modal closes after GPS auto-detect and coordinates are set
    expect(pharmacyProvider.currentLocation.latitude, isNotNull);
    expect(pharmacyProvider.currentLocation.longitude, isNotNull);

    // 4. Open Location Modal again for Manual Address Entry
    await tester.tap(find.byKey(const Key('openLocationModalBtn')));
    await tester.pumpAndSettle();

    // Switch to Manual Entry Tab
    final manualTab = find.text('✏️ Manual Entry');
    expect(manualTab, findsOneWidget);
    await tester.tap(manualTab);
    await tester.pumpAndSettle();

    // Verify default fields: 'DLF Phase 2, Near Cyber Hub', Gurgaon, 122002
    expect(find.text('DLF Phase 2, Near Cyber Hub'), findsOneWidget);
    expect(find.text('Gurgaon'), findsOneWidget);
    expect(find.text('122002'), findsWidgets);

    // Save Manual Location
    final saveManualBtn = find.byKey(const Key('saveManualLocationBtn'));
    expect(saveManualBtn, findsOneWidget);
    await tester.tap(saveManualBtn);
    await tester.pumpAndSettle();

    // 5. Verify banner updates to DLF Phase 2, Near Cyber Hub, Gurgaon - 122002
    expect(pharmacyProvider.currentAddress, 'DLF Phase 2, Near Cyber Hub, Gurgaon - 122002');
    expect(find.text('DLF Phase 2, Near Cyber Hub, Gurgaon - 122002'), findsOneWidget);

    // 6. Test Safe Auto-Pay Limit Guardrail
    expect(find.text('Safe Auto-Pay Limit Guardrail'), findsOneWidget);
    expect(find.text('+ Add Amount'), findsOneWidget);

    // Tap + Add Amount
    await tester.tap(find.text('+ Add Amount'));
    await tester.pumpAndSettle();

    expect(find.text('Safe Auto-Pay Guardrail'), findsOneWidget);
    expect(find.text('+₹1000'), findsOneWidget);

    // Tap +₹1000 chip and Add to Guardrail
    await tester.tap(find.text('+₹1000'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to Guardrail'));
    await tester.pumpAndSettle();

    // Verify balance increased
    expect(authProvider.safeAutoPayBalance, 2500.0);
  });
}
