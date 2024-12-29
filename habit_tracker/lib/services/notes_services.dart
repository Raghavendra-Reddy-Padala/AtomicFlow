import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/services/databaseservice.dart';
import '../models/note_model.dart';

final notesServiceProvider = Provider<NotesService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return NotesService(firestoreService);
});

class NotesService {
  final FirestoreService _firestoreService;

  NotesService(this._firestoreService);

  Future<void> createNote({
    required String title,
    required String content,
  }) async {
    final userId = _firestoreService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    await _firestoreService.setData(
      path: 'notes/${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'userId': userId,
        'title': title,
        'content': content,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    );
  }

  Future<void> updateNote({
    required String noteId,
    String? title,
    String? content,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;

    await _firestoreService.updateData(
      path: 'notes/$noteId',
      data: updates,
    );
  }

  Future<void> deleteNote(String noteId) async {
    await _firestoreService.deleteData(path: 'notes/$noteId');
  }

Stream<List<NoteModel>> getUserNotes() {
  try {
    final userId = _firestoreService.currentUserId;
    
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _firestoreService.collectionStream(
      path: 'notes',
      builder: (data, id) {
        return NoteModel.fromMap(data, id);
      },
      queryBuilder: (query) => query
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true),
    ).handleError((error) {
      throw error;
    });
  } catch (e) {
    rethrow;
  }
}

  Stream<NoteModel?> getNote(String noteId) {
    return _firestoreService.documentStream(
      path: 'notes/$noteId',
      builder: (data, id) => NoteModel.fromMap(data, id),
    );
  }
}