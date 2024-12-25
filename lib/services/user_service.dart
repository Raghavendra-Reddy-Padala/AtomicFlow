import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUserProfile({
    required String username,
    required String description,
    String? profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    await _firestore.collection('users').doc(user.uid).set({
      'username': username,
      'description': description,
      'profileImageUrl': profileImageUrl,
      'email': user.email,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateUserProfile({
    String? username,
    String? description,
    String? profileImageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (description != null) updates['description'] = description;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

    await _firestore.collection('users').doc(user.uid).update(updates);
  }

  Stream<UserModel?> getCurrentUserProfile() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    return _firestore.collection('users').doc(user.uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null,
        );
  }

  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null;
  }
}