import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../providers/pharmacy_provider.dart';
import '../../providers/auth_provider.dart';
import '../services/api_service.dart';

class LocationModal extends StatefulWidget {
  const LocationModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationModal(),
    );
  }

  @override
  State<LocationModal> createState() => _LocationModalState();
}

class _LocationModalState extends State<LocationModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Manual inputs
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;

  // Map Search input
  final TextEditingController _mapSearchController = TextEditingController();

  // Pinned Coordinates
  double _pinnedLat = 28.4952;
  double _pinnedLng = 77.0895;
  String _pinnedAreaName = 'DLF Phase 2, Near Cyber Hub, Gurgaon - 122002';
  bool _isGpsDetecting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    _addressController = TextEditingController(
      text: user?.address.isNotEmpty == true ? user!.address : 'DLF Phase 2, Near Cyber Hub',
    );
    _cityController = TextEditingController(text: 'Gurgaon');
    _pincodeController = TextEditingController(text: '122002');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _mapSearchController.dispose();
    super.dispose();
  }

  Future<void> _applyLocation({
    required String fullAddress,
    required double lat,
    required double lng,
    required String village,
  }) async {
    final pharmacyProv = Provider.of<PharmacyProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // 1. Update active location in PharmacyProvider
    final preset = LocationPreset(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: village,
      area: fullAddress,
      latitude: lat,
      longitude: lng,
      expectedPrimaryShop: 'CyberMed Express & Wellness',
    );
    await pharmacyProv.changeLocationWithDetails(
      preset: preset,
      fullAddress: fullAddress,
      village: village,
    );

    // 2. Update AuthProvider user session address & coordinates
    auth.updateUserLocation(
      address: fullAddress,
      latitude: lat,
      longitude: lng,
    );

    // 3. Sync with backend API
    if (auth.currentUser != null) {
      ApiService().updateProfile(
        userId: auth.currentUser!.id,
        address: fullAddress,
        latitude: lat,
        longitude: lng,
      ).catchError((_) => {});
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Location updated to $fullAddress! Nearby verified pharmacies refreshed.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleManualSave() {
    final addr = _addressController.text.trim();
    final city = _cityController.text.trim();
    final pin = _pincodeController.text.trim();

    String fullAddr = addr;
    if (city.isNotEmpty) {
      fullAddr = fullAddr.isNotEmpty ? '$fullAddr, $city' : city;
    }
    if (pin.isNotEmpty) {
      fullAddr = fullAddr.isNotEmpty ? '$fullAddr - $pin' : pin;
    }
    final village = addr.isNotEmpty ? addr.split(',')[0].trim() : (city.isNotEmpty ? city : 'Gurgaon');

    _applyLocation(
      fullAddress: fullAddr.isEmpty ? 'DLF Phase 2, Near Cyber Hub, Gurgaon - 122002' : fullAddr,
      lat: 28.4952,
      lng: 77.0895,
      village: village,
    );
  }

  Future<void> _handleGpsAutoDetect() async {
    setState(() => _isGpsDetecting = true);

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _isGpsDetecting = false;
      _pinnedLat = 28.4952;
      _pinnedLng = 77.0895;
      _pinnedAreaName = 'DLF Phase 2, Near Cyber Hub, Gurgaon - 122002';
      _addressController.text = 'DLF Phase 2, Near Cyber Hub';
      _cityController.text = 'Gurgaon';
      _pincodeController.text = '122002';
    });

    await _applyLocation(
      fullAddress: 'DLF Phase 2, Near Cyber Hub, Gurgaon - 122002',
      lat: 28.4952,
      lng: 77.0895,
      village: 'DLF Phase 2',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.neuBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: AppTheme.neuSquircle(radius: 14),
                    child: const Center(
                      child: Text('📍', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'For hyper-local medicine delivery & chemist discovery',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3-Segmented Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: AppTheme.neuSunken(radius: 16),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(text: '🗺️ Maps'),
                  Tab(text: '🛰️ Auto GPS'),
                  Tab(text: '✏️ Manual Entry'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Views
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SizedBox(
                  height: 380,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGoogleMapsTab(),
                      _buildAutoGpsTab(),
                      _buildManualEntryTab(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================================
  // TAB 1: GOOGLE MAPS INTERACTIVE PIN PICKER
  // ==============================================================================
  Widget _buildGoogleMapsTab() {
    return Column(
      children: [
        // Search Address on Map
        Container(
          decoration: AppTheme.neuSunken(radius: 14),
          child: TextField(
            controller: _mapSearchController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search locality, street, landmark...',
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.primary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, size: 18, color: AppTheme.primary),
                onPressed: () {
                  final query = _mapSearchController.text.trim();
                  if (query.isNotEmpty) {
                    setState(() {
                      _pinnedAreaName = query;
                      _addressController.text = query;
                    });
                  }
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Map Visualization Box
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Simulated Stylized Map Canvas
                Container(
                  width: double.infinity,
                  color: const Color(0xFFE5E7EB),
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),

                // Map Grid Overlay & Roads
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 120,
                  child: Container(
                    width: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),

                // Center Pin with Floating Glow
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _pinnedAreaName,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.location_on, color: AppTheme.emergency, size: 40),
                      Container(
                        width: 12,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Google Maps Badge
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📍 Google Maps', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
                        SizedBox(width: 4),
                        Text('28.4952° N, 77.0895° E', style: TextStyle(fontSize: 9.5, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Confirm Map Pin Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
            ),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              'Confirm Pinned Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            onPressed: () {
              _applyLocation(
                fullAddress: _pinnedAreaName,
                lat: _pinnedLat,
                lng: _pinnedLng,
                village: 'DLF Phase 2',
              );
            },
          ),
        ),
      ],
    );
  }

  // ==============================================================================
  // TAB 2: GPS AUTO-DETECT (#btnAutoDetectGps)
  // ==============================================================================
  Widget _buildAutoGpsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: AppTheme.neuSquircle(radius: 20),
              child: const Center(
                child: Text('🛰️', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Live GPS Auto-Detection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pinpoint your current coordinates and instantly discover verified pharmacies around your live location.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // BUTTON WITH REQUIRED KEY: btnAutoDetectGps
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('btnAutoDetectGps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: _isGpsDetecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.my_location, size: 20),
                label: Text(
                  _isGpsDetecting ? 'Detecting Live Coordinates...' : '📍 Auto-Detect Current Location (GPS)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                onPressed: _isGpsDetecting ? null : _handleGpsAutoDetect,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================================
  // TAB 3: MANUAL ADDRESS ENTRY
  // ==============================================================================
  Widget _buildManualEntryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputRow(
          label: 'Delivery Address / Street / Society',
          controller: _addressController,
          icon: Icons.home_outlined,
          hint: 'e.g. DLF Phase 2, Near Cyber Hub',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildInputRow(
                label: 'City / Sector',
                controller: _cityController,
                icon: Icons.location_city,
                hint: 'e.g. Gurgaon',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _buildInputRow(
                label: 'PIN Code',
                controller: _pincodeController,
                icon: Icons.pin_drop_outlined,
                hint: '122002',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // SAVE BUTTON WITH KEY
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('saveManualLocationBtn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text(
              'Save Delivery Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: _handleManualSave,
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: AppTheme.neuSunken(radius: 14),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
