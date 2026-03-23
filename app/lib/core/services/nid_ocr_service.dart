import 'dart:io';
import '../models/patient_model.dart';

/// Simulator-safe ID parser used across platforms.
/// Parses name, age, gender, and ID from file name patterns.
class NidOcrService {
  Future<void> dispose() async {}

  /// Process image and extract patient data from Rwandan NID
  /// Format varies; heuristic extraction from the file name.
  Future<PatientModel?> extractFromImage(File imageFile) async {
    try {
      final filename = imageFile.uri.pathSegments.isNotEmpty
          ? imageFile.uri.pathSegments.last
          : imageFile.path;
      return _parseRwandaNidFromFilename(filename);
    } catch (_) {
      return null;
    }
  }

  PatientModel? _parseRwandaNidFromFilename(String rawFilename) {
    final filename = rawFilename.trim();
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
}
