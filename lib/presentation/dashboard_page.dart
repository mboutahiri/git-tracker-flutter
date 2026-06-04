import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/models/fuel_entry.dart';
import '../domain/models/maintenance.dart' as domain;
import '../domain/models/vehicle.dart';
import '../core/utils/constants.dart';
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
                          padding: const EdgeInsets.all(
                            AppConstants.defaultPadding,
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.cardRadius,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(26),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.dashboard,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Monthly overview',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat.yMMMM().format(month),
                                          style: const TextStyle(
                                            color: Color(0xFFDCEAFF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount:
                                  MediaQuery.of(context).size.width > 720
                                  ? 3
                                  : 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.25,
                              children: [
                                _DashboardCard(
                                  icon: Icons.directions_car,
                                  title: 'Vehicles',
                                  value: vehicles.length.toString(),
                                ),
                                _DashboardCard(
                                  icon: Icons.account_balance_wallet,
                                  title: 'Expenses',
                                  value:
                                      '${totalExpenses.toStringAsFixed(2)} DH',
                                ),
                                _DashboardCard(
                                  icon: Icons.local_gas_station,
                                  title: 'Gasoil',
                                  value: '${totalFuel.toStringAsFixed(2)} DH',
                                ),
                                _DashboardCard(
                                  icon: Icons.build,
                                  title: 'Maintenance',
                                  value:
                                      '${totalMaintenance.toStringAsFixed(2)} DH',
                                ),
                                const _DashboardCard(
                                  icon: Icons.pie_chart,
                                  title: 'Repartition',
                                  value: '70% / 30%',
                                ),
                                _DashboardCard(
                                  icon: Icons.water_drop,
                                  title: 'Consumption',
                                  value: '${totalLitres.toStringAsFixed(2)} L',
                                ),
                              ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppConstants.lightBlueColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppConstants.primaryColor),
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppConstants.mutedTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
