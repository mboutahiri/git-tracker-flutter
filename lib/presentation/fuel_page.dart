import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/models/fuel_entry.dart';
import '../domain/models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../providers/fuel_provider.dart';
import '../providers/vehicle_provider.dart';

class FuelPage extends StatefulWidget {
  const FuelPage({super.key});

  @override
  State<FuelPage> createState() => _FuelPageState();
}

class _FuelPageState extends State<FuelPage> {
  final TextEditingController _litresController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedVehicleId;

  @override
  void dispose() {
    _litresController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? _readNumber(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.'));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addFuelEntry({
    required String driverId,
    required String vehicleId,
  }) async {
    final litres = _readNumber(_litresController);
    final amount = _readNumber(_amountController);

    if (litres == null || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Litres and amount must be valid numbers')),
      );
      return;
    }

    await context.read<FuelProvider>().addFuelEntry(
          driverId: driverId,
          vehicleId: vehicleId,
          litres: litres,
          amount: amount,
          date: _selectedDate,
        );

    if (!mounted) return;
    _litresController.clear();
    _amountController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Fuel')),
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
                    child: Text('Add a vehicle before adding fuel entries'),
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
                      TextField(
                        controller: _litresController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Litres',
                          prefixIcon: Icon(Icons.water_drop),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.payments),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month),
                        title: Text(DateFormat.yMMMMd().format(_selectedDate)),
                        trailing: ElevatedButton(
                          onPressed: _pickDate,
                          child: const Text('Choose date'),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _addFuelEntry(
                            driverId: user.uid,
                            vehicleId: selectedVehicleId,
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text('Save fuel entry'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _FuelEntryList(
                          driverId: user.uid,
                          vehicleId: selectedVehicleId,
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

class _FuelEntryList extends StatelessWidget {
  final String driverId;
  final String vehicleId;

  const _FuelEntryList({
    required this.driverId,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FuelEntry>>(
      stream: context.read<FuelProvider>().watchFuelEntriesByVehicle(
            driverId: driverId,
            vehicleId: vehicleId,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(child: Text('No fuel entries for this vehicle'));
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.local_gas_station),
                title: Text('${entry.litres.toStringAsFixed(2)} L'),
                subtitle: Text(DateFormat.yMMMMd().format(entry.date)),
                trailing: Text('${entry.amount.toStringAsFixed(2)} DH'),
              ),
            );
          },
        );
      },
    );
  }
}
