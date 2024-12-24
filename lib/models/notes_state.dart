import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class NotesState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotes() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .get();

      _notes = querySnapshot.docs
          .map((doc) => Note.fromFirestore(doc))
          .toList();

    } catch (e) {
      _error = 'Failed to load notes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNote(String title, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final newNote = Note(
        id: DateTime.now().toString(),
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      );

      // Optimistic update
      _notes.insert(0, newNote);
      notifyListeners();

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .add(newNote.toFirestore());

      // Update with real ID
      _notes[0] = Note(
        id: docRef.id,
        title: newNote.title,
        content: newNote.content,
        createdAt: newNote.createdAt,
        updatedAt: newNote.updatedAt,
      );

    } catch (e) {
      _error = 'Failed to add note: $e';
      _notes.removeAt(0); // Rollback optimistic update
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateNote(String id, String title, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final index = _notes.indexWhere((note) => note.id == id);
      if (index == -1) return;

      final updatedNote = Note(
        id: id,
        title: title,
        content: content,
        createdAt: _notes[index].createdAt,
        updatedAt: DateTime.now(),
      );

      // Optimistic update
      _notes[index] = updatedNote;
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .update(updatedNote.toFirestore());

    } catch (e) {
      _error = 'Failed to update note: $e';
      await loadNotes(); // Rollback by reloading
    }
  }

Future<void> deleteNote(String id) async {
  final user = _auth.currentUser;
  if (user == null) return;

  Note? deletedNote; // Declare outside try block
  int? index; // Declare outside try block

  try {
    index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) return;

    // Optimistic update
    deletedNote = _notes.removeAt(index);
    notifyListeners();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(id)
        .delete();

  } catch (e) {
    _error = 'Failed to delete note: $e';
    if (deletedNote != null && index != null) {
      _notes.insert(index, deletedNote);
      notifyListeners();
    }
  }
}
}