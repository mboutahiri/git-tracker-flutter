import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/models/maintenance.dart' as domain;
import '../domain/models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/vehicle_provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _selectedVehicleId;
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: user == null
          ? const Center(child: Text('Please login first'))
          : StreamBuilder<List<Vehicle>>(
              stream: context.read<VehicleProvider>().watchVehicles(user.uid),
              builder: (context, vehicleSnapshot) {
                if (vehicleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final vehicles = vehicleSnapshot.data ?? [];
                if (vehicles.isEmpty) {
                  return const Center(
                    child: Text('Add a vehicle before viewing history'),
                  );
                }

                final selectedVehicleId =
                    vehicles.any((v) => v.id == _selectedVehicleId)
                        ? _selectedVehicleId!
                        : vehicles.first.id;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedVehicleId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Vehicle',
                        ),
                        items: vehicles
                            .map(
                              (vehicle) => DropdownMenuItem(
                                value: vehicle.id,
                                child: Text(
                                  '${vehicle.name} (${vehicle.matricule})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                _selectedDate == null
                                    ? 'Filter by date'
                                    : DateFormat.yMMMMd()
                                        .format(_selectedDate!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Clear date filter',
                            onPressed: _selectedDate == null
                                ? null
                                : () {
                                    setState(() {
                                      _selectedDate = null;
                                    });
                                  },
                            icon: const Icon(Icons.clear),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _HistoryList(
                          driverId: user.uid,
                          vehicleId: selectedVehicleId,
                          selectedDate: _selectedDate,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final String driverId;
  final String vehicleId;
  final DateTime? selectedDate;

  const _HistoryList({
    required this.driverId,
    required this.vehicleId,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MaintenanceProvider>();
    final stream = selectedDate == null
        ? provider.watchMaintenancesByVehicle(
            driverId: driverId,
            vehicleId: vehicleId,
          )
        : provider.watchMaintenancesByVehicleAndDate(
            driverId: driverId,
            vehicleId: vehicleId,
            date: selectedDate!,
          );

    return StreamBuilder<List<domain.Maintenance>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No maintenance history found'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final maintenance = items[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(maintenance.category),
                subtitle: Text(
                  '${maintenance.description}\n'
                  '${DateFormat.yMMMMd().format(maintenance.date)}',
                ),
                isThreeLine: true,
                trailing: Text('${maintenance.amount.toStringAsFixed(2)} DH'),
              ),
            );
          },
        );
      },
    );
  }
}
