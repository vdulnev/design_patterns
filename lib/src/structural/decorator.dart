// # Decorator Pattern
//
// Intent: Attach additional responsibilities to an object dynamically.
// Decorators provide a flexible alternative to subclassing for extending
// functionality.
//
// When to use:
// - Add behaviour to individual objects without affecting others
// - Extension by subclassing is impractical (too many combinations)
// - Responsibilities should be added and removed at runtime
// - Examples: I/O streams, middleware pipelines, logging wrappers,
//   Flutter widget decoration
//
// Key points in Dart:
// - Decorator implements the same interface as the component
// - Wraps the component and forwards calls, adding behaviour before/after
// - Can be stacked: Decorator(Decorator(Decorator(Component)))

// ─────────────────────────────────────────────
// Component interface
// ─────────────────────────────────────────────

abstract class DataSource {
  void write(String data);
  String read();
}

// ─────────────────────────────────────────────
// Concrete component
// ─────────────────────────────────────────────

class FileDataSource implements DataSource {
  final String filename;
  String _data = '';

  FileDataSource(this.filename);

  @override
  void write(String data) {
    _data = data;
    print('  [File] Writing ${data.length} bytes to $filename');
  }

  @override
  String read() {
    print('  [File] Reading from $filename');
    return _data;
  }
}

// ─────────────────────────────────────────────
// Base decorator
// ─────────────────────────────────────────────

abstract class DataSourceDecorator implements DataSource {
  final DataSource _wrappee;
  const DataSourceDecorator(this._wrappee);

  @override
  void write(String data) => _wrappee.write(data);

  @override
  String read() => _wrappee.read();
}

// ─────────────────────────────────────────────
// Concrete decorators
// ─────────────────────────────────────────────

class EncryptionDecorator extends DataSourceDecorator {
  const EncryptionDecorator(super.wrappee);

  String _encrypt(String data) {
    // Simple Caesar cipher for illustration
    return data.codeUnits.map((c) => c + 3).map(String.fromCharCode).join();
  }

  String _decrypt(String data) {
    return data.codeUnits.map((c) => c - 3).map(String.fromCharCode).join();
  }

  @override
  void write(String data) {
    print('  [Encrypt] Encrypting data...');
    super.write(_encrypt(data));
  }

  @override
  String read() {
    print('  [Encrypt] Decrypting data...');
    return _decrypt(super.read());
  }
}

class CompressionDecorator extends DataSourceDecorator {
  const CompressionDecorator(super.wrappee);

  String _compress(String data) => 'COMPRESSED(${data.length}):$data';

  String _decompress(String data) {
    final colonIdx = data.indexOf(':');
    return data.substring(colonIdx + 1);
  }

  @override
  void write(String data) {
    print('  [Compress] Compressing data...');
    super.write(_compress(data));
  }

  @override
  String read() {
    print('  [Compress] Decompressing data...');
    return _decompress(super.read());
  }
}

class LoggingDecorator extends DataSourceDecorator {
  const LoggingDecorator(super.wrappee);

  @override
  void write(String data) {
    print('  [Log] WRITE called at ${DateTime.now().toIso8601String()}');
    super.write(data);
  }

  @override
  String read() {
    print('  [Log] READ  called at ${DateTime.now().toIso8601String()}');
    return super.read();
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void decoratorExample() {
  print('═' * 50);
  print('DECORATOR PATTERN');
  print('═' * 50);

  const message = 'Hello, Design Patterns!';

  // Plain file
  print('\n[Plain file]');
  final plain = FileDataSource('plain.txt');
  plain.write(message);
  print('  Read back: "${plain.read()}"');

  // File + encryption
  print('\n[File + Encryption]');
  final encrypted = EncryptionDecorator(FileDataSource('secret.txt'));
  encrypted.write(message);
  print('  Read back: "${encrypted.read()}"');

  // File + compression + encryption + logging (stacked decorators)
  print('\n[File + Compression + Encryption + Logging]');
  final full = LoggingDecorator(
    EncryptionDecorator(
      CompressionDecorator(
        FileDataSource('data.bin'),
      ),
    ),
  );
  full.write(message);
  final result = full.read();
  print('  Final value: "$result"');

  print('');
}

void main() => decoratorExample();
