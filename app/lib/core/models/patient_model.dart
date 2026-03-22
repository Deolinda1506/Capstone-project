class PatientModel {
  final String? id;
  final String? name;
  final int? age;
  final String? gender;
  final String? email;
  final String? nationalId;
  final String? villageId;
  final bool consentGiven;
  final DateTime? consentTimestamp;

  const PatientModel({
    this.id,
    this.name,
    this.age,
    this.gender,
    this.email,
    this.nationalId,
    this.villageId,
    this.consentGiven = false,
    this.consentTimestamp,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      email: json['email'] as String?,
      nationalId: json['national_id'] as String?,
      villageId: json['village_id'] as String?,
      consentGiven: json['consent_given'] as bool? ?? false,
      consentTimestamp: json['consent_timestamp'] != null
          ? DateTime.tryParse(json['consent_timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'email': email,
        'national_id': nationalId,
        'village_id': villageId,
        'consent_given': consentGiven,
        'consent_timestamp': consentTimestamp?.toIso8601String(),
      };

  PatientModel copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? email,
    String? nationalId,
    String? villageId,
    bool? consentGiven,
    DateTime? consentTimestamp,
  }) =>
      PatientModel(
        id: id ?? this.id,
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        email: email ?? this.email,
        nationalId: nationalId ?? this.nationalId,
        villageId: villageId ?? this.villageId,
        consentGiven: consentGiven ?? this.consentGiven,
        consentTimestamp: consentTimestamp ?? this.consentTimestamp,
      );
}
