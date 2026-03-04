/// Rwanda district options for registration
class DistrictOption {
  const DistrictOption({
    required this.name,
    required this.idCode,
    required this.hasc,
    required this.province,
  });

  final String name;
  final String idCode;
  final String hasc;
  final String province;

  String get displayLabel => '$name (ID: $idCode) - $province';
}

const List<DistrictOption> rwandaDistricts = [
  DistrictOption(
    name: 'Nyarugenge',
    idCode: '0101',
    hasc: 'RW.KV.NG',
    province: 'Kigali City',
  ),
  DistrictOption(
    name: 'Gasabo',
    idCode: '0102',
    hasc: 'RW.KV.GB',
    province: 'Kigali City',
  ),
  DistrictOption(
    name: 'Musanze',
    idCode: '0403',
    hasc: 'RW.NO.MS',
    province: 'Northern Province',
  ),
  DistrictOption(
    name: 'Huye',
    idCode: '0204',
    hasc: 'RW.SU.HU',
    province: 'Southern Province',
  ),
  DistrictOption(
    name: 'Rwamagana',
    idCode: '0501',
    hasc: 'RW.ES.RM',
    province: 'Eastern Province',
  ),
];
