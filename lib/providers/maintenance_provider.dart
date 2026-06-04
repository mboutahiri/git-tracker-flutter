import 'package:flutter/material.dart';

import '../data/services/maintenance_service.dart';
import '../domain/models/maintenance.dart';
import '../domain/models/maintenance_category.dart';

class MaintenanceProvider extends ChangeNotifier {
  final MaintenanceService _maintenanceService = MaintenanceService();

  Stream<List<MaintenanceCategory>> watchCategories(String driverId) {
    return _maintenanceService.watchCategories(driverId);
  }

  Stream<List<Maintenance>> watchMaintenances(String driverId) {
    return _maintenanceService.watchMaintenances(driverId);
  }

  Stream<List<Maintenance>> watchMaintenancesByVehicle({
    required String driverId,
    required String vehicleId,
  }) {
    return _maintenanceService.watchMaintenancesByVehicle(
      driverId: driverId,
      vehicleId: vehicleId,
    );
  }

  Stream<List<Maintenance>> watchMaintenancesByVehicleAndDate({
    required String driverId,
    required String vehicleId,
    required DateTime date,
  }) {
    return _maintenanceService.watchMaintenancesByVehicleAndDate(
      driverId: driverId,
      vehicleId: vehicleId,
      date: date,
    );
  }

  Stream<List<Maintenance>> watchMonthlyMaintenances({
    required String driverId,
    required DateTime month,
  }) {
    return _maintenanceService.watchMonthlyMaintenances(
      driverId: driverId,
      month: month,
    );
  }

  Future<void> addMaintenance({
    required String driverId,
    required String vehicleId,
    required String category,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    await _maintenanceService.addMaintenance(
      driverId: driverId,
      vehicleId: vehicleId,
      category: category,
      amount: amount,
      description: description,
      date: date,
    );
  }

  Future<void> addCategory({
    required String driverId,
    required String name,
  }) async {
    await _maintenanceService.addCategory(driverId: driverId, name: name);
  }
}
