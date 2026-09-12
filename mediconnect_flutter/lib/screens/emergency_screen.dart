import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class EmergencyScreen extends StatelessWidget {
  final String emergencyReason;

  const EmergencyScreen({
    super.key,
    this.emergencyReason = 'Life-Threatening Emergency Veto Triggered',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF881337), // Deep emergency crimson
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'EMERGENCY SOS OVERRIDE',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Flashing Emergency Beacon
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.emergency,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emergency.withOpacity(0.6),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.emergency, color: Colors.white, size: 52),
              ),
            ),
            const SizedBox(height: 24),

            const Center(
              child: Text(
                '108 Ambulance Dispatched',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                emergencyReason,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Live Dispatch Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.emergencyLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car, color: AppTheme.emergency),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paramedic Unit #DL-04-EM-991',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Text(
                            'Advanced Cardiac Life Support (ACLS)',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.emergencyLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ETA: 6 Mins',
                          style: TextStyle(color: AppTheme.emergency, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppTheme.border),
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: AppTheme.emergency),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Live GPS broadcast sent: Lat 28.6139, Lng 77.2090',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.local_hospital_outlined, size: 18, color: AppTheme.secondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reserved: AIIMS Trauma ER Bay #4',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.mark_email_read_outlined, size: 18, color: AppTheme.success),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Emergency Contacts Alerted via SMS & GPS link',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.emergency,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.phone_in_talk, color: AppTheme.emergency, size: 22),
              label: const Text(
                'Direct Call 108 Emergency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling 108 Emergency Control Room...')),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dismiss SOS Override'),
            ),
          ],
        ),
      ),
    );
  }
}
