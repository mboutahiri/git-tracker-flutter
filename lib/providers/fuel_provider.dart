import 'package:flutter/material.dart';

import '../data/services/fuel_service.dart';
import '../domain/models/fuel_entry.dart';

class FuelProvider extends ChangeNotifier {
  final FuelService _fuelService = FuelService();

  Stream<List<FuelEntry>> watchFuelEntries(String driverId) {
    return _fuelService.watchFuelEntries(driverId);
  }

  Stream<List<FuelEntry>> watchFuelEntriesByVehicle({
    required String driverId,
    required String vehicleId,
  }) {
    return _fuelService.watchFuelEntriesByVehicle(
      driverId: driverId,
      vehicleId: vehicleId,
    );
  }

  Stream<List<FuelEntry>> watchMonthlyFuelEntries({
    required String driverId,
    required DateTime month,
  }) {
    return _fuelService.watchMonthlyFuelEntries(
      driverId: driverId,
      month: month,
    );
  }

  Future<void> addFuelEntry({
    required String driverId,
    required String vehicleId,
    required double litres,
    required double amount,
    required DateTime date,
  }) async {
    await _fuelService.addFuelEntry(
      driverId: driverId,
      vehicleId: vehicleId,
      litres: litres,
      amount: amount,
      date: date,
    );
  }
}
