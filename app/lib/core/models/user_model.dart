import 'user_role.dart';
import 'location_model.dart';

/// User model with RBC-compliant fields
class UserModel {
  final String id;
  final String? phoneNumber;
  final String? mohStaffId;
  final UserRole role;
  final String? fullName;
  final LocationModel? healthCenter;
  final AccountStatus status;
  final String? villageId; // CHW only: restricts patient visibility

  const UserModel({
    required this.id,
    this.phoneNumber,
    this.mohStaffId,
    required this.role,
    this.fullName,
    this.healthCenter,
    this.status = AccountStatus.pending,
    this.villageId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String?,
      mohStaffId: json['moh_staff_id'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'chw'),
      fullName: json['full_name'] as String?,
      healthCenter: json['health_center'] != null
          ? LocationModel.fromJson(json['health_center'] as Map<String, dynamic>)
          : null,
      status: AccountStatus.fromString(json['status'] as String? ?? 'pending'),
      villageId: json['village_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'moh_staff_id': mohStaffId,
        'role': role.name,
        'full_name': fullName,
        'health_center': healthCenter?.toJson(),
        'status': status.name,
        'village_id': villageId,
      };

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? mohStaffId,
    UserRole? role,
    String? fullName,
    LocationModel? healthCenter,
    AccountStatus? status,
    String? villageId,
  }) =>
      UserModel(
        id: id ?? this.id,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        mohStaffId: mohStaffId ?? this.mohStaffId,
        role: role ?? this.role,
        fullName: fullName ?? this.fullName,
        healthCenter: healthCenter ?? this.healthCenter,
        status: status ?? this.status,
        villageId: villageId ?? this.villageId,
      );
}

enum AccountStatus {
  pending,
  approved,
  rejected;

  static AccountStatus fromString(String value) {
    return AccountStatus.values.firstWhere(
      (s) => s.name == value.toLowerCase(),
      orElse: () => AccountStatus.pending,
    );
  }

  String get displayLabel {
    switch (this) {
      case AccountStatus.pending:
        return 'Pending Approval';
      case AccountStatus.approved:
        return 'Approved';
      case AccountStatus.rejected:
        return 'Rejected';
    }
  }
}
