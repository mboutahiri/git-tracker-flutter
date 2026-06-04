import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/constants.dart';
import '../../domain/models/fuel_entry.dart';

class FuelService {
  final CollectionReference<Map<String, dynamic>> _fuelEntries =
      FirebaseFirestore.instance.collection(AppConstants.fuelEntriesCollection);

  Future<void> addFuelEntry({
    required String driverId,
    required String vehicleId,
    required double litres,
    required double amount,
    required DateTime date,
  }) async {
    final doc = _fuelEntries.doc();
    final entry = FuelEntry(
      id: doc.id,
      driverId: driverId,
      vehicleId: vehicleId,
      litres: litres,
      amount: amount,
      date: date,
    );

    await doc.set(entry.toMap());
  }

  Stream<List<FuelEntry>> watchFuelEntries(String driverId) {
    return _fuelEntries
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => FuelEntry.fromMap(doc.data()))
          .toList();
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    });
  }

  Stream<List<FuelEntry>> watchFuelEntriesByVehicle({
    required String driverId,
    required String vehicleId,
  }) {
    return _fuelEntries
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => FuelEntry.fromMap(doc.data()))
          .where((entry) => entry.vehicleId == vehicleId)
          .toList();
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    });
  }

  Stream<List<FuelEntry>> watchMonthlyFuelEntries({
    required String driverId,
    required DateTime month,
  }) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    return _fuelEntries
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => FuelEntry.fromMap(doc.data()))
          .where((entry) => !entry.date.isBefore(start) && entry.date.isBefore(end))
          .toList();
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    });
  }
}
