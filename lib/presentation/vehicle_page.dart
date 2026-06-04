import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/utils/constants.dart';
import '../domain/models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';

class VehiclePage extends StatefulWidget {
  const VehiclePage({super.key});

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  Future<void> _addVehicle(String driverId) async {
    final name = _nameController.text.trim();
    final matricule = _matriculeController.text.trim();

    if (name.isEmpty || matricule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and matricule are required')),
      );
      return;
    }

    await context.read<VehicleProvider>().addVehicle(
      driverId: driverId,
      name: name,
      matricule: matricule,
    );

    if (!mounted) return;
    _nameController.clear();
    _matriculeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicles')),
      body: user == null
          ? const Center(child: Text('Please login first'))
          : Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppConstants.lightBlueColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Add vehicle',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle name',
                              prefixIcon: Icon(Icons.directions_car),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _matriculeController,
                            decoration: const InputDecoration(
                              labelText: 'Matricule',
                              prefixIcon: Icon(Icons.confirmation_number),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _addVehicle(user.uid),
                              icon: const Icon(Icons.add),
                              label: const Text('Add vehicle'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<Vehicle>>(
                      stream: context.read<VehicleProvider>().watchVehicles(
                        user.uid,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final vehicles = snapshot.data ?? [];
                        if (vehicles.isEmpty) {
                          return const Center(
                            child: Text('No vehicles added yet'),
                          );
                        }

                        return ListView.separated(
                          itemCount: vehicles.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: AppConstants.lightBlueColor,
                                  child: const Icon(
                                    Icons.directions_car,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                title: Text(
                                  vehicle.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  '${vehicle.matricule} - '
                                  '${DateFormat.yMd().format(vehicle.createdAt)}',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
