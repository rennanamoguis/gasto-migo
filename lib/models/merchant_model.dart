class MerchantModel {
  final int? id;
  final String uuid;
  final String name;
  final String? normalizedName;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  MerchantModel({
    this.id,
    required this.uuid,
    required this.name,
    this.normalizedName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });

  factory MerchantModel.fromMap(Map<String, dynamic> map) {
    return MerchantModel(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      normalizedName: map['normalized_name'] as String?,
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
      'normalized_name': normalizedName,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }
}
