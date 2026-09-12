import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class HospitalBookingScreen extends StatelessWidget {
  final Map<String, dynamic> appointmentDetails;
  final bool isEmergency;

  const HospitalBookingScreen({
    super.key,
    required this.appointmentDetails,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    final hospitalName = appointmentDetails['hospital_name'] ?? 'Healthcare Facility';
    final address = appointmentDetails['address'] ?? 'Sector 15 Medical District';
    final phone = appointmentDetails['phone'] ?? '+91 98110 11222';
    final distanceKm = appointmentDetails['distance_km'] ?? 1.2;
    final slot = appointmentDetails['slot'] ?? 'Immediate Priority';
    final tokenId = appointmentDetails['token_id'] ?? 'ER-PASS';
    final erIncharge = appointmentDetails['er_incharge'] ?? 'Emergency Care Specialist';
    final icuStatus = appointmentDetails['icu_status'] ?? 'ICU beds on standby';
    final instructions = appointmentDetails['instructions'] ?? 'Please present this digital pass upon arrival.';
    final specialty = appointmentDetails['specialty'] ?? 'General Physician / Internal Medicine';

    final isEr = isEmergency || appointmentDetails['booking_type'] == 'EMERGENCY_PRIORITY_ADMISSION';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEr ? 'Emergency Admission Pass' : 'Clinic Appointment'),
        backgroundColor: isEr ? AppTheme.emergencyLight : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isEr ? AppTheme.emergency : AppTheme.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isEr ? AppTheme.emergency : AppTheme.primary).withOpacity(0.3),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEr ? Icons.local_hospital : Icons.calendar_month,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEr ? 'PRIORITY ER PASS' : 'CONFIRMED APPOINTMENT',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            hospitalName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEr ? 'TOKEN: $tokenId' : 'SLOT: $slot',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$distanceKm km away',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details Card
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
                const Text('Facility & Physician Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on_outlined, 'Address', address),
                const Divider(height: 20),
                _buildInfoRow(Icons.phone_outlined, 'Direct Contact', phone),
                const Divider(height: 20),
                if (isEr) ...[
                  _buildInfoRow(Icons.person_pin_outlined, 'Trauma In-Charge', erIncharge),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.bed_outlined, 'ICU Readiness', icuStatus),
                ] else ...[
                  _buildInfoRow(Icons.medical_services_outlined, 'Consultation Specialty', specialty),
                  const Divider(height: 20),
                  _buildInfoRow(Icons.access_time, 'Preferred Slot', slot),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Clinical Guidance Card
          Container(
            padding: const EdgeInsets.all(16),
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
                    Icon(Icons.info_outline, color: AppTheme.secondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Clinical Protocol Note',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  instructions,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call Facility'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dialing $phone...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEr ? AppTheme.emergency : AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Directions'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening live GPS directions to $hospitalName...')),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
