/// Hospitals near the app's supported districts (Rwanda)
class HospitalInfo {
  const HospitalInfo({
    required this.name,
    required this.district,
    required this.address,
    required this.lat,
    required this.lng,
    this.phone,
  });

  final String name;
  final String district;
  final String address;
  final double lat;
  final double lng;
  final String? phone;
}

/// District hospitals for Nyarugenge, Gasabo, Musanze, Huye, Rwamagana
const List<HospitalInfo> districtHospitals = [
  HospitalInfo(
    name: 'Nyarugenge District Hospital',
    district: 'Nyarugenge',
    address: 'Nyarugenge, Kigali City',
    lat: -1.9536,
    lng: 30.0606,
    phone: '+250 788 123 400',
  ),
  HospitalInfo(
    name: 'Gasabo District Hospital',
    district: 'Gasabo',
    address: 'Kimironko, Gasabo, Kigali',
    lat: -1.9540,
    lng: 30.1120,
    phone: '+250 788 123 456',
  ),
  HospitalInfo(
    name: 'Ruhengeri Level Two Teaching Hospital',
    district: 'Musanze',
    address: 'Muhoza, Musanze, Northern Province',
    lat: -1.5014,
    lng: 29.6344,
    phone: '+250 788 123 500',
  ),
  HospitalInfo(
    name: 'CHUB (University Teaching Hospital of Butare)',
    district: 'Huye',
    address: 'Huye, Southern Province',
    lat: -2.6014,
    lng: 29.7447,
    phone: '+250 788 123 600',
  ),
  HospitalInfo(
    name: 'Rwamagana Level Two Teaching Hospital',
    district: 'Rwamagana',
    address: 'Rwamagana, Eastern Province',
    lat: -1.9486,
    lng: 30.4347,
    phone: '+250 788 123 700',
  ),
];
