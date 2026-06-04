import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/models/fuel_entry.dart';
import '../domain/models/maintenance.dart' as domain;
import '../domain/models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../providers/fuel_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/vehicle_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<AuthProvider>().currentUser;
    final month = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please login first'))
          : StreamBuilder<List<Vehicle>>(
              stream: context.read<VehicleProvider>().watchVehicles(user.uid),
              builder: (context, vehicleSnapshot) {
                final vehicles = vehicleSnapshot.data ?? [];

                return StreamBuilder<List<FuelEntry>>(
                  stream: context.read<FuelProvider>().watchMonthlyFuelEntries(
                        driverId: user.uid,
                        month: month,
                      ),
                  builder: (context, fuelSnapshot) {
                    final fuelEntries = fuelSnapshot.data ?? [];
                    final totalFuel = fuelEntries.fold<double>(
                      0,
                      (sum, item) => sum + item.amount,
                    );
                    final totalLitres = fuelEntries.fold<double>(
                      0,
                      (sum, item) => sum + item.litres,
                    );

                    return StreamBuilder<List<domain.Maintenance>>(
                      stream: context
                          .read<MaintenanceProvider>()
                          .watchMonthlyMaintenances(
                            driverId: user.uid,
                            month: month,
                          ),
                      builder: (context, maintenanceSnapshot) {
                        final maintenances = maintenanceSnapshot.data ?? [];
                        final totalMaintenance = maintenances.fold<double>(
                          0,
                          (sum, item) => sum + item.amount,
                        );
                        final totalExpenses = totalFuel + totalMaintenance;

                        if (vehicleSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            fuelSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            maintenanceSnapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              DateFormat.yMMMM().format(month),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            _DashboardCard(
                              icon: Icons.directions_car,
                              title: 'Total vehicles',
                              value: vehicles.length.toString(),
                            ),
                            _DashboardCard(
                              icon: Icons.account_balance_wallet,
                              title: 'Monthly expenses',
                              value: '${totalExpenses.toStringAsFixed(2)} DH',
                            ),
                            _DashboardCard(
                              icon: Icons.local_gas_station,
                              title: 'Monthly gasoil',
                              value: '${totalFuel.toStringAsFixed(2)} DH',
                            ),
                            _DashboardCard(
                              icon: Icons.build,
                              title: 'Monthly maintenance',
                              value:
                                  '${totalMaintenance.toStringAsFixed(2)} DH',
                            ),
                            _DashboardCard(
                              icon: Icons.pie_chart,
                              title: 'Expense repartition',
                              value: '70% gasoil / 30% maintenance',
                            ),
                            _DashboardCard(
                              icon: Icons.water_drop,
                              title: 'Monthly gasoil consumption',
                              value: '${totalLitres.toStringAsFixed(2)} L',
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
