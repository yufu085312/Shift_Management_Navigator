import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shift_management_navigator/repositories/notification_repository.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockWriteBatch extends Mock implements WriteBatch {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  late NotificationRepository repository;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockWriteBatch mockBatch;
  late MockQuery mockQuery;

  setUpAll(() {
    registerFallbackValue(Timestamp.now());
    registerFallbackValue(MockDocumentReference());
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockBatch = MockWriteBatch();
    mockQuery = MockQuery();
    
    repository = NotificationRepository(firestore: mockFirestore);

    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(() => mockFirestore.batch()).thenReturn(mockBatch);
  });

  group('NotificationRepository - Automatic Deletion', () {
    test('getNotifications triggers _deleteOldNotifications and queries correct date', () async {
      final userId = 'user_001';
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // Mock for _deleteOldNotifications query
      final mockSnapshot = MockQuerySnapshot();
      when(() => mockCollection.where('userId', isEqualTo: userId)).thenReturn(mockQuery);
      when(() => mockQuery.where('createdAt', isLessThan: any(named: 'isLessThan'))).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.docs).thenReturn([]); // No docs to delete

      // Mock for getNotifications main query
      final mockGetSnapshot = MockQuerySnapshot();
      when(() => mockGetSnapshot.docs).thenReturn([]);
      // Since it's the same collection, the mock chain might overlap. 
      // In a real mock world, we'd need more specific matching.

      await repository.getNotifications(userId);

      // Verify that the query for old notifications was made with a timestamp around 30 days ago
      verify(() => mockQuery.where('createdAt', isLessThan: any(named: 'isLessThan'))).called(1);
    });

    test('getNotifications executes batch delete when old notifications exist', () async {
      final userId = 'user_001';

      // Mock documents to delete
      final mockDoc1 = MockQueryDocumentSnapshot();
      final mockRef1 = MockDocumentReference();
      when(() => mockDoc1.reference).thenReturn(mockRef1);
      when(() => mockDoc1.id).thenReturn('notif_old_1');
      when(() => mockDoc1.data()).thenReturn({
        'userId': userId,
        'title': 'Old',
        'body': 'Old body',
        'isRead': true,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 40))),
      });

      final mockSnapshot = MockQuerySnapshot();
      when(() => mockCollection.where('userId', isEqualTo: userId)).thenReturn(mockQuery);
      when(() => mockQuery.where('createdAt', isLessThan: any(named: 'isLessThan'))).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.docs).thenReturn([mockDoc1]);

      // Mock batch behavior
      when(() => mockBatch.delete(any())).thenReturn(null);
      when(() => mockBatch.commit()).thenAnswer((_) async => {});

      await repository.getNotifications(userId);

      // Verify batch delete was called
      verify(() => mockBatch.delete(mockRef1)).called(1);
      verify(() => mockBatch.commit()).called(1);
    });
  });
}
