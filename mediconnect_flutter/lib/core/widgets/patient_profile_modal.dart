import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PatientProfileModal extends StatefulWidget {
  const PatientProfileModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PatientProfileModal(),
    );
  }

  @override
  State<PatientProfileModal> createState() => _PatientProfileModalState();
}

class _PatientProfileModalState extends State<PatientProfileModal> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    _nameController = TextEditingController(text: user?.name ?? 'Rahul Sharma');
    _phoneController = TextEditingController(text: user?.contact ?? '+91 98765 43210');
    _emailController = TextEditingController(text: user?.email ?? 'rahul@health.in');
    _addressController = TextEditingController(text: user?.address ?? 'Sector 15, Gurgaon');
    _limitController = TextEditingController(text: (user?.paymentLimit ?? 1500).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _limitController.dispose();
    _newAllergyController.dispose();
    super.dispose();
  }

  final TextEditingController _newAllergyController = TextEditingController();
  List<String> _editableAllergies = [];

  Future<void> _handleSave() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final newLimit = double.tryParse(_limitController.text) ?? 1500.0;
    final name = _nameController.text.trim();
    final contact = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();

    try {
      auth.updateUserProfile(
        name: name,
        contact: contact,
        email: email,
        address: address,
        paymentLimit: newLimit,
        allergies: _editableAllergies,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Health Card updated for $name! Auto-Pay Cap set to ₹${newLimit.toStringAsFixed(0)}'),
          backgroundColor: AppTheme.success,
        ),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: AppTheme.emergency),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final allergies = user?.allergies ?? ['Aspirin (Strict Block)', 'Penicillin'];
    if (_editableAllergies.isEmpty) {
      _editableAllergies = List<String>.from(allergies);
    }

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
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: AppTheme.neuSquircle(radius: 14),
                    child: const Center(
                      child: Text('👤', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Details entered upon account registration',
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
              const SizedBox(height: 18),

              if (!_isEditing) ...[
                // READONLY VIEW MODE
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.neuRaised(radius: 20),
                  child: Column(
                    children: [
                      _buildProfileRow('Full Name', _nameController.text, Icons.person_outline),
                      const Divider(height: 16),
                      _buildProfileRow('Mobile Number', _phoneController.text, Icons.phone_android_outlined),
                      const Divider(height: 16),
                      _buildProfileRow('Email Address', _emailController.text, Icons.mail_outline),
                      const Divider(height: 16),
                      _buildProfileRow('Delivery Address', _addressController.text, Icons.location_on_outlined),
                      const Divider(height: 16),
                      _buildProfileRow(
                        'GPS Coordinates',
                        '${user?.latitude ?? 28.4680}° N, ${user?.longitude ?? 77.0420}° E',
                        Icons.gps_fixed,
                      ),
                      const Divider(height: 16),
                      _buildProfileRow(
                        'Auto-Pay Spending Cap',
                        '₹${_limitController.text} per order',
                        Icons.lock_clock_outlined,
                        valueColor: AppTheme.success,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Encrypted Allergies Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield, color: AppTheme.secondary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Encrypted Allergies (At Rest)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: allergies
                            .map(
                              (a) => Chip(
                                backgroundColor: Colors.white,
                                side: BorderSide(color: AppTheme.secondary.withOpacity(0.3)),
                                label: Text(
                                  '🛡️ $a',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action button: Edit Profile
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      '✏️ Edit Profile Details & Cap',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                ),
              ] else ...[
                // EDIT MODE
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.neuRaised(radius: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditField('Full Name', _nameController, Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildEditField('Mobile Number', _phoneController, Icons.phone_android_outlined),
                      const SizedBox(height: 12),
                      _buildEditField('Email Address', _emailController, Icons.mail_outline),
                      const SizedBox(height: 12),
                      _buildEditField('Delivery Address', _addressController, Icons.location_on_outlined),
                      const SizedBox(height: 12),
                      _buildEditField(
                        'Auto-Pay Spending Cap (₹)',
                        _limitController,
                        Icons.lock_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Medicine Allergies (AI Safety Guard)',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _editableAllergies
                            .map(
                              (a) => Chip(
                                backgroundColor: AppTheme.secondaryLight,
                                label: Text('🛡️ $a', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                                deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.emergency),
                                onDeleted: () => setState(() => _editableAllergies.remove(a)),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: AppTheme.neuSunken(radius: 12),
                              child: TextField(
                                controller: _newAllergyController,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  hintText: 'Add allergy (e.g. Sulfa, Peanuts)...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final text = _newAllergyController.text.trim();
                              if (text.isNotEmpty && !_editableAllergies.contains(text)) {
                                setState(() {
                                  _editableAllergies.add(text);
                                  _newAllergyController.clear();
                                });
                              }
                            },
                            child: const Text('+ Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => setState(() => _isEditing = false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text(
                          '✓ Save Changes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: _handleSave,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon, {
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
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
