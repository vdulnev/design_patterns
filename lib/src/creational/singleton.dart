// # Singleton Pattern
//
// Intent: Ensure a class has only one instance and provide a global
// access point to it.
//
// When to use:
// - Exactly one object is needed to coordinate actions across the system
// - You need strict control over global variables
// - Examples: Logger, Config, Cache, Connection Pool
//
// Key points in Dart:
// - Use a static field to hold the single instance
// - Make the constructor private with a named constructor
// - Provide a static accessor (`instance`)

// ─────────────────────────────────────────────
// Implementation 1: Classic lazy singleton
// ─────────────────────────────────────────────

class Logger {
  static Logger? _instance;

  // Private constructor prevents direct instantiation
  Logger._internal();

  static Logger get instance {
    _instance ??= Logger._internal();
    return _instance!;
  }

  final List<String> _logs = [];

  void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] $message';
    _logs.add(entry);
    print(entry);
  }

  List<String> get history => List.unmodifiable(_logs);

  void clear() => _logs.clear();
}

// ─────────────────────────────────────────────
// Implementation 2: Singleton via factory constructor
// (more idiomatic Dart)
// ─────────────────────────────────────────────

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();

  // Factory constructor always returns the same instance
  factory AppConfig() => _instance;

  AppConfig._internal() {
    // Simulate loading config from environment / file
    _settings = {
      'theme': 'dark',
      'language': 'en',
      'debug': 'false',
    };
  }

  late Map<String, String> _settings;

  String get(String key) => _settings[key] ?? '';

  void set(String key, String value) => _settings[key] = value;

  @override
  String toString() => 'AppConfig($_settings)';
}

// ─────────────────────────────────────────────
// Implementation 3: Generic singleton registry
//
// Wraps any ordinary class — the class itself needs no
// singleton boilerplate. The registry stores one instance
// per type in a static map and calls the factory only once.
// ─────────────────────────────────────────────

class Singleton {
  static final Map<Type, dynamic> _instances = {};

  /// Returns the single instance of [T], creating it on the first call
  /// via [factory] and ignoring [factory] on every subsequent call.
  static T of<T>(T Function() factory) {
    return (_instances[T] ??= factory()) as T;
  }

  /// Remove the stored instance of [T] (useful in tests).
  static void reset<T>() => _instances.remove(T);
}

// Ordinary classes — zero singleton knowledge required:

class DatabaseConnection {
  final String host;
  final int port;

  DatabaseConnection({required this.host, this.port = 5432}) {
    print('  [DB] Opening connection to $host:$port');
  }

  void query(String sql) => print('  [DB] Query: $sql');

  @override
  String toString() => 'DatabaseConnection($host:$port)';
}

class EventBus {
  final _listeners = <String, List<void Function(dynamic)>>{};

  void on(String event, void Function(dynamic) cb) =>
      (_listeners[event] ??= []).add(cb);

  void emit(String event, [dynamic data]) =>
      _listeners[event]?.forEach((cb) => cb(data));

  @override
  String toString() => 'EventBus(${_listeners.keys.join(', ')})';
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void singletonExample() {
  print('═' * 50);
  print('SINGLETON PATTERN');
  print('═' * 50);

  // Logger: same instance every time
  final log1 = Logger.instance;
  final log2 = Logger.instance;
  print('Same Logger instance? ${identical(log1, log2)}'); // true

  log1.log('Application started');
  log2.log('User logged in');

  print('Total log entries: ${log1.history.length}'); // 2 — shared state

  // AppConfig via factory constructor
  final config1 = AppConfig();
  final config2 = AppConfig();
  print('\nSame AppConfig instance? ${identical(config1, config2)}'); // true

  config1.set('theme', 'light');
  print('Theme from config2: ${config2.get('theme')}'); // light — same object

  // Generic registry — ordinary classes, no boilerplate
  print('\n[Generic Singleton registry]');

  // First call: factory runs, connection is opened
  final db1 = Singleton.of<DatabaseConnection>(
    () => DatabaseConnection(host: 'localhost'),
  );
  // Second call: factory is ignored, same instance returned
  final db2 = Singleton.of<DatabaseConnection>(
    () => DatabaseConnection(host: 'should-never-be-used'),
  );
  print('Same DB instance? ${identical(db1, db2)}');   // true
  print('Host on db2: ${db2.host}');                   // localhost

  db1.query('SELECT * FROM users');

  // Different type → independent instance
  final bus1 = Singleton.of<EventBus>(() => EventBus());
  final bus2 = Singleton.of<EventBus>(() => EventBus());
  print('Same EventBus? ${identical(bus1, bus2)}');    // true

  bus1.on('login', (user) => print('  [bus] login: $user'));
  bus2.emit('login', 'alice'); // fires because bus1 == bus2

  print('');
}
