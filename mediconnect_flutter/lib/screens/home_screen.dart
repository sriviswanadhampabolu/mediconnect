import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/triage_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/pharmacy_provider.dart';
import '../providers/auth_provider.dart';
import 'emergency_screen.dart';
import 'pharmacy_list_screen.dart';
import 'records_screen.dart';
import 'order_checkout_screen.dart';
import 'order_tracking_screen.dart';
import 'hospital_booking_screen.dart';
import 'payment_settings_screen.dart';
import 'orders_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _symptomController = TextEditingController();

  final List<String> _quickSymptoms = [
    'Mild headache & tiredness',
    'Fever and body ache for 2 days',
    'Seasonal runny nose & sneezing',
    'Severe crushing chest pain & breathlessness',
    'Throat irritation & mild cough',
  ];

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  void _handleSymptomSubmit(String text, {String? voiceTranscript}) {
    if (text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    Provider.of<TriageProvider>(context, listen: false).submitSymptom(
      query: text.trim(),
      voiceTranscript: voiceTranscript,
    );
  }

  @override
  Widget build(BuildContext context) {
    final triage = Provider.of<TriageProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final pharmacyProv = Provider.of<PharmacyProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Auto-navigate or display emergency if critical
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (triage.isEmergencyActive) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmergencyScreen(
              emergencyReason: triage.currentTriage?.summary ?? 'Life-Threatening Emergency Detected',
            ),
          ),
        );
        triage.dismissEmergency();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.health_and_safety, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MediConnect',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                Text(
                  'Hyperlocal Health & Pharmacy',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Orders History',
            icon: const Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrdersListScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Payment Limits & Transparency',
            icon: const Icon(Icons.shield_outlined, color: AppTheme.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaymentSettingsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Medical Vault & Allergies',
            icon: const Icon(Icons.folder_shared_outlined, color: AppTheme.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecordsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Cart & Checkout',
            icon: Stack(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: AppTheme.textPrimary),
                if (cart.items.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.items.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderCheckoutScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout / Switch Role',
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: () {
              auth.logout();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emergency,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.emergency, size: 16),
              label: const Text('SOS 108', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EmergencyScreen(emergencyReason: 'User pressed manual SOS 108'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dynamic Hyperlocal Location Selector & Serving Shop Banner
          _buildLocationSelectorBar(pharmacyProv),
          const SizedBox(height: 12),

          // User Greeting & Allergy Shield Card
          _buildGreetingAndAllergyCard(triage.activeAllergyGuard, auth),
          const SizedBox(height: 16),

          // Quick Navigation Bar to Orders and Nearby Pharmacies
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrdersListScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.receipt_long, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Track & receipts', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PharmacyListScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront, color: AppTheme.secondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nearby Stores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(pharmacyProv.selectedPharmacy?.name ?? 'Local Chemists',
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Order Tracker Banner (if an order is placed)
          if (cart.lastOrder != null) ...[
            _buildActiveOrderBanner(cart),
            const SizedBox(height: 16),
          ],

          // Symptom Triage Box
          _buildTriageInputBox(triage),
          const SizedBox(height: 20),

          // Quick Symptom Chips
          _buildQuickSymptomChips(),
          const SizedBox(height: 20),

          // Error Message
          if (triage.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.emergencyLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.emergency.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.emergency),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      triage.errorMessage!,
                      style: const TextStyle(color: AppTheme.emergency, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Multi-Agent Breadcrumbs
          if (triage.currentTriage != null && triage.currentTriage!.routingPath.isNotEmpty) ...[
            _buildAgentBreadcrumbs(triage.currentTriage!.routingPath),
            const SizedBox(height: 20),
          ],

          // Triage Results Section
          if (triage.currentTriage != null) ...[
            _buildTriageResults(triage.currentTriage!),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSelectorBar(PharmacyProvider pharmacyProv) {
    final currentLoc = pharmacyProv.currentLocation;
    final primaryShop = pharmacyProv.selectedPharmacy?.name ?? currentLoc.expectedPrimaryShop;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showLocationPickerSheet(context, pharmacyProv),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        currentLoc.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.primary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Serving Store: $primaryShop',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Switch Area', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPickerSheet(BuildContext context, PharmacyProvider pharmacyProv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_outlined, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 8),
                    const Text('Select Hyperlocal Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Changing your location updates nearby independent pharmacies and automatically switches the serving medical store name.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                // Google Maps Option Card
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.map_rounded, color: Color(0xFF16A34A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google Maps / Pin Location',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                            ),
                            Text(
                              'Interactive pin: 28.4682° N, 77.0425° E',
                              style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📍 Location set via Google Maps: Sector 15 Market, Gurgaon')),
                          );
                        },
                        child: const Text('Pin Map', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                ...PharmacyProvider.locationPresets.map((loc) {
                  final isSelected = pharmacyProv.currentLocation.id == loc.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                      title: Text(
                        loc.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Chemist: ${loc.expectedPrimaryShop} • ${loc.area}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                          : null,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        pharmacyProv.changeLocation(loc);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Location changed to ${loc.name}! Shop updated to ${loc.expectedPrimaryShop}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreetingAndAllergyCard(String allergyGuard, AuthProvider auth) {
    final userName = auth.currentUser?.name ?? 'Rahul Sharma';
    final userContact = auth.currentUser?.contact ?? 'Verified Patient ID: usr-101';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'R';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryLight,
                child: Text(initial, style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, $userName!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text(userContact, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '● Live Guard',
                  style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 18, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allergyGuard,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderBanner(CartProvider cart) {
    final order = cart.lastOrder!;
    final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Order #$shortId',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.pharmacyName} • ₹${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(
                    orderId: order.orderId,
                    initialOrder: order,
                  ),
                ),
              );
            },
            child: const Text('Track Live'),
          ),
        ],
      ),
    );
  }

  Widget _buildTriageInputBox(TriageProvider triage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Describe Your Symptoms',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'AI Safety Agents will triage, cross-check allergies, and recommend safe care.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _symptomController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g., I have a fever, body pain and headache since morning...',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.mic, size: 18),
                label: const Text('Voice Input (Indian Languages)'),
                onPressed: triage.isLoading
                    ? null
                    : () {
                        _showVoiceInputModal(triage);
                      },
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: triage.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(triage.isLoading ? 'Triaging...' : 'Analyze Care'),
                onPressed: triage.isLoading
                    ? null
                    : () => _handleSymptomSubmit(_symptomController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSymptomChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Test Scenarios',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickSymptoms.map((symptom) {
            final isEmergency = symptom.contains('chest pain');
            return ActionChip(
              backgroundColor: isEmergency ? AppTheme.emergencyLight : AppTheme.surfaceVariant,
              side: BorderSide(
                color: isEmergency ? AppTheme.emergency.withOpacity(0.4) : AppTheme.border,
              ),
              label: Text(
                symptom,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isEmergency ? FontWeight.bold : FontWeight.w500,
                  color: isEmergency ? AppTheme.emergency : AppTheme.textPrimary,
                ),
              ),
              onPressed: () {
                _symptomController.text = symptom;
                _handleSymptomSubmit(symptom);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgentBreadcrumbs(List routingPath) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub_outlined, size: 16, color: AppTheme.primary),
              SizedBox(width: 6),
              Text(
                '12-Agent Orchestration Log',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: routingPath.map((step) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 12, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      step.agentName,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTriageResults(triageResult) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Condition Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: triageResult.severity == 'critical_emergency'
                          ? AppTheme.emergencyLight
                          : AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      triageResult.severity.toString().toUpperCase(),
                      style: TextStyle(
                        color: triageResult.severity == 'critical_emergency'
                            ? AppTheme.emergency
                            : AppTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      triageResult.candidateCondition ?? 'Triage Evaluation',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                triageResult.summary,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Contraindication / Allergy Warnings
        if (triageResult.contraindicationWarnings.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.warningLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Safety Guardrail Triggered',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...triageResult.contraindicationWarnings.map((warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $warning', style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Hospital / Clinic Consultation Suggestion
        if (triageResult.hospitalAppointmentSuggested && triageResult.hospitalAppointmentDetails != null) ...[
          _buildHospitalConsultationCard(triageResult.hospitalAppointmentDetails!),
        ],

        // Safe OTC Medicine Recommendations
        if (triageResult.medicines.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended Safe Medicines',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              TextButton.icon(
                icon: const Icon(Icons.storefront, size: 16),
                label: const Text('Find in Nearby Shops'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PharmacyListScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...triageResult.medicines.map((med) => _buildMedicineCard(med)),
          const SizedBox(height: 16),
        ],

        // Home Remedies
        if (triageResult.homeRemedies.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.spa_outlined, color: AppTheme.success, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Natural Supportive Home Care',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...triageResult.homeRemedies.map((remedy) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check, size: 16, color: AppTheme.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(remedy, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMedicineCard(med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.genericName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Branded alternative: ${med.brandedName}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Save ₹${med.savingsAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Generic Price', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      Text('₹${med.averageGenericPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                    ],
                  ),
                ),
                Container(height: 24, width: 1, color: AppTheme.border),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Branded Price', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text(
                          '₹${med.averageBrandedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dosage: ${med.dosageAndUsage}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalConsultationCard(Map<String, dynamic> details) {
    final name = details['hospital_name'] ?? 'Local Healthcare Facility';
    final slot = details['slot'] ?? 'Immediate Priority';
    final isEr = details['booking_type'] == 'EMERGENCY_PRIORITY_ADMISSION';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isEr ? AppTheme.emergencyLight : AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isEr ? AppTheme.emergency : AppTheme.primary).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isEr ? Icons.local_hospital : Icons.medical_services_outlined,
                  color: isEr ? AppTheme.emergency : AppTheme.primaryDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEr ? 'Emergency Admission Pass Auto-Booked' : 'Clinical Consultation Recommended',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isEr ? AppTheme.emergency : AppTheme.primaryDark,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$name — $slot',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            details['instructions'] ?? 'Clinical examination recommended before automated medication.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isEr ? AppTheme.emergency : AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.confirmation_number_outlined, size: 16),
              label: Text(isEr ? 'View Priority ER Pass' : 'View Clinic Details'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HospitalBookingScreen(
                      appointmentDetails: details,
                      isEmergency: isEr,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showVoiceInputModal(TriageProvider triage) {
    String selectedVoiceLang = 'hi-IN';
    final langList = [
      {'code': 'hi-IN', 'name': 'हिन्दी (Hindi)'},
      {'code': 'en-IN', 'name': 'English (India)'},
      {'code': 'te-IN', 'name': 'తెలుగు (Telugu)'},
      {'code': 'ta-IN', 'name': 'தமிழ் (Tamil)'},
      {'code': 'bn-IN', 'name': 'বাংলা (Bengali)'},
      {'code': 'mr-IN', 'name': 'मराठी (Marathi)'},
      {'code': 'gu-IN', 'name': 'ગુજરાતી (Gujarati)'},
      {'code': 'kn-IN', 'name': 'ಕನ್ನಡ (Kannada)'},
      {'code': 'ml-IN', 'name': 'മലയാളം (Malayalam)'},
      {'code': 'pa-IN', 'name': 'ਪੰਜਾਬੀ (Punjabi)'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mic, color: AppTheme.primary, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Voice Assistant (Indian Languages)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Detect any Indian language. Speak your symptoms and AI will triage immediately:',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedVoiceLang,
                      decoration: InputDecoration(
                        labelText: 'Select Spoken Language',
                        prefixIcon: const Icon(Icons.translate, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: langList.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['code'],
                          child: Text(item['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedVoiceLang = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        final samplePhrases = {
                          'hi-IN': 'मुझे कल से तेज़ बुखार और सिर दर्द है',
                          'te-IN': 'నాకు నిన్నటి నుండి జ్వరం మరియు తలనొప్పి ఉంది',
                          'ta-IN': 'எனக்கு நேற்று முதல் காய்ச்சல் மற்றும் தலைவலி உள்ளது',
                          'en-IN': 'I have mild throat soreness and mild fever since yesterday.',
                        };
                        final phrase = samplePhrases[selectedVoiceLang] ?? 'I have mild throat soreness and mild fever since yesterday.';
                        _symptomController.text = phrase;
                        _handleSymptomSubmit(
                          phrase,
                          voiceTranscript: 'Audio transcribed ($selectedVoiceLang): $phrase',
                        );
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2),
                        ),
                        child: const Icon(Icons.mic, color: AppTheme.primary, size: 36),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap microphone to speak naturally',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
