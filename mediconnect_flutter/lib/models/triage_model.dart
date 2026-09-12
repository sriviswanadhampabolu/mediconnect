class MedicineRecommendation {
  final String genericName;
  final String brandedName;
  final String dosageAndUsage;
  final String rationale;
  final bool requiresPrescription;
  final double averageGenericPrice;
  final double averageBrandedPrice;
  final double savingsAmount;

  MedicineRecommendation({
    required this.genericName,
    required this.brandedName,
    required this.dosageAndUsage,
    required this.rationale,
    required this.requiresPrescription,
    required this.averageGenericPrice,
    required this.averageBrandedPrice,
    required this.savingsAmount,
  });

  factory MedicineRecommendation.fromJson(Map<String, dynamic> json) {
    return MedicineRecommendation(
      genericName: json['generic_name'] ?? '',
      brandedName: json['branded_name'] ?? '',
      dosageAndUsage: json['dosage_and_usage'] ?? '',
      rationale: json['rationale'] ?? '',
      requiresPrescription: json['requires_prescription'] ?? false,
      averageGenericPrice: (json['average_generic_price'] ?? 0.0).toDouble(),
      averageBrandedPrice: (json['average_branded_price'] ?? 0.0).toDouble(),
      savingsAmount: (json['savings_amount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'generic_name': genericName,
    'branded_name': brandedName,
    'dosage_and_usage': dosageAndUsage,
    'rationale': rationale,
    'requires_prescription': requiresPrescription,
    'average_generic_price': averageGenericPrice,
    'average_branded_price': averageBrandedPrice,
    'savings_amount': savingsAmount,
  };
}

class AgentStepBreadcrumb {
  final String agentName;
  final String status;
  final String details;

  AgentStepBreadcrumb({
    required this.agentName,
    required this.status,
    required this.details,
  });

  factory AgentStepBreadcrumb.fromJson(Map<String, dynamic> json) {
    return AgentStepBreadcrumb(
      agentName: json['agent_name'] ?? '',
      status: json['status'] ?? '',
      details: json['details'] ?? '',
    );
  }
}

class TriageResponse {
  final String sessionId;
  final String userId;
  final String severity;
  final bool emergencyDetected;
  final String summary;
  final String candidateCondition;
  final List<String> homeRemedies;
  final List<MedicineRecommendation> medicines;
  final List<String> contraindicationWarnings;
  final bool doctorReferralNeeded;
  final List<AgentStepBreadcrumb> routingPath;
  final double genericSavingsTotal;
  final bool hospitalAppointmentSuggested;
  final Map<String, dynamic>? hospitalAppointmentDetails;

  TriageResponse({
    required this.sessionId,
    required this.userId,
    required this.severity,
    required this.emergencyDetected,
    required this.summary,
    required this.candidateCondition,
    required this.homeRemedies,
    required this.medicines,
    required this.contraindicationWarnings,
    required this.doctorReferralNeeded,
    required this.routingPath,
    required this.genericSavingsTotal,
    this.hospitalAppointmentSuggested = false,
    this.hospitalAppointmentDetails,
  });

  factory TriageResponse.fromJson(Map<String, dynamic> json) {
    var rawMeds = json['medicines'] as List? ?? [];
    List<MedicineRecommendation> medsList =
        rawMeds.map((m) => MedicineRecommendation.fromJson(m)).toList();

    var rawPath = json['routing_path'] as List? ?? [];
    List<AgentStepBreadcrumb> pathList =
        rawPath.map((p) => AgentStepBreadcrumb.fromJson(p)).toList();

    var rawRemedies = json['home_remedies'] as List? ?? [];
    List<String> remediesList = rawRemedies.map((r) => r.toString()).toList();

    var rawWarnings = json['contraindication_warnings'] as List? ?? [];
    List<String> warningsList = rawWarnings.map((w) => w.toString()).toList();

    return TriageResponse(
      sessionId: json['session_id'] ?? '',
      userId: json['user_id'] ?? '',
      severity: json['severity'] ?? 'routine',
      emergencyDetected: json['emergency_detected'] ?? false,
      summary: json['summary'] ?? '',
      candidateCondition: json['candidate_condition'] ?? '',
      homeRemedies: remediesList,
      medicines: medsList,
      contraindicationWarnings: warningsList,
      doctorReferralNeeded: json['doctor_referral_needed'] ?? false,
      routingPath: pathList,
      genericSavingsTotal: (json['generic_savings_total'] ?? 0.0).toDouble(),
      hospitalAppointmentSuggested: json['hospital_appointment_suggested'] ?? false,
      hospitalAppointmentDetails: json['hospital_appointment_details'],
    );
  }
}
