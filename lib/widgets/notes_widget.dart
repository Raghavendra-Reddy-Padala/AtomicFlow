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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            StreamBuilder<List<NoteModel>>(
              stream: ref.read(notesServiceProvider).getUserNotes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final notes = snapshot.data ?? [];

                if (notes.isEmpty) {
                  return const Center(
                    child: Text('No notes yet. Create one!'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      title: Text(note.title),
                      subtitle: Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showNoteDialog(note),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}