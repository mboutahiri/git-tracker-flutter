import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  Driver({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
