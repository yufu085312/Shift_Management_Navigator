import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shift_management_navigator/repositories/store_repository.dart';
import 'package:shift_management_navigator/core/constants/app_constants.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late StoreRepository storeRepository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    storeRepository = StoreRepository(firestore: mockFirestore);

    when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocument);
  });

  group('StoreRepository Error Handling Tests', () {
    test('getStore returns null on Firestore error', () async {
      when(() => mockDocument.get()).thenThrow(FirebaseException(plugin: 'firestore', code: 'permission-denied'));

      final result = await storeRepository.getStore('store_001');

      expect(result, isNull);
    });

    test('getStoresByOwner returns empty list on Firestore error', () async {
      final mockQuery = MockQuery();
      when(() => mockCollection.where('ownerId', isEqualTo: any(named: 'isEqualTo'))).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenThrow(FirebaseException(plugin: 'firestore', code: 'unavailable'));

      final result = await storeRepository.getStoresByOwner('owner_001');

      expect(result, isEmpty);
    });
  });
}
