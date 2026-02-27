// # Strategy Pattern
//
// Intent: Define a family of algorithms, encapsulate each one, and make them
// interchangeable. Strategy lets the algorithm vary independently from clients
// that use it.
//
// When to use:
// - Many related classes differ only in their behaviour
// - You need different variants of an algorithm
// - An algorithm uses data clients shouldn't know about
// - Examples: Sorting, compression, payment methods, routing algorithms,
//   validation rules, discount strategies
//
// Key points in Dart:
// - Strategy = an interface (abstract class or typedef)
// - Context holds a reference to the strategy and calls it
// - Dart functions-as-first-class-citizens allow a lightweight
//   function-based variant without a full interface

// ─────────────────────────────────────────────
// Strategy interface
// ─────────────────────────────────────────────

abstract class SortStrategy<T extends Comparable<dynamic>> {
  void sort(List<T> data);
  String get name;
}

// ─────────────────────────────────────────────
// Concrete strategies
// ─────────────────────────────────────────────

class BubbleSort<T extends Comparable<dynamic>> implements SortStrategy<T> {
  @override
  String get name => 'Bubble Sort';

  @override
  void sort(List<T> data) {
    final n = data.length;
    for (var i = 0; i < n - 1; i++) {
      for (var j = 0; j < n - i - 1; j++) {
        if (data[j].compareTo(data[j + 1]) > 0) {
          final tmp = data[j];
          data[j] = data[j + 1];
          data[j + 1] = tmp;
        }
      }
    }
  }
}

class QuickSort<T extends Comparable<dynamic>> implements SortStrategy<T> {
  @override
  String get name => 'Quick Sort';

  @override
  void sort(List<T> data) => _quickSort(data, 0, data.length - 1);

  void _quickSort(List<T> data, int low, int high) {
    if (low < high) {
      final pivot = _partition(data, low, high);
      _quickSort(data, low, pivot - 1);
      _quickSort(data, pivot + 1, high);
    }
  }

  int _partition(List<T> data, int low, int high) {
    final pivot = data[high];
    var i = low - 1;
    for (var j = low; j < high; j++) {
      if (data[j].compareTo(pivot) <= 0) {
        i++;
        final tmp = data[i];
        data[i] = data[j];
        data[j] = tmp;
      }
    }
    final tmp = data[i + 1];
    data[i + 1] = data[high];
    data[high] = tmp;
    return i + 1;
  }
}

class MergeSort<T extends Comparable<dynamic>> implements SortStrategy<T> {
  @override
  String get name => 'Merge Sort';

  @override
  void sort(List<T> data) {
    if (data.length <= 1) return;
    final sorted = _mergeSort(data);
    for (var i = 0; i < sorted.length; i++) {
      data[i] = sorted[i];
    }
  }

  List<T> _mergeSort(List<T> data) {
    if (data.length <= 1) return data;
    final mid = data.length ~/ 2;
    final left  = _mergeSort(data.sublist(0, mid));
    final right = _mergeSort(data.sublist(mid));
    return _merge(left, right);
  }

  List<T> _merge(List<T> left, List<T> right) {
    final result = <T>[];
    int i = 0, j = 0;
    while (i < left.length && j < right.length) {
      if (left[i].compareTo(right[j]) <= 0) {
        result.add(left[i++]);
      } else {
        result.add(right[j++]);
      }
    }
    result.addAll(left.sublist(i));
    result.addAll(right.sublist(j));
    return result;
  }
}

// ─────────────────────────────────────────────
// Context
// ─────────────────────────────────────────────

class Sorter<T extends Comparable<dynamic>> {
  SortStrategy<T> _strategy;

  Sorter(this._strategy);

  // Strategy can be swapped at runtime
  set strategy(SortStrategy<T> s) => _strategy = s;

  List<T> sort(List<T> data) {
    final copy = List<T>.of(data);
    _strategy.sort(copy);
    print('  ${_strategy.name}: $copy');
    return copy;
  }
}

// ─────────────────────────────────────────────
// Bonus: Function-based strategy (lightweight Dart style)
// ─────────────────────────────────────────────

typedef DiscountStrategy = double Function(double price, int quantity);

class ShoppingCart {
  DiscountStrategy discountStrategy;
  ShoppingCart({required this.discountStrategy});

  double checkout(double price, int qty) {
    final discount = discountStrategy(price, qty);
    final total = price * qty - discount;
    print('  Subtotal: \$${(price * qty).toStringAsFixed(2)}'
        '  Discount: -\$${discount.toStringAsFixed(2)}'
        '  Total: \$${total.toStringAsFixed(2)}');
    return total;
  }
}

double noDiscount(double price, int qty) => 0;
double bulkDiscount(double price, int qty) => qty >= 5 ? price * qty * 0.10 : 0;
double loyaltyDiscount(double price, int qty) => price * qty * 0.15;

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void strategyExample() {
  print('═' * 50);
  print('STRATEGY PATTERN');
  print('═' * 50);

  final data = [64, 34, 25, 12, 22, 11, 90];
  print('\nOriginal: $data');

  final sorter = Sorter<int>(BubbleSort<int>());
  sorter.sort(data);

  sorter.strategy = QuickSort<int>();
  sorter.sort(data);

  sorter.strategy = MergeSort<int>();
  sorter.sort(data);

  print('\n[Function-based discount strategies]');
  final cart = ShoppingCart(discountStrategy: noDiscount);

  print('  No discount (qty=2):');
  cart.checkout(20.00, 2);

  cart.discountStrategy = bulkDiscount;
  print('  Bulk discount (qty=6):');
  cart.checkout(20.00, 6);

  cart.discountStrategy = loyaltyDiscount;
  print('  Loyalty discount (qty=3):');
  cart.checkout(20.00, 3);

  print('');
}

void main() => strategyExample();
