import 'package:bloc/bloc.dart';
import 'package:riverpod/riverpod.dart';

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
// - Methods are abstract in the sealed base and implemented per subtype
// - The context (VendingMachine, Cubit, Notifier) is passed as a method
//   parameter — not stored in the state — so state objects remain data-only,
//   can be const, and are shareable across all three implementations

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
// Sealed state hierarchy
//
// Pure data — no stored context reference.
// Methods accept VendingMachine so the state can trigger transitions;
// this makes the same subtypes usable with VendingCubit and VendingNotifier.
// ─────────────────────────────────────────────

sealed class VendingState {
  const VendingState();

  // Methods receive the context; state owns the behaviour (classic GoF)
  // but stays data-only (no stored back-reference).
  void insertCoin(VendingMachine machine, double amount);
  void selectProduct(VendingMachine machine, String code);
  void cancel(VendingMachine machine);
}

class IdleState extends VendingState {
  const IdleState();

  @override
  void insertCoin(VendingMachine machine, double amount) {
    print('  Inserted \$${amount.toStringAsFixed(2)}.'
        ' Balance: \$${amount.toStringAsFixed(2)}');
    machine._transition(HasMoneyState(amount));
  }

  @override
  void selectProduct(VendingMachine machine, String code) =>
      print('  Please insert coins first.');

  @override
  void cancel(VendingMachine machine) => print('  Nothing to cancel.');
}

class HasMoneyState extends VendingState {
  final double balance;
  const HasMoneyState(this.balance);

  @override
  void insertCoin(VendingMachine machine, double amount) {
    final newBalance = balance + amount;
    print('  Added \$${amount.toStringAsFixed(2)}.'
        ' Balance: \$${newBalance.toStringAsFixed(2)}');
    machine._transition(HasMoneyState(newBalance));
  }

  @override
  void selectProduct(VendingMachine machine, String code) {
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
    machine._transition(DispensingState(code: code, balance: balance));
    machine._dispense();
  }

  @override
  void cancel(VendingMachine machine) {
    print('  Cancelled. Refunding \$${balance.toStringAsFixed(2)}');
    machine._transition(const IdleState());
  }
}

class DispensingState extends VendingState {
  final String code;
  final double balance;
  const DispensingState({required this.code, required this.balance});

  @override
  void insertCoin(VendingMachine machine, double amount) =>
      print('  Please wait — dispensing in progress.');

  @override
  void selectProduct(VendingMachine machine, String code) =>
      print('  Please wait — dispensing in progress.');

  @override
  void cancel(VendingMachine machine) =>
      print('  Cannot cancel — already dispensing.');
}

// ─────────────────────────────────────────────
// Custom context (VendingMachine)
//
// Holds state and inventory; delegates to state methods, passing itself.
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

  void _dispense() {
    final DispensingState(:code, :balance) = _state as DispensingState;
    final product = _inventory[code]!;
    final change  = balance - product.price;

    print('  Dispensing ${product.name}...');
    product.stock--;

    if (change > 0) print('  Change returned: \$${change.toStringAsFixed(2)}');
    if (product.stock == 0) print('  ${product.name} now out of stock.');

    _transition(const IdleState());
  }

  // Public API — each call passes `this` so the state can trigger transitions
  void insertCoin(double amount)  => _state.insertCoin(this, amount);
  void selectProduct(String code) => _state.selectProduct(this, code);
  void cancel()                   => _state.cancel(this);
}

// ─────────────────────────────────────────────
// BLoC / Cubit (package:bloc)
//
// Cubit<State> is the simplest BLoC abstraction:
//   emit(newState)  → updates state + notifies stream listeners
//   state           → synchronous read of the current state
//   stream          → Stream<State> for reactive subscribers
//   close()         → disposes the underlying StreamController
//
// The sealed VendingState hierarchy is reused as-is — state subtypes
// are pure data, so Cubit owns the transition logic via switch on `state`.
//
// A full Bloc<Event, State> adds an explicit sealed event type and
// on<Event>(handler) registration, preferred when events carry extra data
// or need async side-effects:
//
//   sealed class VendingEvent {}
//   class InsertCoin    extends VendingEvent { final double amount; ... }
//   class SelectProduct extends VendingEvent { final String code;  ... }
//   class Cancel        extends VendingEvent {}
//
//   class VendingBloc extends Bloc<VendingEvent, VendingState> {
//     VendingBloc() : super(const IdleState()) {
//       on<InsertCoin>(_onInsertCoin);
//       on<SelectProduct>(_onSelectProduct);
//       on<Cancel>(_onCancel);
//     }
//   }
// ─────────────────────────────────────────────

class VendingCubit extends Cubit<VendingState> {
  final Map<String, VendingProduct> _inventory = {
    'A1': VendingProduct('Cola', 1.50, 5),
    'B2': VendingProduct('Chips', 2.00, 3),
  };

  VendingCubit() : super(const IdleState());

  void insertCoin(double amount) {
    switch (state) {
      case IdleState():
        print('  Inserted \$${amount.toStringAsFixed(2)}.'
            ' Balance: \$${amount.toStringAsFixed(2)}');
        emit(HasMoneyState(amount));
      case HasMoneyState(:final balance):
        final newBalance = balance + amount;
        print('  Added \$${amount.toStringAsFixed(2)}.'
            ' Balance: \$${newBalance.toStringAsFixed(2)}');
        emit(HasMoneyState(newBalance));
      case DispensingState():
        print('  Please wait — dispensing in progress.');
    }
  }

  void selectProduct(String code) {
    switch (state) {
      case IdleState():
        print('  Please insert coins first.');
      case DispensingState():
        print('  Please wait — dispensing in progress.');
      case HasMoneyState(:final balance):
        final product = _inventory[code];
        if (product == null) { print('  Unknown product: $code'); return; }
        if (product.stock == 0) { print('  ${product.name} is sold out.'); return; }
        if (balance < product.price) {
          print('  Insufficient balance.'
              ' Need \$${product.price.toStringAsFixed(2)},'
              ' have \$${balance.toStringAsFixed(2)}');
          return;
        }
        print('  Selected: ${product.name}'
            ' (\$${product.price.toStringAsFixed(2)})');
        emit(DispensingState(code: code, balance: balance));
        _dispense(product, balance);
    }
  }

  void cancel() {
    switch (state) {
      case IdleState():
        print('  Nothing to cancel.');
      case HasMoneyState(:final balance):
        print('  Cancelled. Refunding \$${balance.toStringAsFixed(2)}');
        emit(const IdleState());
      case DispensingState():
        print('  Cannot cancel — already dispensing.');
    }
  }

  void _dispense(VendingProduct product, double balance) {
    final change = balance - product.price;
    print('  Dispensing ${product.name}...');
    product.stock--;
    if (change > 0) print('  Change returned: \$${change.toStringAsFixed(2)}');
    if (product.stock == 0) print('  ${product.name} now out of stock.');
    emit(const IdleState());
  }
}

// ─────────────────────────────────────────────
// Riverpod — Notifier<State> (package:riverpod)
//
// Notifier<State> maps the State pattern onto Riverpod's provider graph:
//   build()                       → returns the initial state
//   state = newState              → updates state + notifies subscribers
//   NotifierProvider<N, S>(N.new) → declares the provider
//   ProviderContainer             → pure-Dart owner of the provider graph
//   container.read(p.notifier)    → gets the Notifier to call methods on
//   container.read(p)             → reads current state synchronously
//   container.listen(p, fn)       → reactive subscription to state changes
//   container.dispose()           → closes all providers
// ─────────────────────────────────────────────

class VendingNotifier extends Notifier<VendingState> {
  final Map<String, VendingProduct> _inventory = {
    'A1': VendingProduct('Cola', 1.50, 5),
    'B2': VendingProduct('Chips', 2.00, 3),
  };

  @override
  VendingState build() => const IdleState();

  void insertCoin(double amount) {
    switch (state) {
      case IdleState():
        print('  Inserted \$${amount.toStringAsFixed(2)}.'
            ' Balance: \$${amount.toStringAsFixed(2)}');
        state = HasMoneyState(amount);
      case HasMoneyState(:final balance):
        final newBalance = balance + amount;
        print('  Added \$${amount.toStringAsFixed(2)}.'
            ' Balance: \$${newBalance.toStringAsFixed(2)}');
        state = HasMoneyState(newBalance);
      case DispensingState():
        print('  Please wait — dispensing in progress.');
    }
  }

  void selectProduct(String code) {
    switch (state) {
      case IdleState():
        print('  Please insert coins first.');
      case DispensingState():
        print('  Please wait — dispensing in progress.');
      case HasMoneyState(:final balance):
        final product = _inventory[code];
        if (product == null) { print('  Unknown product: $code'); return; }
        if (product.stock == 0) { print('  ${product.name} is sold out.'); return; }
        if (balance < product.price) {
          print('  Insufficient balance.'
              ' Need \$${product.price.toStringAsFixed(2)},'
              ' have \$${balance.toStringAsFixed(2)}');
          return;
        }
        print('  Selected: ${product.name}'
            ' (\$${product.price.toStringAsFixed(2)})');
        state = DispensingState(code: code, balance: balance);
        _dispense(product, balance);
    }
  }

  void cancel() {
    switch (state) {
      case IdleState():
        print('  Nothing to cancel.');
      case HasMoneyState(:final balance):
        print('  Cancelled. Refunding \$${balance.toStringAsFixed(2)}');
        state = const IdleState();
      case DispensingState():
        print('  Cannot cancel — already dispensing.');
    }
  }

  void _dispense(VendingProduct product, double balance) {
    final change = balance - product.price;
    print('  Dispensing ${product.name}...');
    product.stock--;
    if (change > 0) print('  Change returned: \$${change.toStringAsFixed(2)}');
    if (product.stock == 0) print('  ${product.name} now out of stock.');
    state = const IdleState();
  }
}

final vendingProvider =
    NotifierProvider<VendingNotifier, VendingState>(VendingNotifier.new);

// ─────────────────────────────────────────────
// Example runners
// ─────────────────────────────────────────────

void stateExample() {
  print('═' * 50);
  print('STATE PATTERN  (sealed-class + VendingMachine)');
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

Future<void> blocStateExample() async {
  print('═' * 50);
  print('STATE PATTERN  (BLoC / Cubit)');
  print('═' * 50);

  final vm = VendingCubit();

  // In Flutter / reactive code you would subscribe to all transitions:
  //   vm.stream.listen((s) => print('  [Stream] → ${s.runtimeType}'));

  print('\n[Scenario 1: normal purchase]');
  vm.insertCoin(1.00);
  vm.insertCoin(1.00);
  vm.selectProduct('A1');

  print('\n[Scenario 2: cancel]');
  vm.insertCoin(2.00);
  vm.cancel();

  print('\n[Scenario 3: insufficient funds]');
  vm.insertCoin(0.50);
  vm.selectProduct('B2');
  vm.insertCoin(1.50);
  vm.selectProduct('B2');

  await vm.close(); // disposes the internal StreamController
  print('');
}

void riverpodStateExample() {
  print('═' * 50);
  print('STATE PATTERN  (Riverpod Notifier)');
  print('═' * 50);

  final container = ProviderContainer();
  final vm = container.read(vendingProvider.notifier);

  // Reactive subscription — fires synchronously on each state= assignment:
  container.listen(vendingProvider, (prev, next) {
    print('  [Provider] ${prev?.runtimeType} → ${next.runtimeType}');
  }, fireImmediately: false);

  print('\n[Scenario 1: normal purchase]');
  vm.insertCoin(1.00);
  vm.insertCoin(1.00);
  vm.selectProduct('A1');

  print('\n[Scenario 2: cancel]');
  vm.insertCoin(2.00);
  vm.cancel();

  print('\n[Scenario 3: insufficient funds]');
  vm.insertCoin(0.50);
  vm.selectProduct('B2');
  vm.insertCoin(1.50);
  vm.selectProduct('B2');

  container.dispose();
  print('');
}

Future<void> main() async {
  stateExample();
  await blocStateExample();
  riverpodStateExample();
}
