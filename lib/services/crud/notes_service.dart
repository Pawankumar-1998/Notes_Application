import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mynotes/extensions/list/filter.dart';
import 'package:mynotes/services/crud/crud_exception.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;  

// this class below is the notes service that is going to talk with the database
class NotesService {
  Database? _db;

  //  this below line of code is for catcing the notes so that the notes service has some notes in the memory ( catched ) so that every time
  //  the notes service need not to communicate with the database

  List<DatabaseNote> _notes = [];

  DatabaseUser? _user;

  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance() {
    _notesStreamController = StreamController<List<DatabaseNote>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes);
      },
    );
  }
  factory NotesService() => _shared;

  //  this is a stream controller that controls the list of the notes

  late final StreamController<List<DatabaseNote>> _notesStreamController;

  //  add all to the stream and get from it
  Stream<List<DatabaseNote>> get allNotes =>
      _notesStreamController.stream.filter((note) {
        final currentUser = _user;
        if (currentUser != null) {
          return note.userId == currentUser.id;
        } else {
          throw UserShouldBeSetBeforeReadingAllNote();
        }
      });

//  it gets the email of the firebase user as he is already in notes view which means he is already verified and autherized by the firebase this function either gets the user if he in sqlLite or creates the user in the sql lite database

  Future<DatabaseUser> getOrCreateUser({
    required String email,
    bool setAsCurrentUser = true,
  }) async {
    try {
      final user = await getUser(email: email);
      if (setAsCurrentUser) {
        _user = user;
      }
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      if (setAsCurrentUser) {
        _user = createdUser;
      }
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  //  this function is used to get the notes in the cached view
  Future<void> _cacheNote() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  //  Functionality of the Notes service
  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    await getNotes(id: note.id);
//  changed the noteTable here
    final updateCount = await db.update(
        noteTable,
        {
          textColumn: text,
          isSyncedWithCloudColumn: 0,
        },
        where: 'id=?',
        whereArgs: [note.id]);

    if (updateCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNotes(id: note.id);

      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);

      return updatedNote;
    }
  }

  Future<Iterable<DatabaseNote>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final notes = await db.query(noteTable);

    return notes.map((notesRow) => DatabaseNote.fromRow(notesRow));
  }

  Future<DatabaseNote> getNotes({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id=?',
      whereArgs: [id],
    );

    // if any notes doesnt exist
    if (notes.isEmpty) {
      throw CouldNotFindNotes();
    } else {
      final note = DatabaseNote.fromRow(notes.first);

      // remove the notes from our catched file because it may have not copied with the latest information
      _notes.removeWhere((note) => note.id == id);

      // add the latest note to the catched files
      _notes.add(note);
      _notesStreamController.add(_notes);

      return note;
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(noteTable);

    // setting the our local notes catched list as empty
    _notes = [];
    _notesStreamController.add(_notes);

    return numberOfDeletions;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deletedCount == 0) {
      throw CouldNotDeleteNotes();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // make sure the user is there in the database
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    }

    // this for the creating the notes
    const text = '';
    final noteId = await db.insert(noteTable, {
      userIDColumn: owner.id,
      textColumn: text,
      isSyncedWithCloudColumn: 1,
    });

    final note = DatabaseNote(
        id: noteId, userId: owner.id, text: text, isSyncedWithCloud: true);

    //  add the notes to the catched files and to the stream
    _notes.add(note);
    //  stream gonna track the catched files
    _notesStreamController.add(_notes);

    return note;
  }

//  this function is used to get the user from the sql lite database
  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final result = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (result.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(result.first);
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // first check if the user is there or not
    final result = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (result.isNotEmpty) {
      throw UserAlreadyExists();
    }

    // the insert function always return the int ( will be unique ) can be used as id of the database user
    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
    });

    return DatabaseUser(id: userId, email: email);
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final deletedCount = await db
        .delete(userTable, where: 'email=?', whereArgs: [email.toLowerCase()]);

    // exactly one column should be deleted as we store unique user
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      // empty
    }
  }

//  this function open the database
  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }

    try {
      // this is used ot get your application catche directory
      final docsPath = await getApplicationCacheDirectory();
      //  you will get the db path if we join the application catch directory path and our database path
      final dbPath = join(docsPath.path, dbName);
      // this we get the object of the database
      final db = await openDatabase(dbPath);
      _db = db;

      // create a user table if doesn't  exist
      await db.execute(createUserTable);

      // create a notes table if doesn't exist
      await db.execute(createNoteTable);
      //  as soon as the db is opened and the tables are created add all the notes to the cached file
      await _cacheNote();

      //  if for some reason the platform or the app doest have the directory it will throw thee exception
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentDirectory();
    }
  }
}

// class for the user in database
@immutable
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({
    required this.id,
    required this.email,
  });

//  this constructor is used to extract the data from the map ( Row ) and asign it to the class members
  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// class for the Notes in the database
class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIDColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, ID = $id , userId = $userId , isSyncedWithCloud = $isSyncedWithCloud , text = $text';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idColumn = 'id';
const emailColumn = 'email';
const userIDColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';
const createUserTable = '''CREATE TABLE IF NOT EXISTS "user" (
        "id"	INTEGER NOT NULL,
        "email"	TEXT NOT NULL UNIQUE,
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';
const createNoteTable = '''CREATE TABLE IF NOT EXISTS "note" (
        "id"	INTEGER NOT NULL,
        "user_id"	INTEGER NOT NULL,
        "text"	TEXT,
        "is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY("user_id") REFERENCES "user"("id"),
        PRIMARY KEY("id" AUTOINCREMENT)
      );''';
