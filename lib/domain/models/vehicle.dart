import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String id;
  final String driverId;
  final String name;
  final String matricule;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.driverId,
    required this.name,
    required this.matricule,
    required this.createdAt,
  });

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      matricule: map['matricule'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'name': name,
      'matricule': matricule,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
