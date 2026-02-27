// # Prototype Pattern
//
// Intent: Specify the kinds of objects to create using a prototypical instance,
// and create new objects by copying (cloning) this prototype.
//
// When to use:
// - Object creation is expensive (e.g., DB read, network call)
// - You need many similar objects that differ only slightly
// - The class to instantiate is specified at runtime
// - Examples: Game entities, document templates, UI component snapshots
//
// Key points in Dart:
// - Implement a `clone()` method (Dart has no built-in Cloneable)
// - Distinguish shallow copy vs deep copy
// - Useful with the `copyWith` convention common in Flutter

// ─────────────────────────────────────────────
// Prototype interface
// ─────────────────────────────────────────────

abstract class Prototype<T> {
  T clone();
}

// ─────────────────────────────────────────────
// Value object used inside the prototype
// ─────────────────────────────────────────────

class Position {
  final double x;
  final double y;
  const Position(this.x, this.y);

  Position copyWith({double? x, double? y}) =>
      Position(x ?? this.x, y ?? this.y);

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

// ─────────────────────────────────────────────
// Concrete prototype: Game enemy
// ─────────────────────────────────────────────

class Enemy implements Prototype<Enemy> {
  String name;
  int health;
  int damage;
  Position position;
  List<String> abilities;

  Enemy({
    required this.name,
    required this.health,
    required this.damage,
    required this.position,
    required this.abilities,
  });

  // Deep clone — abilities list is copied, not shared
  @override
  Enemy clone() => Enemy(
        name: name,
        health: health,
        damage: damage,
        position: position.copyWith(), // Position is immutable; this still works
        abilities: List.of(abilities), // deep copy of mutable list
      );

  // Flutter-style copyWith for targeted mutations after cloning
  Enemy copyWith({
    String? name,
    int? health,
    int? damage,
    Position? position,
    List<String>? abilities,
  }) =>
      Enemy(
        name:      name      ?? this.name,
        health:    health    ?? this.health,
        damage:    damage    ?? this.damage,
        position:  position  ?? this.position,
        abilities: abilities ?? List.of(this.abilities),
      );

  @override
  String toString() =>
      'Enemy($name | hp:$health dmg:$damage pos:$position abilities:$abilities)';
}

// ─────────────────────────────────────────────
// Prototype registry
// ─────────────────────────────────────────────

class EnemyRegistry {
  static final Map<String, Enemy> _prototypes = {};

  static void register(String key, Enemy prototype) {
    _prototypes[key] = prototype;
  }

  static Enemy spawn(String key, Position at) {
    final proto = _prototypes[key];
    if (proto == null) throw ArgumentError('No prototype for key: $key');
    return proto.clone()..position = at;
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void prototypeExample() {
  print('═' * 50);
  print('PROTOTYPE PATTERN');
  print('═' * 50);

  // Register base prototypes (expensive creation simulated here)
  EnemyRegistry.register(
    'goblin',
    Enemy(
      name: 'Goblin',
      health: 30,
      damage: 5,
      position: const Position(0, 0),
      abilities: ['scratch', 'dodge'],
    ),
  );

  EnemyRegistry.register(
    'orc',
    Enemy(
      name: 'Orc',
      health: 120,
      damage: 20,
      position: const Position(0, 0),
      abilities: ['slam', 'roar', 'block'],
    ),
  );

  // Spawn cheaply from prototypes
  final g1 = EnemyRegistry.spawn('goblin', const Position(10, 5));
  final g2 = EnemyRegistry.spawn('goblin', const Position(15, 8));
  final boss = EnemyRegistry.spawn('orc', const Position(50, 50))
      .copyWith(name: 'Orc Boss', health: 500, damage: 60);

  print('\nSpawned enemies:');
  print('  $g1');
  print('  $g2');
  print('  $boss');

  // Mutating a clone doesn't affect the original
  g1.abilities.add('fire_breath');
  final g3 = EnemyRegistry.spawn('goblin', const Position(20, 0));
  print('\ng1 abilities (mutated): ${g1.abilities}');
  print('g3 abilities (fresh):   ${g3.abilities}');

  print('');
}

void main() => prototypeExample();
