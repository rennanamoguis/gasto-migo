class PaymentMethodModel {
  final int? id;
  final String uuid;
  final String name;
  final String? icon;
  final int sortOrder;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  PaymentMethodModel({
    this.id,
    required this.uuid,
    required this.name,
    this.icon,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
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
      'icon': icon,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }
}
