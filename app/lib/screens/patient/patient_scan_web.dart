import 'package:image_picker/image_picker.dart';
import '../../core/models/patient_model.dart';

/// Web fallback implementation.
///
/// Browser OCR is not wired here yet, so we do a best-effort parse from the
/// file name (commonly used during demos/tests), e.g.:
/// - "MUKAMANA_34_F_1199....jpg"
/// - "john-doe-male-28.png"
Future<PatientModel?> scanId(XFile xfile) async {
  final filename = xfile.name.trim();
  if (filename.isEmpty) return null;

  final base = filename.replaceFirst(RegExp(r'\.[A-Za-z0-9]+$'), '');
  final normalized = base
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final lower = normalized.toLowerCase();

  String? gender;
  if (RegExp(r'\b(female|f)\b').hasMatch(lower)) {
    gender = 'Female';
  } else if (RegExp(r'\b(male|m)\b').hasMatch(lower)) {
    gender = 'Male';
  }

  int? age;
  final ageMatch = RegExp(r'\b(1[01]\d|120|[1-9]?\d)\b').allMatches(lower);
  for (final m in ageMatch) {
    final v = int.tryParse(m.group(0)!);
    if (v != null && v >= 1 && v <= 120) {
      age = v;
      break;
    }
  }

  String? nationalId;
  final idMatch = RegExp(r'\b\d{12,20}\b').firstMatch(lower);
  if (idMatch != null) nationalId = idMatch.group(0);

  // Remove obvious metadata tokens to infer a name.
  var nameCandidate = normalized
      .replaceAll(RegExp(r'\b(19|20)\d{2}\b'), ' ')
      .replaceAll(RegExp(r'\b(1[01]\d|120|[1-9]?\d)\b'), ' ')
      .replaceAll(RegExp(r'\b(male|female|m|f|id|nid|rwanda)\b', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (nameCandidate.isEmpty) nameCandidate = 'Scanned Patient';

  return PatientModel(
    name: nameCandidate,
    age: age,
    gender: gender,
    nationalId: nationalId,
  );
}
