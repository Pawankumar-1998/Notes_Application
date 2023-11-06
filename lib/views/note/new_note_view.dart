import 'package:flutter/material.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/crud/notes_service.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  DatabaseNote? _note;
  late final NotesService _notesService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _notesService = NotesService();
    _textController = TextEditingController();
    super.initState();
  }

  // this function is responsible for the creation of new note
  Future<DatabaseNote> createNewNote() async {
    final existingNote = _note;

    if (existingNote != null) {
      return existingNote;
    }

    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner = await _notesService.getUser(email: email);

    return await _notesService.createNote(owner: owner);
  }

  //  this function is used to delete the notes if the user just existed the screen without typing anything in the text
  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      _notesService.deleteNote(id: note.id);
    }
  }

  // this below function is used to save the notes entered by the user
  void _saveNoteIfTextIsNotEmpty() async {
    final note = _note;
    final text = _textController.text;

    if (text.isNotEmpty && note != null) {
      await _notesService.updateNote(note: note, text: text);
    }
  }

  // this function is for continously listning to the text editing controller becuase even if the user type a single text we are gonna update the note
  void _textControllerListener() async {
    final note = _note;
    final text = _textController.text;

    if (note == null) {
      return;
    }

    await _notesService.updateNote(note: note, text: text);
  }

  //  this function is used for removing the textControllerListener and agoin adding it
  void _setUpTextControllerListener() {
    _textController.removeListener((_textControllerListener));
    _textController.addListener((_textControllerListener));
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextIsNotEmpty();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("New Note"),
        ),
        body: FutureBuilder(
          future: createNewNote(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                _note = snapshot.data as DatabaseNote;
                _setUpTextControllerListener();
                return TextField(
                  controller: _textController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                      hintText: "Start typing your note here ..."),
                );
              default:
                return const CircularProgressIndicator();
            }
          },
        ));
  }
}
