import 'package:carotid_check/core/models/analysis_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisModel', () {
    test('fromJson maps API fields and defaults', () {
      final m = AnalysisModel.fromJson({
        'id': 'scan-1',
        'analyzed_at': '2026-03-01T10:00:00.000Z',
        'risk': 'High',
        'imt': 1.15,
        'patient_id': 'p-1',
        'patient_name': 'Test Patient',
        'has_image': true,
      });

      expect(m.id, 'scan-1');
      expect(m.risk, 'High');
      expect(m.imt, 1.15);
      expect(m.patientId, 'p-1');
      expect(m.patientName, 'Test Patient');
      expect(m.hasImage, isTrue);
    });

    test('fromJson uses fallbacks for optional fields', () {
      final m = AnalysisModel.fromJson({
        'id': 'scan-2',
        'analyzed_at': '2026-03-01T10:00:00.000Z',
        'risk': 'low',
        'imt': 0.0,
      });

      expect(m.risk, 'low');
      expect(m.imt, 0.0);
      expect(m.patientId, isNull);
      expect(m.hasImage, isFalse);
    });

    test('toJson includes core keys', () {
      final analyzed = DateTime.utc(2026, 3, 1);
      final m = AnalysisModel(
        id: 'a1',
        analyzedAt: analyzed,
        risk: 'Moderate',
        imt: 0.95,
        patientId: 'pid',
      );
      final json = m.toJson();
      expect(json['id'], 'a1');
      expect(json['risk'], 'Moderate');
      expect(json['imt'], 0.95);
      expect(json['patient_id'], 'pid');
      expect(json['analyzed_at'], analyzed.toIso8601String());
    });
  });
}
