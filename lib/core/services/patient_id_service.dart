import 'package:shared_preferences/shared_preferences.dart';

const String _keyPatientCounter = 'patient_id_counter';

/// Generates unique patient IDs (CC-0001, CC-0002, ...)
class PatientIdService {
  static Future<String> generateId() async {
    final prefs = await SharedPreferences.getInstance();
    final counter = prefs.getInt(_keyPatientCounter) ?? 0;
    final next = counter + 1;
    await prefs.setInt(_keyPatientCounter, next);
    return 'CC-${next.toString().padLeft(4, '0')}';
  }
}
