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
// Key points — reactive split model/interface variant (Dart 3+):
// - VendingStateModel: sealed, pure data — state type for BLoC and Riverpod
// - VendingState: abstract interface — each method returns the next
//   VendingStateModel; no VendingMachine reference (pure input→next-state fn)
// - Concrete states extend their model class AND implement VendingState
// - VendingMachine applies the returned next state and triggers side-effects

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
// VendingStateModel — sealed pure-data hierarchy
//
// Direct subtypes are IdleModel, HasMoneyModel, DispensingModel.
// Used as the State type parameter for Cubit<VendingStateModel> and
// Notifier<VendingStateModel> — the sealed keyword makes every switch
// on VendingStateModel exhaustively checked by the compiler.
// ─────────────────────────────────────────────

sealed class VendingStateModel {
  const VendingStateModel();
}

class IdleModel extends VendingStateModel {
  const IdleModel();
}

class HasMoneyModel extends VendingStateModel {
  final double balance;
  const HasMoneyModel(this.balance);
}

class DispensingModel extends VendingStateModel {
  final String code;
  final double balance;
  const DispensingModel({required this.code, required this.balance});
}

// ─────────────────────────────────────────────
// VendingState — behaviour interface
//
// Each method returns the next VendingStateModel. Returning `this` means
// no transition. selectProduct receives the inventory map so the state
// can validate stock and price independently of VendingMachine.
// ─────────────────────────────────────────────

abstract interface class VendingState {
  VendingStateModel insertCoin(double amount);
  VendingStateModel selectProduct(String code, Map<String, VendingProduct> inventory);
  VendingStateModel cancel();
}

// ─────────────────────────────────────────────
// Concrete states
//
// Each class extends its model (carries data, satisfies VendingStateModel)
// AND implements VendingState (carries behaviour, usable by VendingMachine).
// ─────────────────────────────────────────────

class IdleState extends IdleModel implements VendingState {
  const IdleState();

  @override
  VendingStateModel insertCoin(double amount) {
    print('  Inserted \$${amount.toStringAsFixed(2)}.'
        ' Balance: \$${amount.toStringAsFixed(2)}');
    return HasMoneyState(amount);
  }

  @override
  VendingStateModel selectProduct(String code, Map<String, VendingProduct> inventory) {
    print('  Please insert coins first.');
    return this;
  }

  @override
  VendingStateModel cancel() {
    print('  Nothing to cancel.');
    return this;
  }
}

class HasMoneyState extends HasMoneyModel implements VendingState {
  const HasMoneyState(super.balance);

  @override
  VendingStateModel insertCoin(double amount) {
    final newBalance = balance + amount;
    print('  Added \$${amount.toStringAsFixed(2)}.'
        ' Balance: \$${newBalance.toStringAsFixed(2)}');
    return HasMoneyState(newBalance);
  }

  @override
  VendingStateModel selectProduct(String code, Map<String, VendingProduct> inventory) {
    final product = inventory[code];
    if (product == null) {
      print('  Unknown product code: $code');
      return this;
    }
    if (product.stock == 0) {
      print('  ${product.name} is sold out.');
      return this;
    }
    if (balance < product.price) {
      print('  Insufficient balance.'
          ' Need \$${product.price.toStringAsFixed(2)},'
          ' have \$${balance.toStringAsFixed(2)}');
      return this;
    }
    print('  Selected: ${product.name}'
        ' (\$${product.price.toStringAsFixed(2)})');
    return DispensingState(code: code, balance: balance);
  }

  @override
  VendingStateModel cancel() {
    print('  Cancelled. Refunding \$${balance.toStringAsFixed(2)}');
    return const IdleState();
  }
}

class DispensingState extends DispensingModel implements VendingState {
  const DispensingState({required super.code, required super.balance});

  @override
  VendingStateModel insertCoin(double amount) {
    print('  Please wait — dispensing in progress.');
    return this;
  }

  @override
  VendingStateModel selectProduct(String code, Map<String, VendingProduct> inventory) {
    print('  Please wait — dispensing in progress.');
    return this;
  }

  @override
  VendingStateModel cancel() {
    print('  Cannot cancel — already dispensing.');
    return this;
  }
}

// ─────────────────────────────────────────────
// Custom context (VendingMachine)
//
// Calls the reactive VendingState methods and applies the returned next
// state. selectProduct also checks whether the next state is a
// DispensingModel and, if so, runs the dispense side-effect.
// ─────────────────────────────────────────────

class VendingMachine {
  VendingState _state = const IdleState();
  final Map<String, VendingProduct> _inventory = {};

  VendingMachine() {
    _inventory['A1'] = VendingProduct('Cola', 1.50, 5);
    _inventory['B2'] = VendingProduct('Chips', 2.00, 3);
  }

  void _transition(VendingStateModel next) {
    if (identical(_state, next)) return;
    print('  [State] ${_state.runtimeType} → ${next.runtimeType}');
    _state = next as VendingState; // safe: all concrete states implement VendingState
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

  void insertCoin(double amount) => _transition(_state.insertCoin(amount));

  void selectProduct(String code) {
    final next = _state.selectProduct(code, _inventory);
    _transition(next);
    if (next is DispensingModel) _dispense();
  }

  void cancel() => _transition(_state.cancel());
}

// ─────────────────────────────────────────────
// BLoC / Cubit (package:bloc)
//
// Delegates to VendingState — the same reactive interface used by
// VendingMachine. _state casts Cubit.state to VendingState (safe: all
// concrete states implement both). _apply emits the returned next state
// and triggers the dispense side-effect when it is a DispensingModel.
//
// A full Bloc<Event, State> adds an explicit sealed event type:
//
//   sealed class VendingEvent {}
//   class InsertCoin    extends VendingEvent { final double amount; ... }
//   class SelectProduct extends VendingEvent { final String code;  ... }
//   class Cancel        extends VendingEvent {}
//
//   class VendingBloc extends Bloc<VendingEvent, VendingStateModel> {
//     VendingBloc() : super(const IdleState()) {
//       on<InsertCoin>(_onInsertCoin);
//       on<SelectProduct>(_onSelectProduct);
//       on<Cancel>(_onCancel);
//     }
//   }
// ─────────────────────────────────────────────

class VendingCubit extends Cubit<VendingStateModel> {
  final Map<String, VendingProduct> _inventory = {
    'A1': VendingProduct('Cola', 1.50, 5),
    'B2': VendingProduct('Chips', 2.00, 3),
  };

  VendingCubit() : super(const IdleState());

  VendingState get _state => state as VendingState;

  void _apply(VendingStateModel next) {
    if (identical(state, next)) return;
    emit(next);
    if (next is DispensingModel) _dispense(next);
  }

  void insertCoin(double amount)  => _apply(_state.insertCoin(amount));
  void selectProduct(String code) => _apply(_state.selectProduct(code, _inventory));
  void cancel()                   => _apply(_state.cancel());

  void _dispense(DispensingModel dispensing) {
    final product = _inventory[dispensing.code]!;
    final change  = dispensing.balance - product.price;
    print('  Dispensing ${product.name}...');
    product.stock--;
    if (change > 0) print('  Change returned: \$${change.toStringAsFixed(2)}');
    if (product.stock == 0) print('  ${product.name} now out of stock.');
    emit(const IdleState());
  }
}

// ─────────────────────────────────────────────
// Riverpod — Notifier<VendingStateModel> (package:riverpod)
//
// Delegates to VendingState — same approach as VendingCubit. _apply sets
// the Notifier state= and triggers _dispense when it is a DispensingModel.
// ─────────────────────────────────────────────

class VendingNotifier extends Notifier<VendingStateModel> {
  final Map<String, VendingProduct> _inventory = {
    'A1': VendingProduct('Cola', 1.50, 5),
    'B2': VendingProduct('Chips', 2.00, 3),
  };

  @override
  VendingStateModel build() => const IdleState();

  VendingState get _state => state as VendingState;

  void _apply(VendingStateModel next) {
    if (identical(state, next)) return;
    state = next;
    if (next is DispensingModel) _dispense(next);
  }

  void insertCoin(double amount)  => _apply(_state.insertCoin(amount));
  void selectProduct(String code) => _apply(_state.selectProduct(code, _inventory));
  void cancel()                   => _apply(_state.cancel());

  void _dispense(DispensingModel dispensing) {
    final product = _inventory[dispensing.code]!;
    final change  = dispensing.balance - product.price;
    print('  Dispensing ${product.name}...');
    product.stock--;
    if (change > 0) print('  Change returned: \$${change.toStringAsFixed(2)}');
    if (product.stock == 0) print('  ${product.name} now out of stock.');
    state = const IdleState();
  }
}

final vendingProvider =
    NotifierProvider<VendingNotifier, VendingStateModel>(VendingNotifier.new);

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
