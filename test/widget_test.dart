import 'package:flutter_test/flutter_test.dart';
import 'package:git_tracker_flutter/core/utils/constants.dart';

void main() {
  test('app constants are configured', () {
    expect(AppConstants.appName, 'Git Tracker Flutter');
    expect(AppConstants.vehiclesCollection, 'vehicles');
    expect(AppConstants.fuelEntriesCollection, 'fuel_entries');
    expect(AppConstants.maintenancesCollection, 'maintenances');
  });
}
