// # State Pattern
//
// Intent: Allow an object to alter its behaviour when its internal state
// changes. The object will appear to change its class.
//
// When to use:
// - An object's behaviour depends on its state and must change at runtime
// - Operations have large, multipart conditional statements based on state
// - Examples: Vending machine, traffic light, order lifecycle, media player,
//   network connection (connecting/open/closed)
//
// Key points — sealed-class variant (Dart 3+):
// - `sealed` enforces exhaustiveness: every switch must cover all subtypes
//   or the compiler emits an error (no runtime surprises when adding states)
// - State subtypes are pure immutable data — no back-reference to context
// - Context owns ALL transition logic via exhaustive switch statements
// - Compare to abstract-class variant: state objects called back into the
//   context to mutate it; sealed variant inverts that — context reads state

// ─────────────────────────────────────────────
// Sealed state hierarchy
//
// Each subtype carries only the data relevant to that state.
// ─────────────────────────────────────────────

sealed class VendingState {
  const VendingState();
}

class IdleState extends VendingState {
  const IdleState();
}

class HasMoneyState extends VendingState {
  final double balance;
  const HasMoneyState(this.balance);
}

class DispensingState extends VendingState {
  final String code;
  final double balance;
  const DispensingState({required this.code, required this.balance});
}

// ─────────────────────────────────────────────
// Product helper
// ─────────────────────────────────────────────

class VendingProduct {
  final String name;
  final double price;
  int stock;
  VendingProduct(this.name, this.price, this.stock);
}

// ─────────────────────────────────────────────
// Context
//
// Owns state, inventory, and all transition logic.
// Exhaustive switches guarantee every state is handled — the compiler
// rejects a missing case if a new VendingState subtype is added.
// ─────────────────────────────────────────────

class VendingMachine {
  VendingState _state = const IdleState();
  final Map<String, VendingProduct> _inventory = {};

  VendingMachine() {
    _inventory['A1'] = VendingProduct('Cola', 1.50, 5);
    _inventory['B2'] = VendingProduct('Chips', 2.00, 3);
  }

  void _transition(VendingState next) {
    print('  [State] ${_state.runtimeType} → ${next.runtimeType}');
    _state = next;
  }

  // ── insertCoin ──────────────────────────────

  void insertCoin(double amount) {
    switch (_state) {
      case IdleState():
        print('  Inserted \$${amount.toStringAsFixed(2)}.'
            ' Balance: \$${amount.toStringAsFixed(2)}');
        _transition(HasMoneyState(amount));
      case HasMoneyState(:final balance):
        final newBalance = balance + amount;
        print('  Added \$${amount.toStringAsFixed(2)}.'
            ' Balance: \$${newBalance.toStringAsFixed(2)}');
        _transition(HasMoneyState(newBalance));
      case DispensingState():
        print('  Please wait — dispensing in progress.');
    }
  }

  // ── selectProduct ───────────────────────────

  void selectProduct(String code) {
    switch (_state) {
      case IdleState():
        print('  Please insert coins first.');
      case HasMoneyState(:final balance):
        final product = _inventory[code];
        if (product == null) {
          print('  Unknown product code: $code');
          return;
        }
        if (product.stock == 0) {
          print('  ${product.name} is sold out.');
          return;
        }
        if (balance < product.price) {
          print('  Insufficient balance.'
              ' Need \$${product.price.toStringAsFixed(2)},'
              ' have \$${balance.toStringAsFixed(2)}');
          return;
        }
        print('  Selected: ${product.name}'
            ' (\$${product.price.toStringAsFixed(2)})');
        _transition(DispensingState(code: code, balance: balance));
        _dispense(); // immediately dispense after transitioning
      case DispensingState():
        print('  Please wait — dispensing in progress.');
    }
  }

  // ── cancel ──────────────────────────────────

  void cancel() {
    switch (_state) {
      case IdleState():
        print('  Nothing to cancel.');
      case HasMoneyState(:final balance):
        print('  Cancelled. Refunding \$${balance.toStringAsFixed(2)}');
        _transition(const IdleState());
      case DispensingState():
        print('  Cannot cancel — already dispensing.');
    }
  }

  // ── _dispense (private — only valid in DispensingState) ─────────────────

  void _dispense() {
    // Pattern-match to extract state data; non-Dispensing is unreachable here.
    final DispensingState(:code, :balance) = _state as DispensingState;
    final product = _inventory[code]!;
    final change  = balance - product.price;

    print('  Dispensing ${product.name}...');
    product.stock--;

    if (change > 0) {
      print('  Change returned: \$${change.toStringAsFixed(2)}');
    }
    if (product.stock == 0) {
      print('  ${product.name} now out of stock.');
    }

    _transition(const IdleState());
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void stateExample() {
  print('═' * 50);
  print('STATE PATTERN  (sealed-class variant)');
  print('═' * 50);

  final vm = VendingMachine();

  print('\n[Scenario 1: normal purchase]');
  vm.insertCoin(1.00);
  vm.insertCoin(1.00);
  vm.selectProduct('A1'); // Cola \$1.50 — \$0.50 change

  print('\n[Scenario 2: cancel]');
  vm.insertCoin(2.00);
  vm.cancel();

  print('\n[Scenario 3: insufficient funds]');
  vm.insertCoin(0.50);
  vm.selectProduct('B2'); // Chips \$2.00 — need more
  vm.insertCoin(1.50);
  vm.selectProduct('B2'); // now enough

  print('');
}

void main() => stateExample();
