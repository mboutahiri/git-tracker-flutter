import 'package:cloud_firestore/cloud_firestore.dart';

class FuelEntry {
  final String id;
  final String driverId;
  final String vehicleId;
  final double litres;
  final double amount;
  final DateTime date;

  FuelEntry({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.litres,
    required this.amount,
    required this.date,
  });

  factory FuelEntry.fromMap(Map<String, dynamic> map) {
    return FuelEntry(
      id: map['id'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      vehicleId: map['vehicleId'] as String? ?? '',
      litres: (map['litres'] as num?)?.toDouble() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'litres': litres,
      'amount': amount,
      'date': Timestamp.fromDate(date),
    };
  }
}
