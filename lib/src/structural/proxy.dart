// # Proxy Pattern
//
// Intent: Provide a surrogate or placeholder for another object to control
// access to it.
//
// Common proxy types:
//   - Virtual proxy:  lazy initialisation (defer expensive creation)
//   - Protection proxy: access control
//   - Caching proxy: cache results of expensive operations
//   - Logging proxy: record requests transparently
//
// When to use:
// - Lazy initialization of a heavyweight object
// - Access control (protection proxy)
// - Local execution of a remote service (remote proxy)
// - Logging / caching without changing the real subject
//
// Key points in Dart:
// - Proxy and RealSubject share the same interface
// - Client code is unaware it's talking to a proxy

// ─────────────────────────────────────────────
// Subject interface
// ─────────────────────────────────────────────

abstract class ImageLoader {
  String get name;
  void display();
}

// ─────────────────────────────────────────────
// Real subject (expensive to create)
// ─────────────────────────────────────────────

class RealImage implements ImageLoader {
  @override
  final String name;

  late final String _pixels; // simulate loaded data

  RealImage(this.name) {
    _load();
  }

  void _load() {
    // Simulate slow disk/network I/O
    print('  [RealImage] Loading "$name" from disk... (expensive!)');
    _pixels = '<pixel data for $name>';
  }

  @override
  void display() => print('  [RealImage] Displaying "$name": $_pixels');
}

// ─────────────────────────────────────────────
// 1. Virtual / Lazy proxy
// ─────────────────────────────────────────────

class LazyImageProxy implements ImageLoader {
  @override
  final String name;

  RealImage? _real; // created only on first display

  LazyImageProxy(this.name);

  @override
  void display() {
    _real ??= RealImage(name); // deferred creation
    _real!.display();
  }
}

// ─────────────────────────────────────────────
// 2. Caching proxy (database query example)
// ─────────────────────────────────────────────

abstract class UserRepository {
  Map<String, dynamic>? findById(int id);
}

class DatabaseUserRepository implements UserRepository {
  @override
  Map<String, dynamic>? findById(int id) {
    print('  [DB] Executing SELECT * FROM users WHERE id=$id');
    // Simulate result
    return {'id': id, 'name': 'Alice', 'email': 'alice@example.com'};
  }
}

class CachingUserRepositoryProxy implements UserRepository {
  final UserRepository _real;
  final Map<int, Map<String, dynamic>> _cache = {};

  CachingUserRepositoryProxy(this._real);

  @override
  Map<String, dynamic>? findById(int id) {
    if (_cache.containsKey(id)) {
      print('  [Cache] HIT for id=$id');
      return _cache[id];
    }
    print('  [Cache] MISS for id=$id — delegating to DB');
    final result = _real.findById(id);
    if (result != null) _cache[id] = result;
    return result;
  }
}

// ─────────────────────────────────────────────
// 3. Protection proxy
// ─────────────────────────────────────────────

abstract class AdminPanel {
  void deleteUser(int id);
  void viewLogs();
}

class RealAdminPanel implements AdminPanel {
  @override
  void deleteUser(int id) => print('  [Admin] User $id deleted.');
  @override
  void viewLogs() => print('  [Admin] Showing system logs...');
}

class ProtectionProxy implements AdminPanel {
  final AdminPanel _real;
  final String _role;

  ProtectionProxy(this._real, this._role);

  @override
  void deleteUser(int id) {
    if (_role != 'admin') {
      print('  [Access Denied] Only admins can delete users.');
      return;
    }
    _real.deleteUser(id);
  }

  @override
  void viewLogs() {
    if (_role == 'guest') {
      print('  [Access Denied] Guests cannot view logs.');
      return;
    }
    _real.viewLogs();
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void proxyExample() {
  print('═' * 50);
  print('PROXY PATTERN');
  print('═' * 50);

  // Virtual proxy — image not loaded until display()
  print('\n[1. Lazy/Virtual Proxy]');
  final img = LazyImageProxy('photo.jpg');
  print('  Proxy created — image NOT loaded yet');
  img.display(); // loads now
  img.display(); // reuses loaded image

  // Caching proxy
  print('\n[2. Caching Proxy]');
  final repo = CachingUserRepositoryProxy(DatabaseUserRepository());
  repo.findById(1); // miss → DB hit
  repo.findById(2); // miss → DB hit
  repo.findById(1); // cache hit
  repo.findById(2); // cache hit

  // Protection proxy
  print('\n[3. Protection Proxy]');
  final panel = RealAdminPanel();

  final guestPanel = ProtectionProxy(panel, 'guest');
  print('  Guest tries:');
  guestPanel.viewLogs();
  guestPanel.deleteUser(42);

  final adminPanel = ProtectionProxy(panel, 'admin');
  print('  Admin tries:');
  adminPanel.viewLogs();
  adminPanel.deleteUser(42);

  print('');
}

void main() => proxyExample();
