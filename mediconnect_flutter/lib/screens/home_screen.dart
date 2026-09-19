import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/neu_background.dart';
import '../core/widgets/server_config_dialog.dart';
import '../core/widgets/language_modal.dart';
import '../core/widgets/patient_profile_modal.dart';
import '../core/widgets/location_modal.dart';
import '../core/localization/app_localization.dart';
import '../core/services/voice_service.dart';
import '../providers/triage_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/pharmacy_provider.dart';
import '../providers/auth_provider.dart';
import 'order_checkout_screen.dart';
import 'order_tracking_screen.dart';
import 'chemist_chat_screen.dart';
import 'owner_dashboard_screen.dart';
import '../models/triage_model.dart';
import '../models/order_model.dart';
import '../core/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Current active tab matching GitHub web (0: Triage, 1: Stores, 2: Orders, 3: Health Card, 4: SOS)
  int _currentTab = 0;

  // Selected language code
  String _selectedLangCode = 'en';
  String _selectedLangName = 'English';

  // Voice language dropdown in Triage
  String _selectedVoiceLang = 'हिन्दी (Hindi)';

  // Safety guardrail switch state
  bool _safetyGuardActive = true;

  // Orders tab sub-segmented filter (0: Ordered Meds, 1: Booked Appts)
  int _ordersFilterSegment = 0;

  // Search input in Stores tab
  final TextEditingController _storeSearchController = TextEditingController();

  // Symptom input controller in Triage tab
  final TextEditingController _symptomController = TextEditingController();

  // Chat stream messages: list of {'sender': 'user' | 'ai', 'text': String, 'time': String}
  final List<Map<String, String>> _chatMessages = [];

  // Booked appointments list (matching docs/app.js)
  final List<Map<String, dynamic>> _bookedAppointments = [
    {
      'token_id': 'ER-PASS-8821',
      'hospital_name': 'Civil Hospital Trauma ER Center',
      'distance_km': 1.8,
      'priority': 'Level 1 Immediate Critical Bed Reserve',
      'driver_name': 'Suresh Kumar',
      'driver_phone': '+91 98111 22334',
      'ambulance_no': 'DL-01-AMB-1082',
      'eta_minutes': 8,
      'status': 'En route with oxygen backup',
      'created_at': 'Just now',
    },
  ];

  // Live emergency dispatched state (for SOS tab)
  Map<String, dynamic>? _liveEmergencyDispatched;

  @override
  void dispose() {
    _symptomController.dispose();
    _storeSearchController.dispose();
    super.dispose();
  }

  void _handleSymptomSubmit(String text, {String? voiceTranscript}) {
    if (text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _chatMessages.add({
        'sender': 'user',
        'text': text,
        'time': 'Just now',
      });
      _currentTab = 0; // Ensure on Triage tab
    });

    final pharmacyProv = Provider.of<PharmacyProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final loc = pharmacyProv.currentLocation;
    final userAddr = auth.currentUser?.address;
    final village = auth.currentUser?.address ?? loc.name;

    Provider.of<TriageProvider>(context, listen: false).submitTriage(
      message: text,
      voiceTranscript: voiceTranscript,
      latitude: loc.latitude,
      longitude: loc.longitude,
      userId: auth.currentUser?.id ?? ApiConstants.defaultUserId,
      village: village,
      address: userAddr,
    );
  }

  void _triggerAmbulanceSOS() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.neuBackground,
        title: const Row(
          children: [
            Text('🚨', style: TextStyle(fontSize: 26)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Do you need an Ambulance?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: const Text(
          'We will immediately dispatch the nearest available ambulance (108) with oxygen backup to your GPS location and auto-reserve an emergency trauma ER bay at the closest hospital.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emergency,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _dispatchAmbulanceNow();
            },
            child: const Text('YES, DISPATCH NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _dispatchAmbulanceNow() async {
    final res = await ApiService().triggerEmergency(
      reason: 'Manual SOS Trigger from Mobile App',
    );
    setState(() {
      _liveEmergencyDispatched = res;
      _currentTab = 4; // Switch to SOS tab
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 108 Ambulance Dispatched! Trauma ER Bay Token Reserved.'),
        backgroundColor: AppTheme.emergency,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final triage = Provider.of<TriageProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final pharmacyProv = Provider.of<PharmacyProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // If emergency detected by triage agent, switch to Emergency view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (triage.isEmergencyActive) {
        setState(() => _currentTab = 4);
        triage.dismissEmergency();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NeuBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. TOP SYSTEM BRAND BAR (Fixed header)
              _buildBrandHeaderBar(auth),

              // 2. MAIN SCROLLABLE DASHBOARD WORKSPACE
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: [
                    // Top Squircle Navigation Bar (5 tabs matching docs/index.html)
                    _buildTopSquircleNav(cart),
                    const SizedBox(height: 12),

                    // 3D Safety Guard Tactile Switch Banner
                    _buildSafetyGuardTactileSwitch(triage),
                    const SizedBox(height: 12),

                    // Patient Greeting & Location Banner
                    _buildPatientBanner(pharmacyProv, auth),
                    const SizedBox(height: 12),

                    // Live Order Tracker Banner (if order active)
                    if (cart.lastOrder != null) ...[
                      _buildLiveOrderTrackerBanner(cart),
                      const SizedBox(height: 14),
                    ],

                    // TAB VIEW 0: AI HEALTH TRIAGE
                    if (_currentTab == 0) _buildTriageView(triage, pharmacyProv, cart),

                    // TAB VIEW 1: VERIFIED NEIGHBORHOOD CHEMISTS
                    if (_currentTab == 1) _buildStoresView(pharmacyProv, cart),

                    // TAB VIEW 2: ORDERS & BOOKED APPOINTMENTS
                    if (_currentTab == 2) _buildOrdersView(cart),

                    // TAB VIEW 3: SAFE HEALTH CARD
                    if (_currentTab == 3) _buildHealthCardView(auth),

                    // TAB VIEW 4: EMERGENCY AMBULANCE SOS
                    if (_currentTab == 4) _buildEmergencyView(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 1. TOP SYSTEM BRAND HEADER BAR
  // ==========================================================
  Widget _buildBrandHeaderBar(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.neuBackground.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: AppTheme.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          // Brand Logo
          Container(
            width: 38,
            height: 38,
            decoration: AppTheme.neuSquircle(radius: 12),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('🩺', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Brand Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MediConnect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'AI Health Assistant & Chemist',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Language Selector Pill
          InkWell(
            onTap: () {
              LanguageModal.show(
                context,
                currentCode: _selectedLangCode,
                onSelect: (lang) {
                  AppLocalization().setLanguage(lang.code);
                  setState(() {
                    _selectedLangCode = lang.code;
                    _selectedLangName = lang.nativeName;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language switched to ${lang.nativeName} (${lang.englishName})'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: AppTheme.neuPill(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌐', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    _selectedLangName,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),

          // Chemist Store Portal Pill Button
          InkWell(
            onTap: () {
              auth.switchRole('pharmacy_owner');
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: AppTheme.neuPill(
                active: true,
                activeColor: AppTheme.secondary,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏪', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 3),
                  Text(
                    'Chemist',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.secondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),

          // Server Config / Simulator Mode Pill
          InkWell(
            onTap: () => ServerConfigDialog.show(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: AppTheme.neuPill(
                active: ApiConstants.isSimulatorMode,
                activeColor: AppTheme.warning,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ApiConstants.isSimulatorMode ? Icons.bolt : Icons.wifi,
                    size: 12,
                    color: ApiConstants.isSimulatorMode ? AppTheme.warning : AppTheme.success,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    ApiConstants.isSimulatorMode ? 'Sim' : 'Live',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ApiConstants.isSimulatorMode ? AppTheme.warning : AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),

          // 1-Click Logout
          InkWell(
            onTap: () => auth.logout(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: AppTheme.neuPill(),
              child: const Icon(Icons.logout, size: 14, color: AppTheme.emergency),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 2. TOP SQUIRCLE NAVIGATION BAR (5 Tabs matching docs/index.html)
  // ==========================================================
  Widget _buildTopSquircleNav(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Triage
          _buildSquircleNavItem(
            index: 0,
            icon: '🩺',
            label: 'Triage',
            active: _currentTab == 0,
          ),
          // 2. Pharmacies
          _buildSquircleNavItem(
            index: 1,
            icon: '🏪',
            label: 'Stores',
            active: _currentTab == 1,
          ),
          // 3. Orders
          _buildSquircleNavItem(
            index: 2,
            icon: '📦',
            label: 'Orders',
            badgeCount: cart.items.length,
            active: _currentTab == 2,
          ),
          // 4. Health Card
          _buildSquircleNavItem(
            index: 3,
            icon: '🛡️',
            label: 'Health Card',
            active: _currentTab == 3,
          ),
          // 5. SOS
          _buildSquircleNavItem(
            index: 4,
            icon: '🚨',
            label: 'SOS',
            isEmergency: true,
            active: _currentTab == 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSquircleNavItem({
    required int index,
    required String icon,
    required String label,
    required bool active,
    bool isEmergency = false,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: () {
            setState(() => _currentTab = index);
          },
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 58,
                decoration: AppTheme.neuSquircle(active: active, isEmergency: isEmergency, radius: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isEmergency
                            ? AppTheme.emergency
                            : (active ? AppTheme.primary : AppTheme.textSecondary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 2,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 3. 3D TACTILE SAFETY GUARDRAIL SWITCH BANNER
  // ==========================================================
  Widget _buildSafetyGuardTactileSwitch(TriageProvider triage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppTheme.neuRaised(radius: 18),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: AppTheme.neuSquircle(radius: 10),
            child: const Center(
              child: Text('🛡️', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAFETY GUARD & 6.5% COMMISSION LOCK',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Allergy Denylist Veto + Capped Fair Pricing',
                  style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Tactile Switch Knob (Active / Inactive)
          InkWell(
            onTap: () {
              setState(() => _safetyGuardActive = !_safetyGuardActive);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _safetyGuardActive
                        ? '🛡️ Allergy Shield ACTIVE: Aspirin & NSAIDs strictly blocked.'
                        : '⚠️ Allergy Guardrail OFF: Standard OTC mode.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 52,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: AppTheme.neuSunken(radius: 14),
              child: Row(
                mainAxisAlignment: _safetyGuardActive ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _safetyGuardActive ? AppTheme.primary : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_safetyGuardActive ? AppTheme.primary : Colors.grey).withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _safetyGuardActive ? Icons.check : Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 4. PATIENT BANNER (Avatar, Location, Profile Modal Trigger)
  // ==========================================================
  Widget _buildPatientBanner(PharmacyProvider pharmacyProv, AuthProvider auth) {
    final currentLoc = pharmacyProv.currentLocation;
    final userName = auth.currentUser?.name ?? 'Rahul Sharma';
    final displayAddress = pharmacyProv.currentAddress.isNotEmpty
        ? pharmacyProv.currentAddress
        : (auth.currentUser?.address ?? currentLoc.name);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.neuRaised(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'R',
                  style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppTheme.primary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            displayAddress,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // View Profile Modal Trigger
              InkWell(
                onTap: () => PatientProfileModal.show(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person, size: 13, color: AppTheme.primary),
                      SizedBox(width: 3),
                      Text('Profile', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Change Location Trigger (openLocationModalBtn)
              InkWell(
                key: const Key('openLocationModalBtn'),
                onTap: () => LocationModal.show(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_location_alt, size: 12, color: Colors.white),
                      SizedBox(width: 3),
                      Text('Change 📍', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Meta Badges Row
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _safetyGuardActive ? '🛡️ Guard: Aspirin Blocked' : '⚠️ Guard: Inactive',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔒 Auto-Pay Cap: ₹${(auth.currentUser?.paymentLimit ?? 1500).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 🔒 Safe Auto-Pay Limit Guardrail Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Text('🔒', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Safe Auto-Pay Limit Guardrail',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                      Text(
                        'Available: ₹${auth.safeAutoPayBalance.toStringAsFixed(0)} (Auto-deducted on medicine orders)',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showAddAutoPayDialog(auth),
                  child: const Text('+ Add Amount', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAutoPayDialog(AuthProvider auth) {
    final controller = TextEditingController(text: '500');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🔒', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Expanded(
              child: Text('Safe Auto-Pay Guardrail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add funds to your Auto-Pay limit guardrail. Medicine orders deduct directly from this balance in real-time.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Current Balance: ₹${auth.safeAutoPayBalance.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.success),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [500, 1000, 2000, 5000].map((amt) {
                return ActionChip(
                  label: Text('+₹$amt', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  onPressed: () {
                    controller.text = amt.toString();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to Add (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.trim()) ?? 0;
              if (val > 0) {
                auth.addAutoPayAmount(val);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Added ₹${val.toStringAsFixed(0)} to Safe Auto-Pay Limit Guardrail! New Balance: ₹${auth.safeAutoPayBalance.toStringAsFixed(0)}'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Add to Guardrail'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 5. LIVE ORDER TRACKER BANNER (Active order progress)
  // ==========================================================
  Widget _buildLiveOrderTrackerBanner(CartProvider cart) {
    final order = cart.lastOrder!;
    final shortId = order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Medicine Out for Delivery (~15 mins)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '#$shortId',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF15803D)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${order.pharmacyName} • ₹${order.totalAmount.toStringAsFixed(0)} Paid',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(
                        orderId: order.orderId,
                        initialOrder: order,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Track Live ➔',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar steps
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.70,
              minHeight: 4,
              backgroundColor: Color(0xFFDCFCE7),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('✓ Ordered', style: TextStyle(fontSize: 9.5, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
              Text('● Packed', style: TextStyle(fontSize: 9.5, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
              Text('🛵 In Transit', style: TextStyle(fontSize: 9.5, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
              Text('Delivered', style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB VIEW 0: AI HEALTH TRIAGE (viewHealthCheck)
  // ==========================================================
  Widget _buildTriageView(TriageProvider triage, PharmacyProvider pharmacyProv, CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice & Quick Symptom Input Console
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.neuRaised(radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Where does it hurt? (क्या तकलीफ है?)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 3),
              const Text(
                'Tap the 3D microphone to speak naturally, or select a problem below:',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),

              // Voice Language Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: AppTheme.neuSunken(radius: 12),
                child: Row(
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    const Text(
                      'Voice Dialect:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedVoiceLang,
                          isDense: true,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          items: const [
                            DropdownMenuItem(value: 'English (India)', child: Text('English (India)')),
                            DropdownMenuItem(value: 'हिन्दी (Hindi)', child: Text('हिन्दी (Hindi)')),
                            DropdownMenuItem(value: 'తెలుగు (Telugu)', child: Text('తెలుగు (Telugu)')),
                            DropdownMenuItem(value: 'தமிழ் (Tamil)', child: Text('தமிழ் (Tamil)')),
                            DropdownMenuItem(value: 'বাংলা (Bengali)', child: Text('বাংলা (Bengali)')),
                            DropdownMenuItem(value: 'मराठी (Marathi)', child: Text('मराठी (Marathi)')),
                            DropdownMenuItem(value: 'ગુજરાતી (Gujarati)', child: Text('ગુજરાતી (Gujarati)')),
                            DropdownMenuItem(value: 'ಕನ್ನಡ (Kannada)', child: Text('ಕನ್ನಡ (Kannada)')),
                            DropdownMenuItem(value: 'മലയാളം (Malayalam)', child: Text('മലയാളം (Malayalam)')),
                            DropdownMenuItem(value: 'ਪੰਜਾਬੀ (Punjabi)', child: Text('ਪੰਜਾਬੀ (Punjabi)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedVoiceLang = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3D Microphone Button
              Center(
                child: InkWell(
                  onTap: () => _simulateVoiceRecording(triage),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: AppTheme.neuRaised(radius: 30),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🎙️', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tap to Speak Symptoms',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Multi-lingual AI Audio Speech',
                                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4 Exact Problem Chips with subtexts
              const Text(
                '1-Tap Common Problem Presets:',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.1,
                children: [
                  _buildProblemPresetChip(
                    emoji: '🤕',
                    title: 'Headache & Pain',
                    subtitle: 'Aspirin-safe relief',
                    query: 'Severe headache and mild fatigue since morning',
                  ),
                  _buildProblemPresetChip(
                    emoji: '🤧',
                    title: 'Cold & Cough',
                    subtitle: 'Warm remedies & steam',
                    query: 'Runny nose, sneezing and sore throat for 2 days',
                  ),
                  _buildProblemPresetChip(
                    emoji: '🤢',
                    title: 'Gas & Acidity',
                    subtitle: 'Instant antacid relief',
                    query: 'Stomach burning, acidity and sour burps after meals',
                  ),
                  _buildProblemPresetChip(
                    emoji: '🚨',
                    title: 'Chest Pain',
                    subtitle: 'Ambulance SOS 108',
                    query: 'Severe crushing chest pain radiating to left arm and breathlessness',
                    isEmergency: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Progress bar when evaluating
        if (triage.isLoading) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.neuRaised(radius: 16),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '12 AI Safety Agents evaluating symptoms against encrypted vault...',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Chat stream bubbles
        if (_chatMessages.isNotEmpty) ...[
          ..._chatMessages.map((msg) => _buildChatBubble(msg)),
          const SizedBox(height: 10),
        ],

        // Doctor Advice & Medicine Card
        if (triage.currentTriage != null) ...[
          _buildTriageResultsCard(triage.currentTriage!, pharmacyProv, cart),
          const SizedBox(height: 16),
        ],

        // Bottom Chat Input Bar
        _buildBottomChatBar(triage),
      ],
    );
  }

  Widget _buildProblemPresetChip({
    required String emoji,
    required String title,
    required String subtitle,
    required String query,
    bool isEmergency = false,
  }) {
    return InkWell(
      onTap: () {
        _symptomController.text = query;
        _handleSymptomSubmit(query);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isEmergency
            ? BoxDecoration(
                color: AppTheme.emergencyLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.emergency.withOpacity(0.4)),
              )
            : AppTheme.neuRaised(radius: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isEmergency ? AppTheme.emergency : AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isEmergency ? AppTheme.emergency.withOpacity(0.8) : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateVoiceRecording(TriageProvider triage) {
    final voiceService = VoiceService();
    String detectedText = '';

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.neuBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live Recording Indicator Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTheme.emergency,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'REC ● REAL-TIME CLINICAL AUDIO MICROPHONE',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.emergency,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3D Microphone Pulsing Orb
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🎙️', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Listening in $_selectedVoiceLang (${voiceService.listenSeconds}s)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Speak naturally. Audio is streamed and evaluated by 12 clinical safety agents.',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Real-time animated audio waveforms
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: voiceService.waveAmplitudes.map((amp) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 6,
                        height: 14 + (amp * 36),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Real-time transcribed text stream
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 64),
                    padding: const EdgeInsets.all(14),
                    decoration: AppTheme.neuSunken(radius: 16),
                    child: Text(
                      detectedText.isEmpty
                          ? 'Listening to voice stream... (Speak your symptoms)'
                          : detectedText,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: detectedText.isEmpty ? FontWeight.normal : FontWeight.w600,
                        color: detectedText.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Control actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            voiceService.stopListening();
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Done & Consult AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () {
                            voiceService.stopListening();
                            Navigator.of(ctx).pop();
                            final finalMsg = detectedText.isNotEmpty
                                ? detectedText
                                : (_symptomController.text.isNotEmpty
                                    ? _symptomController.text
                                    : 'Mujhe subah se tez sar dard aur halka bukhar mehsoos ho raha hai');
                            _symptomController.text = finalMsg;
                            _handleSymptomSubmit(finalMsg, voiceTranscript: finalMsg);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Determine speech language code
    String langCode = 'hi-IN';
    if (_selectedVoiceLang.contains('Telugu')) langCode = 'te-IN';
    if (_selectedVoiceLang.contains('Tamil')) langCode = 'ta-IN';
    if (_selectedVoiceLang.contains('English')) langCode = 'en-IN';

    // Start real-time audio voice stream
    voiceService.startListening(
      preferredLanguage: langCode,
      onTranscriptUpdate: (text) {
        detectedText = text;
        _symptomController.text = text;
        if (mounted) setState(() {});
      },
      onComplete: (finalText) {
        if (mounted) {
          _symptomController.text = finalText;
          _handleSymptomSubmit(finalText, voiceTranscript: finalText);
        }
      },
    );
  }

  Widget _buildChatBubble(Map<String, String> msg) {
    final isUser = msg['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: isUser
            ? BoxDecoration(
                color: AppTheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              )
            : AppTheme.neuRaised(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: isUser ? Colors.white : AppTheme.textPrimary,
                fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              msg['time'] ?? '',
              style: TextStyle(
                fontSize: 9.5,
                color: isUser ? Colors.white.withOpacity(0.7) : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriageResultsCard(TriageResponse result, PharmacyProvider pharmacyProv, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.neuRaised(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Condition title & severity badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: result.severity == 'critical_emergency' ? AppTheme.emergencyLight : AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: result.severity == 'critical_emergency' ? AppTheme.emergency : AppTheme.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.candidateCondition.isNotEmpty ? result.candidateCondition : 'Clinical Evaluation',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.summary,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Contraindication Warning
          if (result.contraindicationWarnings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...result.contraindicationWarnings.map(
                    (w) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🛡️ ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            w,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Recommended Medicines list with "Order Generic Now"
          if (result.medicines.isNotEmpty) ...[
            const Text(
              'Verified Generic Medicine Alternatives:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            ...result.medicines.map((med) => _buildMedicineRecommendationCard(med, cart)),
            const SizedBox(height: 12),
          ],

          // Home remedies
          if (result.homeRemedies.isNotEmpty) ...[
            const Text(
              'Natural Home Care & Remedies:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            ...result.homeRemedies.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 14, color: AppTheme.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(r, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 12-Agent Orchestration Log
          if (result.routingPath.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.hub_outlined, size: 14, color: AppTheme.primary),
                SizedBox(width: 4),
                Text(
                  '12-Agent Orchestration Log:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: result.routingPath.map((step) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 10, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        step.agentName,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicineRecommendationCard(MedicineRecommendation med, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Brand: ${med.brandedName}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Save ₹${med.savingsAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹${med.averageGenericPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${med.averageBrandedPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_shopping_cart, size: 14),
                label: const Text('Order Generic', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  cart.addItem(OrderItem(
                    medicineName: med.genericName,
                    isGeneric: true,
                    unitPrice: med.averageGenericPrice,
                    quantity: 1,
                  ));
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrderCheckoutScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomChatBar(TriageProvider triage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: AppTheme.neuRaised(radius: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _symptomController,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Describe symptoms: e.g. "headache since morning"...',
                hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (val) => _handleSymptomSubmit(val),
            ),
          ),
          InkWell(
            onTap: triage.isLoading ? null : () => _handleSymptomSubmit(_symptomController.text),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: triage.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Consult AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB VIEW 1: VERIFIED NEIGHBORHOOD CHEMISTS (viewStores)
  // ==========================================================
  Widget _buildStoresView(PharmacyProvider pharmacyProv, CartProvider cart) {
    final stores = pharmacyProv.nearbyPharmacies;
    final query = _storeSearchController.text.toLowerCase().trim();
    final filteredStores = query.isEmpty
        ? stores
        : stores.where((s) {
            return s.name.toLowerCase().contains(query) ||
                s.address.toLowerCase().contains(query) ||
                s.inventory.any((inv) => inv.medicineName.toLowerCase().contains(query));
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.neuRaised(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🏪 Verified Neighborhood Chemists',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 3),
              const Text(
                'Order genuine generic medicines with verified stock, 5–10% capped commissions, and direct chemist chat.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),

              // Search Medicine Input
              Container(
                decoration: AppTheme.neuSunken(radius: 14),
                child: TextField(
                  controller: _storeSearchController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search medicine (e.g. Paracetamol, Cetirizine)...',
                    hintStyle: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _storeSearchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (filteredStores.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text('No matching chemists or medicines found.', style: TextStyle(color: AppTheme.textSecondary)),
          )
        else
          ...filteredStores.map((store) => _buildStoreCard(store, cart)),
      ],
    );
  }

  Widget _buildStoreCard(store, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.neuRaised(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            store.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Verified',
                            style: TextStyle(color: AppTheme.primaryDark, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${store.address} • ${store.distanceKm.toStringAsFixed(1)} km away',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 12, color: AppTheme.warning),
                    const SizedBox(width: 2),
                    Text(
                      '${store.rating}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Inventory chips
          const Text('In-Stock Formulations:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: store.inventory.map<Widget>((inv) {
              return InkWell(
                onTap: () {
                  cart.addItem(OrderItem(
                    medicineName: inv.medicineName,
                    isGeneric: inv.isGeneric,
                    unitPrice: inv.price,
                    quantity: 1,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${inv.medicineName} to cart (₹${inv.price.toStringAsFixed(0)})'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        inv.medicineName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${inv.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.add, size: 12, color: AppTheme.primary),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Actions: Direct Chat & Order Medicines
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 14),
                  label: const Text('Direct Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChemistChatScreen(
                          pharmacy: store,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                  label: const Text('Order Delivery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    // Populate cart with first generic item if empty
                    if (cart.items.isEmpty && store.inventory.isNotEmpty) {
                      final item = store.inventory.first;
                      cart.addItem(OrderItem(
                        medicineName: item.medicineName,
                        isGeneric: item.isGeneric,
                        unitPrice: item.price,
                        quantity: 1,
                      ));
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OrderCheckoutScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB VIEW 2: ORDERS & BOOKED APPOINTMENTS (viewOrders)
  // ==========================================================
  Widget _buildOrdersView(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.neuRaised(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📦 Orders & Booked Appointments',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 3),
              const Text(
                'Track your previous ordered medicines and booked hospital ER admission passes.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),

              // Segmented switch: Ordered Meds vs Booked Appts
              Container(
                padding: const EdgeInsets.all(3),
                decoration: AppTheme.neuSunken(radius: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _ordersFilterSegment = 0),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _ordersFilterSegment == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _ordersFilterSegment == 0
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '📦 Ordered Meds (${cart.lastOrder != null ? 1 : 0})',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: _ordersFilterSegment == 0 ? AppTheme.primary : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _ordersFilterSegment = 1),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _ordersFilterSegment == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _ordersFilterSegment == 1
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '🏥 Booked Appts (${_bookedAppointments.length})',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: _ordersFilterSegment == 1 ? AppTheme.primary : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Sub-panel 0: Ordered Medicines
        if (_ordersFilterSegment == 0) ...[
          if (cart.lastOrder == null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.neuRaised(radius: 18),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Text('📦', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text('No medicine orders placed yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Consult AI Triage or pick from Stores to place an order.', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                ],
              ),
            )
          else
            _buildPastOrderItemCard(cart.lastOrder!),
        ] else ...[
          // Sub-panel 1: Booked Hospital Appointments
          ..._bookedAppointments.map((appt) => _buildAppointmentCard(appt)),
        ],
      ],
    );
  }

  Widget _buildPastOrderItemCard(OrderResponse order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.neuRaised(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderId.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Chemist: ${order.pharmacyName}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          Text('Total Paid: ₹${order.totalAmount.toStringAsFixed(0)} (Generic Savings ₹${order.genericSavings.toStringAsFixed(0)})',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                  icon: const Icon(Icons.call, size: 14),
                  label: const Text('Call Chemist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📞 Calling Chemist: +91 98101 23456')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.delivery_dining, size: 14),
                  label: const Text('Track Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(orderId: order.orderId, initialOrder: order),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.neuRaised(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.emergencyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appt['token_id'] ?? 'ER-PASS',
                  style: const TextStyle(color: AppTheme.emergency, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              Text(
                'ETA ~${appt['eta_minutes']} mins',
                style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appt['hospital_name'] ?? 'Civil Hospital Trauma Center',
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Priority: ${appt['priority']}',
            style: const TextStyle(fontSize: 11.5, color: AppTheme.emergency, fontWeight: FontWeight.w700),
          ),
          Text(
            'Ambulance (${appt['ambulance_no']}) • Driver: ${appt['driver_name']} (${appt['driver_phone']})',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB VIEW 3: SAFE HEALTH CARD (viewHealthCard)
  // ==========================================================
  Widget _buildHealthCardView(AuthProvider auth) {
    final user = auth.currentUser;
    final allergies = user?.allergies ?? ['Aspirin (Strict Denylist)', 'Penicillin', 'Sulfonamides'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.neuRaised(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: AppTheme.neuSquircle(radius: 12),
                    child: const Center(
                      child: Text('🛡️', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safe Health Profile & Guardrails',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                        ),
                        Text(
                          'AES-256 encrypted medical records and payment limits',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Patient details
              _buildCardDetailRow('Patient ID', user?.id ?? ApiConstants.defaultUserId),
              _buildCardDetailRow('Full Name', user?.name ?? 'Rahul Sharma'),
              _buildCardDetailRow('Phone', user?.contact ?? '+91 98765 43210'),
              _buildCardDetailRow('Delivery Address', user?.address ?? 'DLF Phase 2, Near Cyber Hub, Gurgaon - 122002'),
              _buildCardDetailRow('Safe Auto-Pay Limit Guardrail', '₹${auth.safeAutoPayBalance.toStringAsFixed(0)} available', isHighlight: true),
              _buildCardDetailRow('Per-Order Auto-Pay Cap', '₹${(user?.paymentLimit ?? 1500).toStringAsFixed(0)} / order'),
              const SizedBox(height: 8),

              // Auto-Pay Quick Top-up Button
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Auto-Pay Protection Active', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                          Text('Deducts automatically on medicine order checkout', style: TextStyle(fontSize: 10, color: Color(0xFF15803D))),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showAddAutoPayDialog(auth),
                      child: const Text('+ Top-Up Limit', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Allergies Denylist
              const Text('Encrypted Active Allergy Denylist:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: allergies.map((a) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                    ),
                    child: Text('🛡️ $a', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Edit details trigger
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('✏️ Edit Health Card Details & Allergies', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  onPressed: () => PatientProfileModal.show(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isHighlight ? AppTheme.success : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB VIEW 4: EMERGENCY AMBULANCE SOS (viewEmergency)
  // ==========================================================
  Widget _buildEmergencyView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.neuRaised(radius: 24),
      child: Column(
        children: [
          const Text('🚨', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text(
            'Immediate Emergency Ambulance SOS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Pressing the button below instantly notifies the nearest 108 ambulance with oxygen backup, auto-reserves a trauma ER bay at the closest hospital, and broadcasts your live GPS coordinates.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Big Dispatch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emergency,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 6,
                shadowColor: AppTheme.emergency.withOpacity(0.4),
              ),
              icon: const Icon(Icons.emergency, size: 22),
              label: const Text(
                'DISPATCH AMBULANCE NOW (108)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              onPressed: _triggerAmbulanceSOS,
            ),
          ),
          const SizedBox(height: 16),

          // Dispatched box if active
          if (_liveEmergencyDispatched != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.emergency, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'AMBULANCE DISPATCHED (108 EN ROUTE)',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.emergency),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ticket: ${_liveEmergencyDispatched!['ticket_id'] ?? 'SOS-108-EMERGENCY'}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const Text('Vehicle: DL-01-AMB-1082 • Driver: Suresh Kumar (+91 98111 22334)', style: TextStyle(fontSize: 11)),
                  const Text('Hospital Reserve: Civil Hospital Trauma ER Bay (Token: ER-PASS-8821)', style: TextStyle(fontSize: 11, color: AppTheme.emergency, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // LOCATION PICKER MODAL (3 Tabs: Map, GPS, Manual)
  // ==========================================================
  void _showLocationPickerSheet(BuildContext context, PharmacyProvider pharmacyProv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppTheme.neuBackground,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Select Delivery Location',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Changing your location updates nearby independent pharmacies and automatically switches the serving medical store.',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),

                // Presets list
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
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 18) : null,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        pharmacyProv.changeLocation(loc);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Location changed to ${loc.name}! Serving store: ${loc.expectedPrimaryShop}'),
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
}
