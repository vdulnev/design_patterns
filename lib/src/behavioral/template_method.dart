// # Template Method Pattern
//
// Intent: Define the skeleton of an algorithm in an operation, deferring some
// steps to subclasses. Template Method lets subclasses redefine certain steps
// without changing the algorithm's structure.
//
// When to use:
// - You want to let clients extend only particular steps of an algorithm
// - Several classes contain the same algorithm with minor differences
// - You want to control at which points subclassing is allowed
// - Examples: Data miners/parsers, game AI turns, report generation,
//   HTTP request pipelines, unit test setUp/tearDown
//
// Key points in Dart:
// - The template method is defined (and usually final) in the abstract class
// - Abstract "hook" methods are overridden by subclasses
// - Optional hooks can have default (no-op) implementations

// ─────────────────────────────────────────────
// Abstract class with template method
// ─────────────────────────────────────────────

abstract class DataMiner {
  // Template method — defines the algorithm skeleton
  void mine(String source) {
    print('  [$runtimeType] Mining: $source');
    final raw  = extractData(source);
    final data = parseData(raw);
    final result = analyzeData(data);
    sendReport(result);
    if (shouldCleanup()) cleanup(source);
  }

  // Abstract steps — subclasses must implement
  String extractData(String source);
  List<String> parseData(String raw);
  Map<String, int> analyzeData(List<String> data);

  // Concrete step — common to all subclasses
  void sendReport(Map<String, int> result) {
    print('  Report: ${result.entries.map((e) => "${e.key}=${e.value}").join(", ")}');
  }

  // Optional hook — subclass may override
  bool shouldCleanup() => false;
  void cleanup(String source) {}
}

// ─────────────────────────────────────────────
// Concrete classes
// ─────────────────────────────────────────────

class CsvDataMiner extends DataMiner {
  @override
  String extractData(String source) {
    print('  Reading CSV file: $source');
    // Simulate CSV content
    return 'apple,banana,apple,cherry,banana,apple';
  }

  @override
  List<String> parseData(String raw) {
    print('  Parsing CSV rows...');
    return raw.split(',');
  }

  @override
  Map<String, int> analyzeData(List<String> data) {
    print('  Counting CSV items...');
    return data.fold({}, (map, item) {
      map[item] = (map[item] ?? 0) + 1;
      return map;
    });
  }

  @override
  bool shouldCleanup() => true;

  @override
  void cleanup(String source) => print('  Deleting temp CSV: $source.tmp');
}

class JsonDataMiner extends DataMiner {
  @override
  String extractData(String source) {
    print('  Fetching JSON from: $source');
    return '{"a":1,"b":2,"a":3,"c":1}'; // duplicate key for demo
  }

  @override
  List<String> parseData(String raw) {
    print('  Tokenizing JSON keys...');
    // Naive key extraction
    final regex = RegExp(r'"(\w+)"\s*:');
    return regex.allMatches(raw).map((m) => m.group(1)!).toList();
  }

  @override
  Map<String, int> analyzeData(List<String> data) {
    print('  Counting JSON key occurrences...');
    return data.fold({}, (map, key) {
      map[key] = (map[key] ?? 0) + 1;
      return map;
    });
  }
}

class DatabaseDataMiner extends DataMiner {
  @override
  String extractData(String source) {
    print('  Running query on: $source');
    return 'row1:active|row2:inactive|row3:active|row4:active';
  }

  @override
  List<String> parseData(String raw) {
    print('  Parsing DB rows...');
    return raw.split('|').map((r) => r.split(':').last).toList();
  }

  @override
  Map<String, int> analyzeData(List<String> data) {
    print('  Aggregating status counts...');
    return data.fold({}, (map, status) {
      map[status] = (map[status] ?? 0) + 1;
      return map;
    });
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void templateMethodExample() {
  print('═' * 50);
  print('TEMPLATE METHOD PATTERN');
  print('═' * 50);

  final miners = <DataMiner>[
    CsvDataMiner(),
    JsonDataMiner(),
    DatabaseDataMiner(),
  ];

  final sources = [
    'sales_2024.csv',
    'https://api.example.com/data.json',
    'orders_db.users',
  ];

  for (var i = 0; i < miners.length; i++) {
    print('');
    miners[i].mine(sources[i]);
  }

  print('');
}
