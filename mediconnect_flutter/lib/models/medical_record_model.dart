class MedicationHistoryItem {
  final String id;
  final String medicineName;
  final String genericName;
  final String dosage;
  final String prescribedBy;
  final bool active;

  MedicationHistoryItem({
    required this.id,
    required this.medicineName,
    required this.genericName,
    required this.dosage,
    required this.prescribedBy,
    required this.active,
  });

  factory MedicationHistoryItem.fromJson(Map<String, dynamic> json) {
    return MedicationHistoryItem(
      id: json['id'] ?? '',
      medicineName: json['medicine_name'] ?? '',
      genericName: json['generic_name'] ?? '',
      dosage: json['dosage'] ?? '',
      prescribedBy: json['prescribed_by'] ?? '',
      active: json['active'] ?? true,
    );
  }
}

class ClinicalNote {
  final String date;
  final String condition;
  final String prescribingSource;
  final String notes;

  ClinicalNote({
    required this.date,
    required this.condition,
    required this.prescribingSource,
    required this.notes,
  });

  factory ClinicalNote.fromJson(Map<String, dynamic> json) {
    return ClinicalNote(
      date: json['date'] ?? '',
      condition: json['condition'] ?? '',
      prescribingSource: json['prescribing_source'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

class UserMedicalProfile {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final double maxAutoPayLimit;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<MedicationHistoryItem> medications;
  final List<ClinicalNote> clinicalNotes;

  UserMedicalProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.maxAutoPayLimit,
    required this.allergies,
    required this.chronicConditions,
    required this.medications,
    required this.clinicalNotes,
  });

  factory UserMedicalProfile.fromJson(Map<String, dynamic> json) {
    var rawAllergies = json['allergies'] as List? ?? [];
    List<String> allergiesList = rawAllergies.map((a) => a.toString()).toList();

    var rawConditions = json['chronic_conditions'] as List? ?? [];
    List<String> conditionsList = rawConditions.map((c) => c.toString()).toList();

    var rawMeds = json['medications'] as List? ?? [];
    List<MedicationHistoryItem> medsList =
        rawMeds.map((m) => MedicationHistoryItem.fromJson(m)).toList();

    var rawNotes = json['clinical_notes'] as List? ?? [];
    List<ClinicalNote> notesList =
        rawNotes.map((n) => ClinicalNote.fromJson(n)).toList();

    return UserMedicalProfile(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      maxAutoPayLimit: (json['payment_limit'] ?? json['max_auto_pay_limit'] ?? 1500.0).toDouble(),
      allergies: allergiesList,
      chronicConditions: conditionsList,
      medications: medsList,
      clinicalNotes: notesList,
    );
  }

  double get paymentLimit => maxAutoPayLimit;
}
