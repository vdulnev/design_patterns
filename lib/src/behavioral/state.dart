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
// Key points — sealed-class + method-per-subtype variant (Dart 3+):
// - `sealed` enforces exhaustiveness: any switch on VendingState must cover
//   every subtype or the compiler rejects it
// - Methods are declared abstract in the sealed base and implemented in each
//   subtype — each state encapsulates its own behaviour (classic GoF)
// - State subtypes hold a back-reference to the context to trigger transitions
// - Context delegates: insertCoin/selectProduct/cancel → _state.method()

// ─────────────────────────────────────────────
// Forward declaration (states reference VendingMachine)
// ─────────────────────────────────────────────

class VendingMachine {
  late VendingState _state;
  final Map<String, VendingProduct> _inventory = {};

  VendingMachine() {
    _state = IdleState(this);
    _inventory['A1'] = VendingProduct('Cola', 1.50, 5);
    _inventory['B2'] = VendingProduct('Chips', 2.00, 3);
  }

  void _transition(VendingState next) {
    print('  [State] ${_state.runtimeType} → ${next.runtimeType}');
    _state = next;
  }

  void _dispense() {
    final DispensingState(:code, :balance) = _state as DispensingState;
    final product = _inventory[code]!;
    final change  = balance - product.price;

    print('  Dispensing ${product.name}...');
    product.stock--;

    if (change > 0) print('  Change returned: \$${change.toStringAsFixed(2)}');
    if (product.stock == 0) print('  ${product.name} now out of stock.');

    _transition(IdleState(this));
  }

  // Public API — delegates to current state
  void insertCoin(double amount)  => _state.insertCoin(amount);
  void selectProduct(String code) => _state.selectProduct(code);
  void cancel()                   => _state.cancel();
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
// Sealed state base
//
// Abstract methods make every subtype self-contained.
// `sealed` means the compiler can verify switch exhaustiveness.
// ─────────────────────────────────────────────

sealed class VendingState {
  final VendingMachine machine;
  VendingState(this.machine);

  void insertCoin(double amount);
  void selectProduct(String code);
  void cancel();
}

// ─────────────────────────────────────────────
// Concrete states
// ─────────────────────────────────────────────

class IdleState extends VendingState {
  IdleState(super.machine);

  @override
  void insertCoin(double amount) {
    print('  Inserted \$${amount.toStringAsFixed(2)}.'
        ' Balance: \$${amount.toStringAsFixed(2)}');
    machine._transition(HasMoneyState(machine, amount));
  }

  @override
  void selectProduct(String code) => print('  Please insert coins first.');

  @override
  void cancel() => print('  Nothing to cancel.');
}

class HasMoneyState extends VendingState {
  final double balance;
  HasMoneyState(super.machine, this.balance);

  @override
  void insertCoin(double amount) {
    final newBalance = balance + amount;
    print('  Added \$${amount.toStringAsFixed(2)}.'
        ' Balance: \$${newBalance.toStringAsFixed(2)}');
    machine._transition(HasMoneyState(machine, newBalance));
  }

  @override
  void selectProduct(String code) {
    final product = machine._inventory[code];
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
    machine._transition(DispensingState(machine, code: code, balance: balance));
    machine._dispense();
  }

  @override
  void cancel() {
    print('  Cancelled. Refunding \$${balance.toStringAsFixed(2)}');
    machine._transition(IdleState(machine));
  }
}

class DispensingState extends VendingState {
  final String code;
  final double balance;
  DispensingState(super.machine, {required this.code, required this.balance});

  @override
  void insertCoin(double amount) =>
      print('  Please wait — dispensing in progress.');

  @override
  void selectProduct(String code) =>
      print('  Please wait — dispensing in progress.');

  @override
  void cancel() => print('  Cannot cancel — already dispensing.');
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
