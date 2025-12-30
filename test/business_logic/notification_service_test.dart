import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shift_management_navigator/services/notification_service.dart';
import 'package:shift_management_navigator/providers/staff_provider.dart';
import 'package:shift_management_navigator/providers/notification_provider.dart';
import 'package:shift_management_navigator/providers/auth_provider.dart';
import 'package:shift_management_navigator/repositories/staff_repository.dart';
import 'package:shift_management_navigator/repositories/notification_repository.dart';
import 'package:shift_management_navigator/repositories/auth_repository.dart';
import 'package:shift_management_navigator/models/staff_model.dart';
import 'package:shift_management_navigator/models/user_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockStaffRepository extends Mock implements StaffRepository {}
class MockNotificationRepository extends Mock implements NotificationRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ProviderContainer container;
  late MockStaffRepository mockStaffRepository;
  late MockNotificationRepository mockNotificationRepository;
  late MockAuthRepository mockAuthRepository;
  late NotificationService notificationService;

  setUp(() {
    mockStaffRepository = MockStaffRepository();
    mockNotificationRepository = MockNotificationRepository();
    mockAuthRepository = MockAuthRepository();

    container = ProviderContainer(
      overrides: [
        staffRepositoryProvider.overrideWithValue(mockStaffRepository),
        notificationRepositoryProvider.overrideWithValue(mockNotificationRepository),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );

    notificationService = container.read(notificationServiceProvider);
  });

  group('NotificationService Tests', () {
    test('notifyAllStaff sends notifications to all staff except excluded user', () async {
      final staffs = [
        StaffModel(id: 's1', userId: 'u1', storeId: 'store_001', name: 'Staff A'),
        StaffModel(id: 's2', userId: 'u2', storeId: 'store_001', name: 'Staff B'),
        StaffModel(id: 's3', userId: 'u3', storeId: 'store_001', name: 'Staff C'),
      ];

      when(() => mockStaffRepository.getStaffsByStore('store_001'))
          .thenAnswer((_) async => staffs);
      when(() => mockNotificationRepository.createNotification(
            userId: any(named: 'userId'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => {});

      await notificationService.notifyAllStaff(
        storeId: 'store_001',
        title: 'Title',
        body: 'Body',
        excludeUserId: 'u1',
      );

      verify(() => mockNotificationRepository.createNotification(
            userId: 'u2',
            title: 'Title',
            body: 'Body',
          )).called(1);
      verify(() => mockNotificationRepository.createNotification(
            userId: 'u3',
            title: 'Title',
            body: 'Body',
          )).called(1);
      verifyNever(() => mockNotificationRepository.createNotification(
            userId: 'u1',
            title: any(named: 'title'),
            body: any(named: 'body'),
          ));
    });

    test('notifyAdmins sends notifications to all admins', () async {
      final admins = [
        UserModel(uid: 'a1', name: 'Admin 1', email: 'a1@example.com', role: AppConstants.roleAdmin),
        UserModel(uid: 'a2', name: 'Admin 2', email: 'a2@example.com', role: AppConstants.roleAdmin),
      ];

      when(() => mockAuthRepository.getUsersByStoreAndRole('store_001', AppConstants.roleAdmin))
          .thenAnswer((_) async => admins);
      when(() => mockNotificationRepository.createNotification(
            userId: any(named: 'userId'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => {});

      await notificationService.notifyAdmins(
        storeId: 'store_001',
        title: 'Admin Title',
        body: 'Admin Body',
      );

      verify(() => mockNotificationRepository.createNotification(
            userId: 'a1',
            title: 'Admin Title',
            body: 'Admin Body',
          )).called(1);
      verify(() => mockNotificationRepository.createNotification(
            userId: 'a2',
            title: 'Admin Title',
            body: 'Admin Body',
          )).called(1);
    });
  });
}
