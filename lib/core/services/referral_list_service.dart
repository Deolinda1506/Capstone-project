import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A referral entry: hospital + when referred
class ReferralEntry {
  const ReferralEntry({
    required this.hospitalName,
    required this.district,
    required this.referredAt,
  });

  final String hospitalName;
  final String district;
  final DateTime referredAt;

  Map<String, dynamic> toJson() => {
        'hospitalName': hospitalName,
        'district': district,
        'referredAt': referredAt.toIso8601String(),
      };

  factory ReferralEntry.fromJson(Map<String, dynamic> json) => ReferralEntry(
        hospitalName: json['hospitalName'] as String,
        district: json['district'] as String,
        referredAt: DateTime.parse(json['referredAt'] as String),
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
