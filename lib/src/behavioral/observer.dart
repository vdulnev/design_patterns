// # Observer Pattern
//
// Intent: Define a one-to-many dependency between objects so that when one
// object changes state, all its dependents are notified and updated
// automatically.
//
// When to use:
// - A change in one object requires changing others, and you don't know how many
// - Objects should be able to notify other objects without making assumptions
// - Examples: Event systems, data binding, stock tickers, UI state management
//   (this is the basis of Flutter's ValueNotifier / ChangeNotifier)
//
// Key points in Dart:
// - Observer interface with an `update` method (or typed callback)
// - Subject (Observable) holds a list of observers and notifies them
// - Dart Streams are a built-in implementation of the observer pattern

// ─────────────────────────────────────────────
// Observer interface
// ─────────────────────────────────────────────

abstract class StockObserver {
  void onPriceChanged(String symbol, double oldPrice, double newPrice);
}

// ─────────────────────────────────────────────
// Subject (Observable)
// ─────────────────────────────────────────────

class StockMarket {
  final Map<String, double> _prices = {};
  final List<StockObserver> _observers = [];

  void subscribe(StockObserver observer) {
    _observers.add(observer);
  }

  void unsubscribe(StockObserver observer) {
    _observers.remove(observer);
  }

  void _notify(String symbol, double oldPrice, double newPrice) {
    for (final observer in List.of(_observers)) {
      observer.onPriceChanged(symbol, oldPrice, newPrice);
    }
  }

  void updatePrice(String symbol, double price) {
    final old = _prices[symbol] ?? price;
    _prices[symbol] = price;
    if (old != price) _notify(symbol, old, price);
  }

  double? getPrice(String symbol) => _prices[symbol];
}

// ─────────────────────────────────────────────
// Concrete observers
// ─────────────────────────────────────────────

class PriceAlertObserver implements StockObserver {
  final String name;
  final double threshold; // alert if change % exceeds this

  PriceAlertObserver(this.name, {required this.threshold});

  @override
  void onPriceChanged(String symbol, double oldPrice, double newPrice) {
    final change = ((newPrice - oldPrice) / oldPrice * 100).abs();
    if (change >= threshold) {
      final direction = newPrice > oldPrice ? '▲' : '▼';
      print('  [$name] ALERT: $symbol $direction ${change.toStringAsFixed(2)}%'
          '  (\$${oldPrice.toStringAsFixed(2)} → \$${newPrice.toStringAsFixed(2)})');
    }
  }
}

class PortfolioObserver implements StockObserver {
  final String name;
  final Map<String, int> _holdings; // symbol → shares

  PortfolioObserver(this.name, Map<String, int> holdings)
      : _holdings = Map.of(holdings);

  @override
  void onPriceChanged(String symbol, double oldPrice, double newPrice) {
    final shares = _holdings[symbol];
    if (shares == null) return;
    final delta = (newPrice - oldPrice) * shares;
    final sign = delta >= 0 ? '+' : '';
    print('  [$name] $symbol ×$shares → P&L: $sign\$${delta.toStringAsFixed(2)}');
  }
}

class AuditLogObserver implements StockObserver {
  final List<String> log = [];

  @override
  void onPriceChanged(String symbol, double oldPrice, double newPrice) {
    final entry =
        '${DateTime.now().toIso8601String()} | $symbol: $oldPrice → $newPrice';
    log.add(entry);
    print('  [Audit] $entry');
  }
}

// ─────────────────────────────────────────────
// Bonus: Dart-idiomatic observer using callbacks
// ─────────────────────────────────────────────

class EventEmitter<T> {
  final List<void Function(T)> _listeners = [];

  void on(void Function(T) listener) => _listeners.add(listener);
  void off(void Function(T) listener) => _listeners.remove(listener);
  void emit(T event) {
    for (final l in List.of(_listeners)) {
      l(event);
    }
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void observerExample() {
  print('═' * 50);
  print('OBSERVER PATTERN');
  print('═' * 50);

  final market = StockMarket();

  final alert     = PriceAlertObserver('AlertBot', threshold: 5.0);
  final portfolio = PortfolioObserver('MyPortfolio', {'AAPL': 10, 'GOOG': 3});
  final audit     = AuditLogObserver();

  market
    ..subscribe(alert)
    ..subscribe(portfolio)
    ..subscribe(audit);

  // Set initial prices (no notification — same price)
  market.updatePrice('AAPL', 150.00);
  market.updatePrice('GOOG', 2800.00);

  print('\nPrice updates:');
  market.updatePrice('AAPL', 162.50);   // +8.3% — triggers alert
  market.updatePrice('GOOG', 2850.00);  // +1.8% — no alert
  market.updatePrice('AAPL', 155.00);   // -4.6% — no alert

  // Unsubscribe audit and fire one more
  market.unsubscribe(audit);
  print('\n(Audit unsubscribed)');
  market.updatePrice('GOOG', 2600.00);  // -8.8% — alert + portfolio, no audit

  print('\n[Callback-style EventEmitter]');
  final clicks = EventEmitter<String>();
  clicks.on((btn) => print('  Button "$btn" clicked!'));
  clicks.emit('Submit');
  clicks.emit('Cancel');

  print('');
}

void main() => observerExample();
