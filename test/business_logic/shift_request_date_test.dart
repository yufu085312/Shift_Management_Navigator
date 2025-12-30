import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shift_management_navigator/repositories/shift_request_repository.dart';
import 'package:shift_management_navigator/models/shift_request_model.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late ShiftRequestRepository shiftRequestRepository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    shiftRequestRepository = ShiftRequestRepository(firestore: mockFirestore);

    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
  });

  group('ShiftRequestRepository Date Filtering Tests', () {
    test('getRequestsByStoreAndDateRange filters requests in memory', () async {
      final mockQuery = MockQuery();
      final mockSnapshot = MockQuerySnapshot();
      
      final doc1 = MockQueryDocumentSnapshot();
      when(() => doc1.id).thenReturn('r1');
      when(() => doc1.data()).thenReturn({
        'storeId': 'store_001',
        'staffId': 's1',
        'type': 'wish',
        'date': '2025-01-01',
        'status': 'pending',
      });

      final doc2 = MockQueryDocumentSnapshot();
      when(() => doc2.id).thenReturn('r2');
      when(() => doc2.data()).thenReturn({
        'storeId': 'store_001',
        'staffId': 's1',
        'type': 'wish',
        'date': '2025-01-05',
        'status': 'pending',
      });

      final doc3 = MockQueryDocumentSnapshot();
      when(() => doc3.id).thenReturn('r3');
      when(() => doc3.data()).thenReturn({
        'storeId': 'store_001',
        'staffId': 's1',
        'type': 'wish',
        'date': '2025-01-10',
        'status': 'pending',
      });

      when(() => mockCollection.where('storeId', isEqualTo: any(named: 'isEqualTo'))).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.docs).thenReturn([doc1, doc2, doc3]);

      final result = await shiftRequestRepository.getRequestsByStoreAndDateRange(
        storeId: 'store_001',
        startDate: '2025-01-02',
        endDate: '2025-01-06',
      );

      expect(result.length, 1);
      expect(result.first.id, 'r2');
      expect(result.first.date, '2025-01-05');
    });
  });
}
