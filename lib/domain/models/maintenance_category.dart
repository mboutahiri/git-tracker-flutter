class MaintenanceCategory {
  final String id;
  final String driverId;
  final String name;

  MaintenanceCategory({
    required this.id,
    required this.driverId,
    required this.name,
  });

  factory MaintenanceCategory.fromMap(Map<String, dynamic> map) {
    return MaintenanceCategory(
      id: map['id'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'name': name,
    };
  }
}
