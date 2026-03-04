/// Rwanda administrative hierarchy for hospital linkage
/// Province → District → Sector → Health Center/Hospital

class LocationModel {
  final String province;
  final String district;
  final String sector;
  final String? healthCenter;
  final String? village; // CHW's assigned village

  const LocationModel({
    required this.province,
    required this.district,
    required this.sector,
    this.healthCenter,
    this.village,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      province: json['province'] as String? ?? '',
      district: json['district'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      healthCenter: json['health_center'] as String?,
      village: json['village'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'province': province,
        'district': district,
        'sector': sector,
        'health_center': healthCenter,
        'village': village,
      };

  String get displayAddress {
    final parts = [province, district, sector];
    if (healthCenter != null) parts.add(healthCenter!);
    if (village != null) parts.add(village!);
    return parts.join(' • ');
  }
}

/// Rwanda provinces (Kigali City + 4 provinces)
const List<String> rwandaProvinces = [
  'Kigali City',
  'Eastern Province',
  'Southern Province',
  'Western Province',
  'Northern Province',
];

/// Sample districts by province (simplified; full data would come from API/JSON)
Map<String, List<String>> rwandaDistricts = {
  'Kigali City': ['Gasabo', 'Kicukiro', 'Nyarugenge'],
  'Eastern Province': ['Bugesera', 'Gatsibo', 'Kayonza', 'Kirehe', 'Ngoma', 'Nyagatare', 'Rwamagana'],
  'Southern Province': ['Gisagara', 'Huye', 'Kamonyi', 'Muhanga', 'Nyamagabe', 'Nyanza', 'Nyaruguru', 'Ruhango'],
  'Western Province': ['Karongi', 'Ngororero', 'Nyabihu', 'Nyamasheke', 'Rubavu', 'Rusizi', 'Rutsiro'],
  'Northern Province': ['Burera', 'Gakenke', 'Gicumbi', 'Musanze', 'Rulindo'],
};
