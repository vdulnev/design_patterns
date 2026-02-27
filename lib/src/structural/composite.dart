// # Composite Pattern
//
// Intent: Compose objects into tree structures to represent part-whole
// hierarchies. Composite lets clients treat individual objects and compositions
// of objects uniformly.
//
// When to use:
// - You want to represent part-whole hierarchies of objects
// - Clients should ignore the difference between single objects and compositions
// - Examples: File system (files & folders), UI widget trees, org charts,
//   arithmetic expression trees, HTML/XML DOM
//
// Key points in Dart:
// - Component: common interface for leaves and composites
// - Leaf: has no children, does the actual work
// - Composite: contains children (Leaf or Composite), delegates to them

// ─────────────────────────────────────────────
// Component interface
// ─────────────────────────────────────────────

abstract class FileSystemItem {
  String get name;
  int get sizeBytes;
  void display({int indent = 0});
}

// ─────────────────────────────────────────────
// Leaf
// ─────────────────────────────────────────────

class File implements FileSystemItem {
  @override
  final String name;
  @override
  final int sizeBytes;

  const File(this.name, this.sizeBytes);

  @override
  void display({int indent = 0}) {
    final pad = ' ' * (indent * 2);
    print('$pad📄 $name (${_humanSize(sizeBytes)})');
  }

  static String _humanSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1048576).toStringAsFixed(1)}MB';
  }
}

// ─────────────────────────────────────────────
// Composite
// ─────────────────────────────────────────────

class Directory implements FileSystemItem {
  @override
  final String name;
  final List<FileSystemItem> _children = [];

  Directory(this.name);

  void add(FileSystemItem item) => _children.add(item);
  void remove(FileSystemItem item) => _children.remove(item);

  @override
  int get sizeBytes => _children.fold(0, (sum, c) => sum + c.sizeBytes);

  @override
  void display({int indent = 0}) {
    final pad = ' ' * (indent * 2);
    print('$pad📁 $name/ (${_children.length} items, ${File._humanSize(sizeBytes)})');
    for (final child in _children) {
      child.display(indent: indent + 1);
    }
  }
}

// ─────────────────────────────────────────────
// Example 2: Expression tree (arithmetic)
// ─────────────────────────────────────────────

abstract class Expression {
  int evaluate();
  String toInfix();
}

class NumberExpr implements Expression {
  final int value;
  const NumberExpr(this.value);

  @override
  int evaluate() => value;

  @override
  String toInfix() => '$value';
}

class BinaryExpr implements Expression {
  final Expression left;
  final Expression right;
  final String op;

  const BinaryExpr(this.left, this.op, this.right);

  @override
  int evaluate() => switch (op) {
        '+' => left.evaluate() + right.evaluate(),
        '-' => left.evaluate() - right.evaluate(),
        '*' => left.evaluate() * right.evaluate(),
        '/' => left.evaluate() ~/ right.evaluate(),
        _ => throw ArgumentError('Unknown operator: $op'),
      };

  @override
  String toInfix() => '(${left.toInfix()} $op ${right.toInfix()})';
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void compositeExample() {
  print('═' * 50);
  print('COMPOSITE PATTERN');
  print('═' * 50);

  // Build a file system tree
  final root = Directory('project');

  final src = Directory('src')
    ..add(const File('main.dart', 3200))
    ..add(const File('app.dart', 8700));

  final lib = Directory('lib')
    ..add(const File('models.dart', 12500))
    ..add(const File('utils.dart', 4100));

  final test = Directory('test')
    ..add(const File('main_test.dart', 2300))
    ..add(const File('models_test.dart', 5600));

  src.add(lib);
  root
    ..add(src)
    ..add(test)
    ..add(const File('pubspec.yaml', 830))
    ..add(const File('README.md', 1200));

  print('\n[File System Tree]');
  root.display();
  print('  Total size: ${File._humanSize(root.sizeBytes)}');

  // Expression tree: (3 + 4) * (10 - 2)
  print('\n[Expression Tree]');
  final expr = BinaryExpr(
    BinaryExpr(const NumberExpr(3), '+', const NumberExpr(4)),
    '*',
    BinaryExpr(const NumberExpr(10), '-', const NumberExpr(2)),
  );
  print('  Expression: ${expr.toInfix()}');
  print('  Result:     ${expr.evaluate()}'); // 56

  print('');
}
