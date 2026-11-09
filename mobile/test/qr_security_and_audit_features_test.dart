import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/qr_security_service.dart';
import 'package:mobile/services/fleet_state.dart';
import 'package:mobile/models/bus_expense_model.dart';
import 'package:mobile/models/lost_item_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Cryptographic Dynamic Passenger QR Code Service', () {
    final qrService = QrSecurityService.instance;

    test('Generates valid v2 HMAC signed token for passenger', () {
      final token = qrService.generateSignedPassengerQr('SBK-KL-409123');
      expect(token.startsWith('ENROUTE:PASSENGER:v2:SBK-KL-409123:'), isTrue);

      final result = qrService.verifyPassengerQr(token);
      expect(result.isValid, isTrue);
      expect(result.passengerId, equals('SBK-KL-409123'));
      expect(result.isExpired, isFalse);
      expect(result.isTampered, isFalse);
    });

    test('Rejects expired screenshot token (> 150 seconds old)', () {
      final expiredTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 200;
      final expiredToken = qrService.generateSignedPassengerQr('SBK-KL-409123', timestampOverride: expiredTimestamp);

      final result = qrService.verifyPassengerQr(expiredToken);
      expect(result.isValid, isFalse);
      expect(result.isExpired, isTrue);
      expect(result.errorMessage, contains('Expired'));
    });

    test('Rejects counterfeit / tampered token with manipulated passenger ID', () {
      final token = qrService.generateSignedPassengerQr('SBK-KL-409123');
      // Tamper with passenger ID in the payload
      final tamperedToken = token.replaceAll('SBK-KL-409123', 'SBK-KL-999999');

      final result = qrService.verifyPassengerQr(tamperedToken);
      expect(result.isValid, isFalse);
      expect(result.isTampered, isTrue);
      expect(result.errorMessage, contains('Tampered'));
    });

    test('Maintains backwards compatibility for legacy format', () {
      final legacy = 'SMARTBUS:PASSENGER:SBK-KL-001245';
      final result = qrService.verifyPassengerQr(legacy);
      expect(result.isValid, isTrue);
      expect(result.passengerId, equals('SBK-KL-001245'));
      expect(result.isLegacy, isTrue);
    });
  });

  group('2. Operational Expenses & Real Financial Ledger', () {
    final fleet = FleetState.instance;

    test('Logs real bus operational expenses and calculates net profit', () {
      final testExpense = BusExpenseRecord(
        id: 'EXP-TEST-001',
        busRegNumber: 'KL 10 AZ 4589',
        ownerId: 'OWNER-1',
        category: 'Diesel / Fuel',
        amount: 3500.0,
        date: DateTime.now(),
        note: 'Full tank Indian Oil Aluva',
      );

      fleet.addExpense(testExpense);
      final busExpenses = fleet.getExpensesForBus('KL 10 AZ 4589');
      expect(busExpenses.any((e) => e.id == 'EXP-TEST-001'), isTrue);

      final report = fleet.getProfitReportForOwner('OWNER-1', OwnerTimeframe.daily);
      expect(report.totalExpenses, greaterThanOrEqualTo(3500.0));
      expect(report.fuelExpense, greaterThanOrEqualTo(3500.0));
      expect(report.busBreakdowns.any((b) => b.isRecordedExpense), isTrue);

      fleet.deleteExpense('EXP-TEST-001');
    });
  });

  group('3. 3-Tier Bus Occupancy Telemetry (Singapore Benchmark)', () {
    final fleet = FleetState.instance;

    test('Broadcasts and transitions live bus occupancy status', () {
      final bus = fleet.getBusByReg('KL 10 AZ 4589');
      expect(bus, isNotNull);

      fleet.updateBusOccupancy('KL 10 AZ 4589', 'STANDING_AVAILABLE');
      final updated = fleet.getBusByReg('KL 10 AZ 4589');
      expect(updated!.occupancyStatus, equals('STANDING_AVAILABLE'));
      expect(updated.occupancyLabel, equals('Standing Only'));

      fleet.updateBusOccupancy('KL 10 AZ 4589', 'HEAVILY_CROWDED');
      final crowded = fleet.getBusByReg('KL 10 AZ 4589');
      expect(crowded!.occupancyStatus, equals('HEAVILY_CROWDED'));
      expect(crowded.occupancyLabel, equals('Heavily Crowded'));

      // Restore to seats available
      fleet.updateBusOccupancy('KL 10 AZ 4589', 'SEATS_AVAILABLE');
      expect(fleet.getBusByReg('KL 10 AZ 4589')!.occupancyStatus, equals('SEATS_AVAILABLE'));
    });
  });

  group('4. Lost & Found Reporting Lifecycle', () {
    final fleet = FleetState.instance;

    test('Allows passenger to report lost item and crew to mark found', () {
      final lostReport = LostItemReport(
        id: 'LOST-TEST-001',
        busRegNumber: 'KL 10 AZ 4589',
        busName: 'Sana',
        itemCategory: 'Bag / Backpack',
        description: 'Blue college backpack with books',
        reporterName: 'Fathima',
        reporterPhone: '9847123456',
        dateReported: DateTime.now(),
      );

      fleet.reportLostItem(lostReport);
      expect(fleet.lostItems.any((item) => item.id == 'LOST-TEST-001'), isTrue);

      fleet.resolveLostItem('LOST-TEST-001', 'FOUND_IN_BUS', 'Recovered by conductor behind seat 14');
      final foundItem = fleet.lostItems.firstWhere((i) => i.id == 'LOST-TEST-001');
      expect(foundItem.status, equals('FOUND_IN_BUS'));
      expect(foundItem.resolutionNotes, contains('Recovered'));
    });
  });
}
