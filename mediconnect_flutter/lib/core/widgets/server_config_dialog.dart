import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../theme/app_theme.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConstants.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final inputUrl = _urlController.text.trim();
      var target = inputUrl;
      if (target.endsWith('/')) target = target.substring(0, target.length - 1);
      if (!target.endsWith('/api')) target = '$target/api';

      final res = await http.get(Uri.parse('$target/pharmacy/nearby')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        setState(() {
          _isTesting = false;
          _testSuccess = true;
          _testResult = 'Connected successfully! Server is online.';
        });
      } else {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Server responded with HTTP ${res.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'Could not reach server. Offline simulator will be used automatically.';
      });
    }
  }

  void _saveAndApply(String url, bool simulator) {
    if (simulator) {
      ApiConstants.enableSimulatorMode();
    } else {
      ApiConstants.setBaseUrl(url);
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(simulator
            ? '⚡ Switched to Offline Simulator Mode (Works Everywhere)'
            : '🟢 Backend URL updated to: ${ApiConstants.baseUrl}'),
        backgroundColor: simulator ? AppTheme.warning : AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSim = ApiConstants.isSimulatorMode;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.neuRaised(radius: 24, color: AppTheme.surface),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: AppTheme.neuSquircle(radius: 14),
                  child: const Center(
                    child: Icon(Icons.settings_ethernet, color: AppTheme.primary, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Server Connection',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Configure backend IP or offline simulation',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Current Active Mode Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSim ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSim ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSim ? Icons.bolt : Icons.check_circle,
                    size: 18,
                    color: isSim ? const Color(0xFFB45309) : const Color(0xFF15803D),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSim
                          ? 'Offline Simulator Mode: Active (Complete self-contained offline dataset)'
                          : 'Live Backend Mode: Active (${ApiConstants.baseUrl})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSim ? const Color(0xFFB45309) : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Preset Buttons
            const Text(
              'QUICK CONNECTION PRESETS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: () => _saveAndApply('https://mediconnect-yt1e.onrender.com/api', false),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: AppTheme.neuRaised(radius: 14),
                child: const Row(
                  children: [
                    Text('☁️', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Render Cloud Live Backend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                          Text('https://mediconnect-yt1e.onrender.com/api', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: () => _saveAndApply('', true),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: AppTheme.neuRaised(radius: 14),
                child: const Row(
                  children: [
                    Text('⚡', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Offline Simulator Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Works 100% reliably without running any Python server', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: () => _saveAndApply('http://10.0.2.2:8000/api', false),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: AppTheme.neuRaised(radius: 14),
                child: const Row(
                  children: [
                    Text('📱', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Android Studio Emulator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Connect to 10.0.2.2:8000 (host machine)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Custom Server URL
            const Text(
              'OR ENTER CUSTOM BACKEND IP / DOMAIN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: AppTheme.neuSunken(radius: 16),
              child: TextField(
                controller: _urlController,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. http://192.168.1.15:8000/api',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.link, size: 20, color: AppTheme.primary),
                ),
              ),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: _testSuccess ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_tethering, size: 16),
                    label: Text(_isTesting ? 'Testing...' : 'Test Connection', style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _saveAndApply(_urlController.text, false),
                    child: const Text('Save & Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
