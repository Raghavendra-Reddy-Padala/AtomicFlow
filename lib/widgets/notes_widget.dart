import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/services/notes_services.dart';
import '../models/note_model.dart';

class NotesWidget extends ConsumerStatefulWidget {
  const NotesWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<NotesWidget> createState() => _NotesWidgetState();
}

class _NotesWidgetState extends ConsumerState<NotesWidget> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _showNoteDialog([NoteModel? note]) async {
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'New Note' : 'Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _titleController.clear();
              _contentController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (note == null) {
                // Create new note
                await ref.read(notesServiceProvider).createNote(
                      title: _titleController.text,
                      content: _contentController.text,
                    );
              } else {
                // Update existing note
                await ref.read(notesServiceProvider).updateNote(
                      noteId: note.id,
                      title: _titleController.text,
                      content: _contentController.text,
                    );
              }
              if (mounted) {
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
              }
            },
            child: Text(note == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              children: [
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showNoteDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Notes list section
            Expanded(
              child: StreamBuilder<List<NoteModel>>(
                stream: ref.read(notesServiceProvider).getUserNotes(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notes = snapshot.data ?? [];

                  if (notes.isEmpty) {
                    return const Center(
                      child: Text('No notes yet. Create one!'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      // Get note color based on creation time
                      final noteColor = _getNoteColor(note.createdAt);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: noteColor.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: noteColor.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Note header
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: noteColor.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(note.updatedAt),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Edit button
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showNoteDialog(note),
                                      tooltip: 'Edit Note',
                                    ),
                                    // Delete button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteNote(note.id),
                                      tooltip: 'Delete Note',
                                    ),
                                  ],
                                ),
                              ),
                              // Note content
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  note.content,
                                  style: const TextStyle(
                                  color: Colors.black,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Helper method to delete a note with confirmation
Future<void> _deleteNote(String noteId) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Note'),
      content: const Text('Are you sure you want to delete this note?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (shouldDelete ?? false) {
    await ref.read(notesServiceProvider).deleteNote(noteId);
  }
}

// Helper method to format the date
String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

// Helper method to get note color based on creation time
Color _getNoteColor(DateTime createdAt) {
  // Get hour of creation to determine color
  final hour = createdAt.hour;
  
  // Morning notes (6-12)
  if (hour >= 6 && hour < 12) {
    return Colors.blue;
  }
  // Afternoon notes (12-18)
  else if (hour >= 12 && hour < 18) {
    return Colors.green;
  }
  // Evening notes (18-24)
  else if (hour >= 18) {
    return Colors.purple;
  }
  // Night notes (0-6)
  else {
    return Colors.orange;
  }
}
}