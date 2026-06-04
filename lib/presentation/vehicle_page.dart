import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Vehicle name',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _matriculeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Matricule',
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _addVehicle(user.uid),
                      icon: const Icon(Icons.add),
                      label: const Text('Add vehicle'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<Vehicle>>(
                      stream: context
                          .read<VehicleProvider>()
                          .watchVehicles(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        final vehicles = snapshot.data ?? [];
                        if (vehicles.isEmpty) {
                          return const Center(
                            child: Text('No vehicles added yet'),
                          );
                        }

                        return ListView.separated(
                          itemCount: vehicles.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];
                            return ListTile(
                              leading: const Icon(Icons.directions_car),
                              title: Text(vehicle.name),
                              subtitle: Text(
                                '${vehicle.matricule} - '
                                '${DateFormat.yMd().format(vehicle.createdAt)}',
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
