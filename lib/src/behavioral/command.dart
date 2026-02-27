// # Command Pattern
//
// Intent: Encapsulate a request as an object, thereby letting you parameterize
// clients with different requests, queue or log requests, and support
// undoable operations.
//
// When to use:
// - Parameterize objects with operations
// - Queue, schedule, or execute requests at different times
// - Support undo/redo
// - Support logging and transactional behaviour
// - Examples: Text editor actions, UI button commands, macro recording,
//   job queues, database transactions
//
// Key points in Dart:
// - Command interface with execute() and (optionally) undo()
// - Invoker holds and triggers commands
// - Receiver contains the actual business logic

// ─────────────────────────────────────────────
// Command interface
// ─────────────────────────────────────────────

abstract class Command {
  void execute();
  void undo();
  String get description;
}

// ─────────────────────────────────────────────
// Receiver: the text document
// ─────────────────────────────────────────────

class TextDocument {
  final StringBuffer _buffer = StringBuffer();

  String get content => _buffer.toString();

  void insertAt(int position, String text) {
    final current = _buffer.toString();
    _buffer
      ..clear()
      ..write(current.substring(0, position))
      ..write(text)
      ..write(current.substring(position));
  }

  void deleteRange(int start, int end) {
    final current = _buffer.toString();
    _buffer
      ..clear()
      ..write(current.substring(0, start))
      ..write(current.substring(end));
  }

  void replaceAll(String from, String to) {
    final updated = _buffer.toString().replaceAll(from, to);
    _buffer
      ..clear()
      ..write(updated);
  }
}

// ─────────────────────────────────────────────
// Concrete commands
// ─────────────────────────────────────────────

class InsertTextCommand implements Command {
  final TextDocument _doc;
  final int _position;
  final String _text;

  InsertTextCommand(this._doc, this._position, this._text);

  @override
  String get description => 'Insert "$_text" at pos $_position';

  @override
  void execute() => _doc.insertAt(_position, _text);

  @override
  void undo() => _doc.deleteRange(_position, _position + _text.length);
}

class DeleteTextCommand implements Command {
  final TextDocument _doc;
  final int _start;
  final int _end;
  late String _deletedText; // saved for undo

  DeleteTextCommand(this._doc, this._start, this._end);

  @override
  String get description => 'Delete chars [$_start, $_end)';

  @override
  void execute() {
    _deletedText = _doc.content.substring(_start, _end);
    _doc.deleteRange(_start, _end);
  }

  @override
  void undo() => _doc.insertAt(_start, _deletedText);
}

class ReplaceCommand implements Command {
  final TextDocument _doc;
  final String _from;
  final String _to;
  late String _previousContent;

  ReplaceCommand(this._doc, this._from, this._to);

  @override
  String get description => 'Replace "$_from" → "$_to"';

  @override
  void execute() {
    _previousContent = _doc.content;
    _doc.replaceAll(_from, _to);
  }

  @override
  void undo() {
    _doc.deleteRange(0, _doc.content.length);
    _doc.insertAt(0, _previousContent);
  }
}

// ─────────────────────────────────────────────
// Invoker: editor with undo/redo history
// ─────────────────────────────────────────────

class TextEditor {
  final TextDocument document = TextDocument();
  final List<Command> _history = [];
  final List<Command> _redoStack = [];

  void execute(Command cmd) {
    cmd.execute();
    _history.add(cmd);
    _redoStack.clear(); // new command clears redo
    print('  ✓ ${cmd.description}');
    print('    Content: "${document.content}"');
  }

  void undo() {
    if (_history.isEmpty) {
      print('  Nothing to undo.');
      return;
    }
    final cmd = _history.removeLast();
    cmd.undo();
    _redoStack.add(cmd);
    print('  ↩ Undo: ${cmd.description}');
    print('    Content: "${document.content}"');
  }

  void redo() {
    if (_redoStack.isEmpty) {
      print('  Nothing to redo.');
      return;
    }
    final cmd = _redoStack.removeLast();
    cmd.execute();
    _history.add(cmd);
    print('  ↪ Redo: ${cmd.description}');
    print('    Content: "${document.content}"');
  }

  // Macro: batch commands executed as one unit
  void executeMacro(String name, List<Command> commands) {
    print('  [Macro: $name]');
    for (final cmd in commands) {
      execute(cmd);
    }
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void commandExample() {
  print('═' * 50);
  print('COMMAND PATTERN');
  print('═' * 50);

  final editor = TextEditor();

  print('\nExecuting commands:');
  editor.execute(InsertTextCommand(editor.document, 0, 'Hello World'));
  editor.execute(InsertTextCommand(editor.document, 5, ','));
  editor.execute(ReplaceCommand(editor.document, 'World', 'Dart'));

  print('\nUndo × 2:');
  editor.undo();
  editor.undo();

  print('\nRedo × 1:');
  editor.redo();

  print('\nDelete range:');
  editor.execute(DeleteTextCommand(editor.document, 0, 6));

  print('\nUndo delete:');
  editor.undo();

  print('');
}
