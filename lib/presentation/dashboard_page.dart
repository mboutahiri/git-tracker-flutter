import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/utils/constants.dart';
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
      backgroundColor: AppConstants.backgroundColor,
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
                  stream: context.read<FuelProvider>().watchFuelEntries(
                    user.uid,
                  ),
                  builder: (context, fuelSnapshot) {
                    final fuelEntries = fuelSnapshot.data ?? [];

                    return StreamBuilder<List<domain.Maintenance>>(
                      stream: context
                          .read<MaintenanceProvider>()
                          .watchMaintenances(user.uid),
                      builder: (context, maintenanceSnapshot) {
                        final maintenances = maintenanceSnapshot.data ?? [];
                        final monthlyFuelEntries = fuelEntries
                            .where((entry) => _isSameMonth(entry.date, month))
                            .toList();
                        final monthlyMaintenances = maintenances
                            .where((item) => _isSameMonth(item.date, month))
                            .toList();
                        final totalFuel = monthlyFuelEntries.fold<double>(
                          0,
                          (sum, item) => sum + item.amount,
                        );
                        final totalLitres = monthlyFuelEntries.fold<double>(
                          0,
                          (sum, item) => sum + item.litres,
                        );
                        final totalMaintenance = monthlyMaintenances
                            .fold<double>(0, (sum, item) => sum + item.amount);
                        final totalExpenses = totalFuel + totalMaintenance;
                        final monthlyData = _buildMonthlyData(
                          fuelEntries: fuelEntries,
                          maintenances: maintenances,
                        );

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
                            _DashboardHeader(month: month),
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
                                  backgroundColor:
                                      AppConstants.vehicleSoftColor,
                                  accentColor: const Color.fromARGB(255, 163, 71, 22),
                                ),
                                _DashboardCard(
                                  icon: Icons.account_balance_wallet,
                                  title: 'Expenses',
                                  value:
                                      '${totalExpenses.toStringAsFixed(2)} DH',
                                  backgroundColor:
                                      AppConstants.expenseSoftColor,
                                  accentColor: AppConstants.expenseColor,
                                ),
                                _DashboardCard(
                                  icon: Icons.local_gas_station,
                                  title: 'Gasoil',
                                  value: '${totalFuel.toStringAsFixed(2)} DH',
                                  backgroundColor: AppConstants.fuelSoftColor,
                                  accentColor: AppConstants.fuelColor,
                                ),
                                _DashboardCard(
                                  icon: Icons.build,
                                  title: 'Maintenance',
                                  value:
                                      '${totalMaintenance.toStringAsFixed(2)} DH',
                                  backgroundColor:
                                      AppConstants.maintenanceSoftColor,
                                  accentColor: AppConstants.maintenanceColor,
                                ),
                                const _DashboardCard(
                                  icon: Icons.pie_chart,
                                  title: 'Repartition',
                                  value: '70% / 30%',
                                  backgroundColor: AppConstants.totalSoftColor,
                                  accentColor: AppConstants.totalColor,
                                ),
                                _DashboardCard(
                                  icon: Icons.water_drop,
                                  title: 'Consumption',
                                  value: '${totalLitres.toStringAsFixed(2)} L',
                                  backgroundColor: AppConstants.fuelSoftColor,
                                  accentColor: AppConstants.fuelColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _ExpenseSplitChart(
                              fuelAmount: totalFuel,
                              maintenanceAmount: totalMaintenance,
                            ),
                            const SizedBox(height: 16),
                            _FuelConsumptionChart(monthlyData: monthlyData),
                            const SizedBox(height: 16),
                            _MonthlyExpensesChart(monthlyData: monthlyData),
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

bool _isSameMonth(DateTime first, DateTime second) {
  return first.year == second.year && first.month == second.month;
}

List<_MonthDashboardData> _buildMonthlyData({
  required List<FuelEntry> fuelEntries,
  required List<domain.Maintenance> maintenances,
}) {
  final now = DateTime.now();
  final months = List.generate(
    6,
    (index) => DateTime(now.year, now.month - (5 - index)),
  );

  return months.map((month) {
    final fuelForMonth = fuelEntries.where(
      (entry) => _isSameMonth(entry.date, month),
    );
    final maintenanceForMonth = maintenances.where(
      (item) => _isSameMonth(item.date, month),
    );

    return _MonthDashboardData(
      month: month,
      fuelLitres: fuelForMonth.fold<double>(
        0,
        (sum, entry) => sum + entry.litres,
      ),
      fuelAmount: fuelForMonth.fold<double>(
        0,
        (sum, entry) => sum + entry.amount,
      ),
      maintenanceAmount: maintenanceForMonth.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      ),
    );
  }).toList();
}

class _MonthDashboardData {
  final DateTime month;
  final double fuelLitres;
  final double fuelAmount;
  final double maintenanceAmount;

  const _MonthDashboardData({
    required this.month,
    required this.fuelLitres,
    required this.fuelAmount,
    required this.maintenanceAmount,
  });

  double get totalAmount => fuelAmount + maintenanceAmount;
}

class _DashboardHeader extends StatelessWidget {
  final DateTime month;

  const _DashboardHeader({required this.month});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.primaryColor, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withAlpha(28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.dashboard, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: const TextStyle(color: Color(0xFFDCEAFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color backgroundColor;
  final Color accentColor;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: 2,
      shadowColor: accentColor.withAlpha(22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        side: BorderSide(color: accentColor.withAlpha(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(190),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppConstants.textDarkColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseSplitChart extends StatelessWidget {
  final double fuelAmount;
  final double maintenanceAmount;

  const _ExpenseSplitChart({
    required this.fuelAmount,
    required this.maintenanceAmount,
  });

  @override
  Widget build(BuildContext context) {
    final total = fuelAmount + maintenanceAmount;
    final hasData = total > 0;
    final fuelRatio = hasData ? fuelAmount / total : 0.7;
    final maintenanceRatio = hasData ? maintenanceAmount / total : 0.3;

    return _ChartCard(
      icon: Icons.pie_chart,
      title: 'Repartition des depenses',
      subtitle: 'Gasoil vs maintenance',
      child: Column(
        children: [
          if (!hasData) const _NoDataMessage(),
          Row(
            children: [
              SizedBox(
                height: 118,
                width: 118,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 112,
                      width: 112,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 15,
                        color: AppConstants.maintenanceColor.withAlpha(150),
                        backgroundColor: AppConstants.maintenanceSoftColor,
                      ),
                    ),
                    SizedBox(
                      height: 112,
                      width: 112,
                      child: CircularProgressIndicator(
                        value: fuelRatio,
                        strokeWidth: 15,
                        color: AppConstants.fuelColor,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(fuelRatio * 100).round()}%',
                          style: const TextStyle(
                            color: AppConstants.fuelColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'Gasoil',
                          style: TextStyle(
                            color: AppConstants.mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _LegendRow(
                      color: AppConstants.fuelColor,
                      label: 'Gasoil',
                      value:
                          '${(fuelRatio * 100).round()}% - ${fuelAmount.toStringAsFixed(2)} DH',
                    ),
                    const SizedBox(height: 10),
                    _LegendRow(
                      color: AppConstants.maintenanceColor,
                      label: 'Maintenance',
                      value:
                          '${(maintenanceRatio * 100).round()}% - ${maintenanceAmount.toStringAsFixed(2)} DH',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FuelConsumptionChart extends StatelessWidget {
  final List<_MonthDashboardData> monthlyData;

  const _FuelConsumptionChart({required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    final maxLitres = monthlyData.fold<double>(
      0,
      (max, item) => item.fuelLitres > max ? item.fuelLitres : max,
    );

    return _ChartCard(
      icon: Icons.local_gas_station,
      title: 'Consommation gasoil',
      subtitle: 'Litres consommes par mois',
      child: maxLitres == 0
          ? const _NoDataMessage()
          : _SimpleBarChart(
              monthlyData: monthlyData,
              maxValue: maxLitres,
              valueBuilder: (item) => item.fuelLitres,
              color: AppConstants.fuelColor,
              softColor: AppConstants.fuelSoftColor,
              suffix: 'L',
            ),
    );
  }
}

class _MonthlyExpensesChart extends StatelessWidget {
  final List<_MonthDashboardData> monthlyData;

  const _MonthlyExpensesChart({required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    final maxTotal = monthlyData.fold<double>(
      0,
      (max, item) => item.totalAmount > max ? item.totalAmount : max,
    );

    return _ChartCard(
      icon: Icons.bar_chart,
      title: 'Depenses par mois',
      subtitle: 'Gasoil, maintenance et total',
      child: Column(
        children: [
          if (maxTotal == 0)
            const _NoDataMessage()
          else
            _StackedExpenseBars(monthlyData: monthlyData, maxValue: maxTotal),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _SmallLegend(color: AppConstants.fuelColor, label: 'Gasoil'),
              _SmallLegend(
                color: AppConstants.maintenanceColor,
                label: 'Maintenance',
              ),
              _SmallLegend(color: AppConstants.totalColor, label: 'Total'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: AppConstants.primaryColor.withAlpha(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.totalSoftColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppConstants.totalColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppConstants.textDarkColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppConstants.mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final List<_MonthDashboardData> monthlyData;
  final double maxValue;
  final double Function(_MonthDashboardData item) valueBuilder;
  final Color color;
  final Color softColor;
  final String suffix;

  const _SimpleBarChart({
    required this.monthlyData,
    required this.maxValue,
    required this.valueBuilder,
    required this.color,
    required this.softColor,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: monthlyData.map((item) {
          final value = valueBuilder(item);
          final heightFactor = maxValue == 0 ? 0.0 : value / maxValue;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    value == 0 ? '-' : value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppConstants.textDarkColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: heightFactor.clamp(0.05, 1.0),
                        child: Container(
                          width: 22,
                          decoration: BoxDecoration(
                            color: value == 0 ? softColor : color,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.MMM().format(item.month),
                    style: const TextStyle(
                      color: AppConstants.mutedTextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StackedExpenseBars extends StatelessWidget {
  final List<_MonthDashboardData> monthlyData;
  final double maxValue;

  const _StackedExpenseBars({
    required this.monthlyData,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: monthlyData.map((item) {
        final fuelRatio = maxValue == 0 ? 0.0 : item.fuelAmount / maxValue;
        final maintenanceRatio = maxValue == 0
            ? 0.0
            : item.maintenanceAmount / maxValue;
        final totalRatio = maxValue == 0 ? 0.0 : item.totalAmount / maxValue;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  DateFormat.MMM().format(item.month),
                  style: const TextStyle(
                    color: AppConstants.mutedTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _ExpenseProgressBar(
                      value: fuelRatio,
                      color: AppConstants.fuelColor,
                      backgroundColor: AppConstants.fuelSoftColor,
                    ),
                    const SizedBox(height: 4),
                    _ExpenseProgressBar(
                      value: maintenanceRatio,
                      color: AppConstants.maintenanceColor,
                      backgroundColor: AppConstants.maintenanceSoftColor,
                    ),
                    const SizedBox(height: 4),
                    _ExpenseProgressBar(
                      value: totalRatio,
                      color: AppConstants.totalColor,
                      backgroundColor: AppConstants.totalSoftColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                child: Text(
                  '${item.totalAmount.toStringAsFixed(0)} DH',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppConstants.textDarkColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ExpenseProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color backgroundColor;

  const _ExpenseProgressBar({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        minHeight: 8,
        value: value.clamp(0.0, 1.0),
        color: color,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 12,
          width: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppConstants.textDarkColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppConstants.mutedTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SmallLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _SmallLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.mutedTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _NoDataMessage extends StatelessWidget {
  const _NoDataMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        'Aucune donnée disponible',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppConstants.mutedTextColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
