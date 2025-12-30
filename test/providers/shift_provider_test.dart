import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/providers/shift_provider.dart';
import 'package:shift_management_navigator/repositories/shift_repository.dart';
import 'package:shift_management_navigator/models/shift_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockShiftRepository extends Mock implements ShiftRepository {}

void main() {
  late MockShiftRepository mockShiftRepository;

  setUp(() {
    mockShiftRepository = MockShiftRepository();
  });

  group('ShiftProvider Tests', () {
    test('recruitingSubstitutesProvider returns list of shifts', () async {
      final mockShifts = [
        ShiftModel(
          id: '1',
          storeId: 'store_01',
          staffId: 'staff_01',
          date: '2025-12-30',
          startTime: '09:00',
          endTime: '18:00',
          status: AppConstants.shiftStatusConfirmed,
        ),
      ];

      when(() => mockShiftRepository.getRecruitingSubstitutes('store_01'))
          .thenAnswer((_) async => mockShifts);

      final container = ProviderContainer(
        overrides: [
          shiftRepositoryProvider.overrideWithValue(mockShiftRepository),
        ],
      );

      final result = await container.read(recruitingSubstitutesProvider('store_01').future);

      expect(result, mockShifts);
      verify(() => mockShiftRepository.getRecruitingSubstitutes('store_01')).called(1);
    });
  });
}
