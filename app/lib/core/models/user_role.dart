
enum UserRole {
  /// Level 1: Community Health Worker
  /// Simplified UI: Scan → Result (Color) → Refer
  /// Sees only patients in their village
  chw(level: 1, label: 'Community Health Worker'),

  /// Level 2: Hospital Clinician (Nurse/MD)
  /// Advanced UI: Review AI Segmentation → Clinical Validation → Treatment Plan
  clinician(level: 2, label: 'Hospital Clinician'),

  /// Level 3: Administrator/Researcher (ALU/RBC)
  /// Data UI: Anonymized stats → System Health → AI Accuracy Monitoring
  admin(level: 3, label: 'Administrator / Researcher');

  const UserRole({required this.level, required this.label});
  final int level;
  final String label;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value.toLowerCase(),
      orElse: () => UserRole.chw,
    );
  }

  bool get isChw => this == UserRole.chw;
  bool get isClinician => this == UserRole.clinician;
  bool get isAdmin => this == UserRole.admin;
}
