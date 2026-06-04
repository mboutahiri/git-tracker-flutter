import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/constants.dart';
import '../../domain/models/maintenance.dart';
import '../../domain/models/maintenance_category.dart';

class MaintenanceService {
  final CollectionReference<Map<String, dynamic>> _maintenances =
      FirebaseFirestore.instance.collection(AppConstants.maintenancesCollection);
  final CollectionReference<Map<String, dynamic>> _categories =
      FirebaseFirestore.instance
          .collection(AppConstants.maintenanceCategoriesCollection);

  Future<void> addMaintenance({
    required String driverId,
    required String vehicleId,
    required String category,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    final doc = _maintenances.doc();
    final maintenance = Maintenance(
      id: doc.id,
      driverId: driverId,
      vehicleId: vehicleId,
      category: category,
      amount: amount,
      description: description,
      date: date,
    );

    await doc.set(maintenance.toMap());
  }

  Future<void> addCategory({
    required String driverId,
    required String name,
  }) async {
    final doc = _categories.doc();
    final category = MaintenanceCategory(
      id: doc.id,
      driverId: driverId,
      name: name,
    );

    await doc.set(category.toMap());
  }

  Stream<List<MaintenanceCategory>> watchCategories(String driverId) {
    return _categories
        .where('driverId', isEqualTo: driverId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MaintenanceCategory.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<Maintenance>> watchMaintenances(String driverId) {
    return _maintenances
        .where('driverId', isEqualTo: driverId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Maintenance.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<Maintenance>> watchMaintenancesByVehicle({
    required String driverId,
    required String vehicleId,
  }) {
    return _maintenances
        .where('driverId', isEqualTo: driverId)
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Maintenance.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<Maintenance>> watchMaintenancesByVehicleAndDate({
    required String driverId,
    required String vehicleId,
    required DateTime date,
  }) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return _maintenances
        .where('driverId', isEqualTo: driverId)
        .where('vehicleId', isEqualTo: vehicleId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Maintenance.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<Maintenance>> watchMonthlyMaintenances({
    required String driverId,
    required DateTime month,
  }) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    return _maintenances
        .where('driverId', isEqualTo: driverId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Maintenance.fromMap(doc.data()))
              .toList(),
        );
  }
}
