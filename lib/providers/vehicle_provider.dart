import 'package:flutter/material.dart';

import '../data/services/vehicle_service.dart';
import '../domain/models/vehicle.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();

  Stream<List<Vehicle>> watchVehicles(String driverId) {
    return _vehicleService.watchVehicles(driverId);
  }

  Future<void> addVehicle({
    required String driverId,
    required String name,
    required String matricule,
  }) async {
    await _vehicleService.addVehicle(
      driverId: driverId,
      name: name,
      matricule: matricule,
    );
  }
}
