import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dt_medrhythm/mypages/modifyroutes.dart';

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  FirebaseModifyStore,
])
void main() {}
