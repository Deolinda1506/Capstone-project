class AnalysisModel {
  final String id;
  final String? patientId;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final DateTime analyzedAt;
  final String risk; // low, moderate, high, unknown
  final double? imt; // intima-media thickness (mm), null when not measurable
  final double? stenosisPct; // NASCET %
  final String? stenosisSource; // "nascet" when stenosis from lumen mask
  final bool? plaqueDetected;
  final String? notes;
  final String? imagePath; // local path or URL for thumbnail
  final bool hasImage; // true when scan image is stored for doctor view
  final bool hasAiOverlay; // true when stored image is green AI segmentation overlay

  const AnalysisModel({
    required this.id,
    this.patientId,
    this.patientName,
    this.patientAge,
    this.patientGender,
    required this.analyzedAt,
    required this.risk,
    this.imt,
    this.stenosisPct,
    this.stenosisSource,
    this.plaqueDetected,
    this.notes,
    this.imagePath,
    this.hasImage = false,
    this.hasAiOverlay = false,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String?,
      patientName: json['patient_name'] as String?,
      patientAge: json['patient_age'] as int?,
      patientGender: json['patient_gender'] as String?,
      analyzedAt: DateTime.parse(json['analyzed_at'] as String),
      risk: json['risk'] as String? ?? 'low',
      imt: (json['imt'] as num?)?.toDouble(),
      plaqueDetected: json['plaque_detected'] as bool?,
      notes: json['notes'] as String?,
      imagePath: json['image_path'] as String?,
      hasImage: json['has_image'] as bool? ?? false,
      hasAiOverlay: json['has_ai_overlay'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'patient_name': patientName,
        'patient_age': patientAge,
        'patient_gender': patientGender,
        'analyzed_at': analyzedAt.toIso8601String(),
        'risk': risk,
        'imt': imt,
        'plaque_detected': plaqueDetected,
        'notes': notes,
        'image_path': imagePath,
        'has_image': hasImage,
        'has_ai_overlay': hasAiOverlay,
      };
}
