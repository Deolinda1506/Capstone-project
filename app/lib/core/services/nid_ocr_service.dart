import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/patient_model.dart';

/// OCR service for Rwandan National ID using Google ML Kit
/// Parses name, age, gender from ID card image
class NidOcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<void> dispose() => _recognizer.close();

  /// Process image and extract patient data from Rwandan NID
  /// Format varies; heuristic extraction for common patterns
  Future<PatientModel?> extractFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _recognizer.processImage(inputImage);
      final text = recognizedText.text;
      if (text.isEmpty) return null;
      return _parseRwandaNid(text);
    } catch (_) {
      return null;
    }
  }

  PatientModel? _parseRwandaNid(String rawText) {
    final lines = rawText
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    String? name;
    int? age;
    String? gender;
    String? nationalId;

    const ignoredNameTokens = <String>{
      'republic of rwanda',
      'national id',
      'identity card',
      'id card',
      'card',
      'sex',
      'gender',
      'date of birth',
      'dob',
      'issued',
      'expires',
    };

    // Rwanda NID format varies by issue version and OCR quality.
    // Heuristics below intentionally tolerate noisy punctuation and spacing.
    for (final line in lines) {
      final cleaned = line.replaceAll(RegExp(r'[^A-Za-z0-9\s\-]'), '').trim();
      final lowerCleaned = cleaned.toLowerCase();
      if (cleaned.length > 10 &&
          RegExp(r'^[A-Za-z\s\-]+$').hasMatch(cleaned) &&
          !RegExp(r'^\d+$').hasMatch(cleaned) &&
          !ignoredNameTokens.any(lowerCleaned.contains)) {
        if (name == null || cleaned.length > name.length) {
          name = cleaned.replaceAll(RegExp(r'\s+'), ' ');
        }
      }
      // ID number: commonly 16 digits (accept a broader range for OCR noise).
      final idMatch = RegExp(r'\b\d{12,20}\b').firstMatch(cleaned);
      if (idMatch != null && nationalId == null) {
        nationalId = idMatch.group(0);
      }
      // DOB: DD/MM/YYYY or similar.
      final dobMatch = RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})').firstMatch(cleaned);
      if (dobMatch != null && age == null) {
        final yearVal = dobMatch.group(3);
        final year = yearVal != null ? int.tryParse(yearVal) : null;
        if (year != null) {
          final y = yearVal!.length == 2
              ? (year >= 50 ? 1900 + year : 2000 + year)
              : year;
          age = DateTime.now().year - y;
          if (age < 0 || age > 120) age = null;
        }
      }
      // Gender: M/F or Male/Female
      final lower = lowerCleaned;
      if (gender == null) {
        if (lower.contains('male') && !lower.contains('female')) gender = 'Male';
        if (lower.contains('female')) gender = 'Female';
        if (lower == 'm' || lower.startsWith('m ')) gender = 'Male';
        if (lower == 'f' || lower.startsWith('f ')) gender = 'Female';
      }
    }

    if (name == null && age == null && gender == null) return null;

    return PatientModel(
      name: name,
      age: age,
      gender: gender,
      nationalId: nationalId,
    );
  }
}
