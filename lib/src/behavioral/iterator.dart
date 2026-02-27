// # Iterator Pattern
//
// Intent: Provide a way to access the elements of an aggregate object
// sequentially without exposing its underlying representation.
//
// When to use:
// - Access contents of a collection without exposing internal structure
// - Traverse multiple types of collections with a uniform interface
// - Provide several traversal strategies for the same collection
// - Examples: tree traversals, paginated API results, playlist navigation
//
// Key points in Dart:
// - Dart already has built-in Iterator<E> and Iterable<E> interfaces
// - Implement Iterable to get for-in loop support and all extension methods
// - Custom iterators shine for non-linear structures (trees, graphs)

// ─────────────────────────────────────────────
// Example 1: Custom iterator over a binary tree
// ─────────────────────────────────────────────

class TreeNode<T> {
  final T value;
  TreeNode<T>? left;
  TreeNode<T>? right;
  TreeNode(this.value, {this.left, this.right});
}

// In-order iterator (left → root → right)
class InOrderIterator<T> implements Iterator<T> {
  final List<TreeNode<T>> _stack = [];
  TreeNode<T>? _current;
  T? _currentValue;

  InOrderIterator(TreeNode<T>? root) {
    _pushLeft(root);
  }

  void _pushLeft(TreeNode<T>? node) {
    while (node != null) {
      _stack.add(node);
      node = node.left;
    }
  }

  @override
  T get current => _currentValue as T;

  @override
  bool moveNext() {
    if (_stack.isEmpty) return false;
    _current = _stack.removeLast();
    _currentValue = _current!.value;
    _pushLeft(_current!.right);
    return true;
  }
}

class BinaryTree<T> extends Iterable<T> {
  final TreeNode<T>? root;
  const BinaryTree(this.root);

  @override
  Iterator<T> get iterator => InOrderIterator(root);
}

// ─────────────────────────────────────────────
// Example 2: Paginated collection iterator
// ─────────────────────────────────────────────

class Page<T> {
  final List<T> items;
  final int pageNumber;
  final bool hasNext;
  const Page(this.items, this.pageNumber, {required this.hasNext});
}

// Simulated data source
class UserDataSource {
  static const _allUsers = [
    'Alice', 'Bob', 'Carol', 'Dave', 'Eve',
    'Frank', 'Grace', 'Hank', 'Iris', 'Jack',
  ];

  Page<String> fetchPage(int page, {int size = 3}) {
    final start = page * size;
    final end   = (start + size).clamp(0, _allUsers.length);
    final items = _allUsers.sublist(start, end);
    return Page(items, page, hasNext: end < _allUsers.length);
  }
}

class PaginatedIterator implements Iterator<String> {
  final UserDataSource _repo;
  final int _pageSize;
  List<String> _buffer = [];
  int _pageIndex = 0;
  int _bufferIndex = -1;
  bool _done = false;

  PaginatedIterator(this._repo, {int pageSize = 3}) : _pageSize = pageSize;

  @override
  String get current => _buffer[_bufferIndex];

  @override
  bool moveNext() {
    if (_done) return false;
    _bufferIndex++;
    if (_bufferIndex < _buffer.length) return true;

    // Fetch next page
    final page = _repo.fetchPage(_pageIndex++, size: _pageSize);
    _buffer = page.items;
    _bufferIndex = 0;
    if (_buffer.isEmpty) { _done = true; return false; }
    if (!page.hasNext) _done = true;
    return _buffer.isNotEmpty;
  }
}

class PaginatedUsers extends Iterable<String> {
  final UserDataSource _repo;
  const PaginatedUsers(this._repo);

  @override
  Iterator<String> get iterator => PaginatedIterator(_repo);
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void iteratorExample() {
  print('═' * 50);
  print('ITERATOR PATTERN');
  print('═' * 50);

  // Binary tree:
  //       4
  //      / \
  //     2   6
  //    / \ / \
  //   1  3 5  7
  final tree = BinaryTree(
    TreeNode(4,
      left: TreeNode(2,
        left:  TreeNode(1),
        right: TreeNode(3),
      ),
      right: TreeNode(6,
        left:  TreeNode(5),
        right: TreeNode(7),
      ),
    ),
  );

  print('\n[In-order tree traversal]');
  print('  Values: ${tree.toList()}'); // [1, 2, 3, 4, 5, 6, 7]

  // Built-in Iterable methods work automatically
  print('  Sum:    ${tree.fold(0, (a, b) => a + b)}');
  print('  Even:   ${tree.where((v) => v % 2 == 0).toList()}');

  // Paginated iterator
  print('\n[Paginated API iterator — 3 per page]');
  final users = PaginatedUsers(UserDataSource());
  var i = 1;
  for (final user in users) {
    print('  $i. $user');
    i++;
  }

  print('');
}

void main() => iteratorExample();
