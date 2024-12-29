import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
String getTodayDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

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
      }
    }try {
     await _firestore
          .collection('study_sessions')
          .where('isActive', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .get();
    } catch (e) {
      if (e is FirebaseException && e.code == 'failed-precondition') {
        print(e);
      }
    }
    try {
      await _firestore
          .collection('study_sessions')
          .where('userId', isEqualTo: currentUserId)
          .where('isActive', isEqualTo: true)
          .get();
    } catch (e) {
      if (e is FirebaseException && e.code == 'failed-precondition') {
        print(e);
      }
    }
    try {
    // Add index for daily rankings
    await _firestore
        .collection('study_sessions')
        .where('date', isEqualTo:getTodayDate())
        .orderBy('totalMinutes', descending: true)
        .get();
  } catch (e) {
    if (e is FirebaseException && e.code == 'failed-precondition') {
      print(e);
    }
  }
  try {
    // Add index for active sessions with date
    await _firestore
        .collection('study_sessions')
        .where('date', isEqualTo: getTodayDate())
        .where('isActive', isEqualTo: true)
        .orderBy('startTime', descending: true)
        .get();
  } catch (e) {
    if (e is FirebaseException && e.code == 'failed-precondition') {
print(e);
    }
  }

    try {
      // Add index for time segments
      await _firestore
          .collection('study_sessions')
          .where('date', isEqualTo: getTodayDate())
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timeSegments', descending: true)
          .get();
    } catch (e) {
      if (e is FirebaseException && e.code == 'failed-precondition') {
        print(e);
      }
    }
  
  }
    Future<void> batchUpdate({
    required String path,
    required List<Map<String, dynamic>> updates,
  }) async {
    final batch = _firestore.batch();
    final reference = _firestore.doc(path);
    
    for (final update in updates) {
      batch.update(reference, update);
    }
    
    await batch.commit();
  }
    // Add this method to clean up old sessions
  Future<void> deleteOldSessions(String collection) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayDate = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
    
    final snapshot = await _firestore
        .collection(collection)
        .where('date', isEqualTo: yesterdayDate)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
  // Add this method to verify document ownership
  Future<bool> verifyDocumentOwnership(String path) async {
    if (currentUserId == null) return false;
    
    try {
      final doc = await getData(path: path);
      return doc['userId'] == currentUserId;
    } catch (e) {
      return false;
    }
  }
  
   Future<List<Map<String, dynamic>>> queryCollection(
    String path, {
    Query Function(Query query)? queryBuilder,
  }) async {
    Query query = _firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Include document ID
      return data;
    }).toList();
  }

 Future<Map<String, dynamic>> getData({required String path}) async {
    final reference = _firestore.doc(path);
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      throw Exception('Document does not exist');
    }
    final data = snapshot.data() as Map<String, dynamic>;
    data['id'] = snapshot.id; // Include document ID
    return data;
  }

  Future<Map<String, dynamic>?> getDocument(
    String collection, {
    required Map<String, dynamic> conditions,
  }) async {
    Query query = _firestore.collection(collection);
    
    conditions.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }


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
    rethrow;
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
