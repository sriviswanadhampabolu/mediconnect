import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProv = Provider.of<ProfileProvider>(context);
    final profile = profileProv.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records & Vault'),
      ),
      body: profileProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_person_outlined, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text('Failed to load encrypted profile.', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => profileProv.fetchProfile(),
                        child: const Text('Retry Decryption'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Encryption Security Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.enhanced_encryption_outlined, color: AppTheme.secondary, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AES-256 Encrypted Vault',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 14),
                                ),
                                Text(
                                  'All records are encrypted at rest with strict immutable audit logging.',
                                  style: TextStyle(fontSize: 12, color: AppTheme.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Info Card
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
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryLight,
                                child: Text(
                                  profile.name.isNotEmpty ? profile.name[0] : 'U',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                    ),
                                    Text(
                                      '${profile.email} • ${profile.phone}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: AppTheme.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Auto-Pay Safety Cap:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              Text(
                                '₹${profile.maxAutoPayLimit.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Allergies Shield Card
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
                              Icon(Icons.shield, color: AppTheme.emergency, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Documented Allergies & Drug Blocks',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (profile.allergies.isEmpty)
                            const Text('No documented drug allergies.', style: TextStyle(color: AppTheme.textSecondary))
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.allergies.map((allergy) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emergencyLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.emergency.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.block, size: 14, color: AppTheme.emergency),
                                      const SizedBox(width: 6),
                                      Text(
                                        allergy,
                                        style: const TextStyle(color: AppTheme.emergency, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active Medications
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
                              Icon(Icons.medication_outlined, color: AppTheme.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Active Medication History',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (profile.medications.isEmpty)
                            const Text('No active medications recorded.', style: TextStyle(color: AppTheme.textSecondary))
                          else
                            ...profile.medications.map((med) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(med.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('Generic: ${med.genericName} • Dosage: ${med.dosage}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Active', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
