import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A referral entry: hospital + when referred, optionally tied to a scan analysis.
class ReferralEntry {
  const ReferralEntry({
    required this.hospitalName,
    required this.district,
    required this.referredAt,
    this.scanId,
  });

  final String hospitalName;
  final String district;
  final DateTime referredAt;
  /// When set, this analysis was already referred (hide repeat referral CTA on result).
  final String? scanId;

  Map<String, dynamic> toJson() => {
        'hospitalName': hospitalName,
        'district': district,
        'referredAt': referredAt.toIso8601String(),
        if (scanId != null && scanId!.isNotEmpty) 'scanId': scanId,
      };

  factory ReferralEntry.fromJson(Map<String, dynamic> json) => ReferralEntry(
        hospitalName: json['hospitalName'] as String,
        district: json['district'] as String,
        referredAt: DateTime.parse(json['referredAt'] as String),
        scanId: json['scanId'] as String?,
      );
}

/// Persists referral list locally
class ReferralListService {
  static const String _key = 'referral_list';

  Future<List<ReferralEntry>> getReferrals() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => ReferralEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// True if any saved referral is linked to this scan (same analysis).
  Future<bool> isScanReferred(String scanId) async {
    final id = scanId.trim();
    if (id.isEmpty) return false;
    final list = await getReferrals();
    return list.any((e) {
      final s = e.scanId?.trim();
      return s != null && s.isNotEmpty && s == id;
    });
  }

  Future<void> addReferral(ReferralEntry entry) async {
    final list = await getReferrals();
    list.insert(0, entry);
    await _save(list);
  }

  Future<void> removeReferral(int index) async {
    final list = await getReferrals();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await _save(list);
    }
  }

  Future<void> clear() async {
    await _save([]);
  }

  Future<void> _save(List<ReferralEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
