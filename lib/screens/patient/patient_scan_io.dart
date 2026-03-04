import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/models/patient_model.dart';
import '../../core/services/nid_ocr_service.dart';

/// Mobile/desktop implementation - uses File and ML Kit OCR
Future<PatientModel?> scanId(XFile xfile) async {
  final ocrService = NidOcrService();
  try {
    final file = File(xfile.path);
    return await ocrService.extractFromImage(file);
  } finally {
    ocrService.dispose();
  }
}
