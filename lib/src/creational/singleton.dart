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

  print('');
}
