import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> createRequiredIndexes() async {
    try {
      // Try to fetch with required indexes
      await _firestore
          .collection('habits')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();
    } catch (e) {
      if (e is FirebaseException && e.code == 'failed-precondition') {
      }
    }

    try {
      await _firestore
          .collection('notes')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('updatedAt', descending: true)
          .get();
    } catch (e) {
      if (e is FirebaseException && e.code == 'failed-precondition') {
      }
    }
     try {
      // New index for pomodoro sessions
      await _firestore
          .collection('pomodoro_sessions')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('startTime', descending: true)
          .get();
    } catch (e) {
      if (e is FirebaseException && e.code == 'failed-precondition') {
        print('Need to create index for pomodoro_sessions collection');
        print(e);
        // You'll need to create this index in Firebase Console
        throw Exception('''
Please create the following index in Firebase Console:

Collection: pomodoro_sessions
Fields to index:
- userId (Ascending)
- startTime (Descending)
        ''');
      }
    }
  }
  

  // Generic document stream
  Stream<T?> documentStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String id) builder,
  }) {
    final reference = _firestore.doc(path);
    final snapshots = reference.snapshots();
    return snapshots.map((snapshot) {
      if (!snapshot.exists) return null;
      return builder(snapshot.data()!, snapshot.id);
    });
  }

  // Generic collection stream
  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String id) builder,
    Query Function(Query query)? queryBuilder,
    int Function(T lhs, T rhs)? sort,
  }) {
    try{
    Query query = _firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshots = query.snapshots();
    return snapshots.map((snapshot) {
      final result = snapshot.docs
          .map((doc) => builder(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      if (sort != null) {
        result.sort(sort);
      }
      return result;
    }).handleError( (error) {
      throw error;
    });
  
  }catch(e){
    throw e;
  }
  }

  // Generic set document
  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final reference = _firestore.doc(path);
    await reference.set(data, SetOptions(merge: merge));
  }

  // Generic update document
  Future<void> updateData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final reference = _firestore.doc(path);
    await reference.update(data);
  }

  // Generic delete document
  Future<void> deleteData({required String path}) async {
    final reference = _firestore.doc(path);
    await reference.delete();
  }
}
