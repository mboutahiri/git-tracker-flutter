import 'package:cloud_firestore/cloud_firestore.dart';

class Maintenance {
  final String id;
  final String driverId;
  final String vehicleId;
  final String category;
  final double amount;
  final String description;
  final DateTime date;

  Maintenance({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory Maintenance.fromMap(Map<String, dynamic> map) {
    return Maintenance(
      id: map['id'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      category: map['category'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'category': category,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
    };
  }
}
