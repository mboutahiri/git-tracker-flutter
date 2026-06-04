import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/constants.dart';
import '../../domain/models/vehicle.dart';

class VehicleService {
  final CollectionReference<Map<String, dynamic>> _vehicles =
      FirebaseFirestore.instance.collection(AppConstants.vehiclesCollection);

  Future<void> addVehicle({
    required String driverId,
    required String name,
    required String matricule,
  }) async {
    final doc = _vehicles.doc();
    final vehicle = Vehicle(
      id: doc.id,
      driverId: driverId,
      name: name,
      matricule: matricule,
      createdAt: DateTime.now(),
    );

    await doc.set(vehicle.toMap());
  }

  Stream<List<Vehicle>> watchVehicles(String driverId) {
    return _vehicles
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Vehicle.fromMap(doc.data()))
              .toList(),
        );
  }
}
