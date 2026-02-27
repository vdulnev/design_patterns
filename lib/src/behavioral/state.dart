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
// Key points in Dart:
// - State interface defines behaviour for each state
// - Context holds current state and delegates to it
// - Each state knows what the next state should be (or context decides)

// ─────────────────────────────────────────────
// Context forward declaration
// ─────────────────────────────────────────────

class VendingMachine {
  late VendingState _state;
  double _balance = 0;
  final Map<String, VendingProduct> _inventory = {};

  VendingMachine() {
    _state = IdleState(this);
    _inventory['A1'] = VendingProduct('Cola', 1.50, 5);
    _inventory['B2'] = VendingProduct('Chips', 2.00, 3);
  }

  // State transitions
  void transitionTo(VendingState state) {
    print('  [State] → ${state.runtimeType}');
    _state = state;
  }

  // Public API — delegated to current state
  void insertCoin(double amount) => _state.insertCoin(amount);
  void selectProduct(String code)  => _state.selectProduct(code);
  void dispense()                  => _state.dispense();
  void cancel()                    => _state.cancel();

  // Helpers for states
  double get balance => _balance;
  void addBalance(double amount) => _balance += amount;
  void resetBalance() => _balance = 0;

  VendingProduct? getProduct(String code) => _inventory[code];
  void decrementProduct(String code) {
    final p = _inventory[code];
    if (p != null) p.stock--;
  }

  String? selectedCode;
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
// State interface
// ─────────────────────────────────────────────

abstract class VendingState {
  final VendingMachine machine;
  VendingState(this.machine);

  void insertCoin(double amount);
  void selectProduct(String code);
  void dispense();
  void cancel();
}

// ─────────────────────────────────────────────
// Concrete states
// ─────────────────────────────────────────────

class IdleState extends VendingState {
  IdleState(super.machine);

  @override
  void insertCoin(double amount) {
    machine.addBalance(amount);
    print('  Inserted \$${amount.toStringAsFixed(2)}. Balance: \$${machine.balance.toStringAsFixed(2)}');
    machine.transitionTo(HasMoneyState(machine));
  }

  @override
  void selectProduct(String code) =>
      print('  Please insert coins first.');

  @override
  void dispense() => print('  Please insert coins and select a product.');

  @override
  void cancel() => print('  Nothing to cancel.');
}

class HasMoneyState extends VendingState {
  HasMoneyState(super.machine);

  @override
  void insertCoin(double amount) {
    machine.addBalance(amount);
    print('  Added \$${amount.toStringAsFixed(2)}. Balance: \$${machine.balance.toStringAsFixed(2)}');
  }

  @override
  void selectProduct(String code) {
    final product = machine.getProduct(code);
    if (product == null) {
      print('  Unknown product code: $code');
      return;
    }
    if (product.stock == 0) {
      print('  ${product.name} is sold out.');
      return;
    }
    if (machine.balance < product.price) {
      print('  Insufficient balance. Need \$${product.price.toStringAsFixed(2)}, have \$${machine.balance.toStringAsFixed(2)}');
      return;
    }
    machine.selectedCode = code;
    print('  Selected: ${product.name} (\$${product.price.toStringAsFixed(2)})');
    machine.transitionTo(DispensingState(machine));
    machine.dispense(); // trigger dispense now that state is set
  }

  @override
  void dispense() => print('  Select a product first.');

  @override
  void cancel() {
    final refund = machine.balance;
    machine.resetBalance();
    print('  Cancelled. Refunding \$${refund.toStringAsFixed(2)}');
    machine.transitionTo(IdleState(machine));
  }
}

class DispensingState extends VendingState {
  DispensingState(super.machine);

  @override
  void insertCoin(double amount) => print('  Please wait — dispensing in progress.');

  @override
  void selectProduct(String code) => print('  Please wait — dispensing in progress.');

  @override
  void dispense() {
    final code    = machine.selectedCode!;
    final product = machine.getProduct(code)!;
    final change  = machine.balance - product.price;

    print('  Dispensing ${product.name}...');
    machine.decrementProduct(code);
    machine.resetBalance();
    machine.selectedCode = null;

    if (change > 0) {
      print('  Change returned: \$${change.toStringAsFixed(2)}');
    }

    final remaining = machine.getProduct(code)!.stock;
    if (remaining == 0) {
      print('  ${product.name} now out of stock.');
    }

    machine.transitionTo(IdleState(machine));
  }

  @override
  void cancel() => print('  Cannot cancel — already dispensing.');
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void stateExample() {
  print('═' * 50);
  print('STATE PATTERN');
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
