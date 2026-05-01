class AccountModel {
  final int? id;
  final String uuid;
  final String name;
  final String? accountType;
  final String currency;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  AccountModel({
    this.id,
    required this.uuid,
    required this.name,
    this.accountType,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      accountType: map['account_type'] as String?,
      currency: map['currency'] as String? ?? 'PHP',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'local',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'account_type': accountType,
      'currency': currency,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }
}