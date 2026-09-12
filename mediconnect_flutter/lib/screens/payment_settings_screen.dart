import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import '../providers/profile_provider.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _limitController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final profileProv = Provider.of<ProfileProvider>(context, listen: false);
    if (profileProv.profile == null) {
      profileProv.fetchProfile();
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _showEditLimitDialog(double currentLimit) {
    _limitController.text = currentLimit.toInt().toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Auto-Pay Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transactions above this limit will require explicit two-step confirmation before charges are placed.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Auto-Pay Cap (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
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
            onPressed: () async {
              final newLimit = double.tryParse(_limitController.text);
              if (newLimit != null && newLimit > 0) {
                Navigator.of(ctx).pop();
                setState(() => _isUpdating = true);
                try {
                  await _apiService.updatePaymentLimit(newLimit: newLimit);
                  if (!mounted) return;
                  Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment limit updated to ₹${newLimit.toStringAsFixed(0)}'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update limit: $e'), backgroundColor: AppTheme.emergency),
                  );
                } finally {
                  if (mounted) setState(() => _isUpdating = false);
                }
              }
            },
            child: const Text('Save Limit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProv = Provider.of<ProfileProvider>(context);
    final profile = profileProv.profile;
    final currentLimit = profile?.paymentLimit ?? 1500.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Security & Limits'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Auto-Pay Safety Guard Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Server-Side Auto-Pay Cap',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('ACTIVE GUARD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '₹${currentLimit.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Any order above this amount will halt auto-debit and require explicit biometric or OTP confirmation.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isUpdating
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.edit, size: 14),
                    label: const Text('Change Limit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _isUpdating ? null : () => _showEditLimitDialog(currentLimit),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Business Guardrail Transparency Card
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
                    Icon(Icons.verified_outlined, color: AppTheme.success, size: 20),
                    SizedBox(width: 8),
                    Text('Fair Local Commerce Guarantee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildGuaranteeTile(
                  Icons.percent,
                  '6.5% Capped Commission',
                  'Aggregators charge 20–30% to local pharmacies. MediConnect enforces a hard 5–10% cap at the server level (set to 6.5%), protecting neighborhood chemists.',
                ),
                const Divider(height: 20),
                _buildGuaranteeTile(
                  Icons.chat_bubble_outline,
                  'Direct Chemist Relationships',
                  'You can live-chat directly with your local pharmacist, preserving neighborhood trust and personalized care.',
                ),
                const Divider(height: 20),
                _buildGuaranteeTile(
                  Icons.savings_outlined,
                  'Generic Price Transparency',
                  'Every search reveals generic alternatives side-by-side with branded drugs, saving patients up to 70% on standard formulations.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Methods Card
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
                const Text('Configured Payment Modes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _buildPaymentMethodTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'UPI AutoPay',
                  subtitle: 'Primary method (Verified)',
                  isDefault: true,
                ),
                const Divider(height: 16),
                _buildPaymentMethodTile(
                  icon: Icons.credit_card,
                  title: 'Cards & Net Banking',
                  subtitle: 'RuPay, Visa, Mastercard, NetBanking',
                  isDefault: false,
                ),
                const Divider(height: 16),
                _buildPaymentMethodTile(
                  icon: Icons.payments_outlined,
                  title: 'Cash On Delivery',
                  subtitle: 'Direct settlement with local chemist runner',
                  isDefault: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeTile(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryLight,
          child: Icon(icon, size: 16, color: AppTheme.primaryDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDefault,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        if (isDefault)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('DEFAULT', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
