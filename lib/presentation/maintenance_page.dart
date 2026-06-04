import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/utils/constants.dart';
import '../domain/models/maintenance.dart' as domain;
import '../domain/models/maintenance_category.dart';
import '../domain/models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/vehicle_provider.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedVehicleId;
  String? _selectedCategory;

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double? _readAmount() {
    return double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
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

  Future<void> _addMaintenance({
    required String driverId,
    required String vehicleId,
    required List<MaintenanceCategory> categories,
  }) async {
    final typedCategory = _categoryController.text.trim();
    final category = typedCategory.isNotEmpty
        ? typedCategory
        : (_selectedCategory ?? '').trim();
    final amount = _readAmount();
    final description = _descriptionController.text.trim();

    if (category.isEmpty || amount == null || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category, amount and description are required'),
        ),
      );
      return;
    }

    final provider = context.read<MaintenanceProvider>();
    final exists = categories.any(
      (item) => item.name.toLowerCase() == category.toLowerCase(),
    );

    if (!exists) {
      await provider.addCategory(driverId: driverId, name: category);
    }

    await provider.addMaintenance(
      driverId: driverId,
      vehicleId: vehicleId,
      category: category,
      amount: amount,
      description: description,
      date: _selectedDate,
    );

    if (!mounted) return;
    _categoryController.clear();
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      body: user == null
          ? const Center(child: Text('Please login first'))
          : StreamBuilder<List<Vehicle>>(
              stream: context.read<VehicleProvider>().watchVehicles(user.uid),
              builder: (context, vehicleSnapshot) {
                if (vehicleSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final vehicles = vehicleSnapshot.data ?? [];
                if (vehicles.isEmpty) {
                  return const Center(
                    child: Text('Add a vehicle before maintenance'),
                  );
                }

                final selectedVehicleId =
                    vehicles.any((v) => v.id == _selectedVehicleId)
                    ? _selectedVehicleId!
                    : vehicles.first.id;

                return StreamBuilder<List<MaintenanceCategory>>(
                  stream: context.read<MaintenanceProvider>().watchCategories(
                    user.uid,
                  ),
                  builder: (context, categorySnapshot) {
                    final categories = categorySnapshot.data ?? [];
                    final selectedCategory =
                        categories.any((c) => c.name == _selectedCategory)
                        ? _selectedCategory
                        : null;

                    return ListView(
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
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
                                        Icons.build,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'New maintenance',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedVehicleId,
                                  decoration: const InputDecoration(
                                    labelText: 'Vehicle',
                                    prefixIcon: Icon(Icons.directions_car),
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
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedCategory,
                                  decoration: const InputDecoration(
                                    labelText: 'Choose category',
                                    prefixIcon: Icon(Icons.category),
                                  ),
                                  items: categories
                                      .map(
                                        (category) => DropdownMenuItem(
                                          value: category.name,
                                          child: Text(category.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _categoryController,
                                  decoration: const InputDecoration(
                                    labelText: 'Or type a new category',
                                    prefixIcon: Icon(Icons.edit),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Amount',
                                    prefixIcon: Icon(Icons.payments),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    prefixIcon: Icon(Icons.description),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.calendar_month),
                                  title: Text(
                                    DateFormat.yMMMMd().format(_selectedDate),
                                  ),
                                  trailing: OutlinedButton(
                                    onPressed: _pickDate,
                                    child: const Text('Choose'),
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _addMaintenance(
                                      driverId: user.uid,
                                      vehicleId: selectedVehicleId,
                                      categories: categories,
                                    ),
                                    icon: const Icon(Icons.save),
                                    label: const Text('Save maintenance'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 340,
                          child: _MaintenanceList(
                            driverId: user.uid,
                            vehicleId: selectedVehicleId,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

class _MaintenanceList extends StatelessWidget {
  final String driverId;
  final String vehicleId;

  const _MaintenanceList({required this.driverId, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<domain.Maintenance>>(
      stream: context.read<MaintenanceProvider>().watchMaintenancesByVehicle(
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

        final maintenances = snapshot.data ?? [];
        if (maintenances.isEmpty) {
          return const Center(child: Text('No maintenance for this vehicle'));
        }

        return ListView.builder(
          itemCount: maintenances.length,
          itemBuilder: (context, index) {
            final maintenance = maintenances[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppConstants.lightBlueColor,
                  child: const Icon(
                    Icons.build,
                    color: AppConstants.primaryColor,
                  ),
                ),
                title: Text(
                  maintenance.category,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${maintenance.description}\n'
                  '${DateFormat.yMMMMd().format(maintenance.date)}',
                ),
                isThreeLine: true,
                trailing: Text(
                  '${maintenance.amount.toStringAsFixed(2)} DH',
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
