import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
// - VendingState: abstract interface — methods return the next VendingState;
//   a model getter exposes the VendingStateModel for BLoC/Riverpod emission
// - Concrete states implement VendingState only; each holds its
//   VendingStateModel subtype by composition (no model inheritance)
// - VendingMachine works purely with VendingState; BLoC/Riverpod emit
//   next.model to keep their VendingStateModel state type in sync

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

sealed class VendingStateModel extends Equatable {
  const VendingStateModel();
}

class IdleModel extends VendingStateModel {
  const IdleModel();

  @override
  List<Object?> get props => const [];
}

class HasMoneyModel extends VendingStateModel {
  final double balance;
  const HasMoneyModel(this.balance);

  @override
  List<Object?> get props => [balance];
}

class DispensingModel extends VendingStateModel {
  final String code;
  final double balance;
  const DispensingModel({required this.code, required this.balance});

  @override
  List<Object?> get props => [code, balance];
}

// ─────────────────────────────────────────────
// VendingState — behaviour interface
//
// Each method returns the next VendingState. Returning `this` means no
// transition. The model getter exposes the VendingStateModel so BLoC and
// Riverpod can emit/set it as their state type. selectProduct receives
// the inventory map for stock and price validation.
// ─────────────────────────────────────────────

abstract interface class VendingState {
  VendingStateModel get model;
  VendingState insertCoin(double amount);
  VendingState selectProduct(String code, Map<String, VendingProduct> inventory);
  VendingState cancel();
}

// ─────────────────────────────────────────────
// Concrete states
//
// Each class implements VendingState only; data is held by composition —
// a final field of the matching VendingStateModel subtype. The model getter
// satisfies the interface; no class inherits from the model hierarchy.
// ─────────────────────────────────────────────

class IdleState extends Equatable implements VendingState {
  const IdleState();

  @override
  List<Object?> get props => const [];

  @override
  IdleModel get model => const IdleModel();

  @override
  VendingState insertCoin(double amount) {
    print(
      '  Inserted \$${amount.toStringAsFixed(2)}.'
      ' Balance: \$${amount.toStringAsFixed(2)}',
    );
    return HasMoneyState(amount);
  }

  @override
  VendingState selectProduct(String code, Map<String, VendingProduct> inventory) {
    print('  Please insert coins first.');
    return this;
  }

  @override
  VendingState cancel() {
    print('  Nothing to cancel.');
    return this;
  }
}

class HasMoneyState extends Equatable implements VendingState {
  @override
  final HasMoneyModel model;

  HasMoneyState(double balance) : model = HasMoneyModel(balance);

  @override
  List<Object?> get props => [model];

  @override
  VendingState insertCoin(double amount) {
    final newBalance = model.balance + amount;
    print(
      '  Added \$${amount.toStringAsFixed(2)}.'
      ' Balance: \$${newBalance.toStringAsFixed(2)}',
    );
    return HasMoneyState(newBalance);
  }

  @override
  VendingState selectProduct(String code, Map<String, VendingProduct> inventory) {
    final product = inventory[code];
    if (product == null) {
      print('  Unknown product code: $code');
      return this;
    }
    if (product.stock == 0) {
      print('  ${product.name} is sold out.');
      return this;
    }
    if (model.balance < product.price) {
      print(
        '  Insufficient balance.'
        ' Need \$${product.price.toStringAsFixed(2)},'
        ' have \$${model.balance.toStringAsFixed(2)}',
      );
      return this;
    }
    print(
      '  Selected: ${product.name}'
      ' (\$${product.price.toStringAsFixed(2)})',
    );
    return DispensingState(code: code, balance: model.balance);
  }

  @override
  VendingState cancel() {
    print('  Cancelled. Refunding \$${model.balance.toStringAsFixed(2)}');
    return const IdleState();
  }
}

class DispensingState extends Equatable implements VendingState {
  @override
  final DispensingModel model;

  DispensingState({required String code, required double balance})
      : model = DispensingModel(code: code, balance: balance);

  @override
  List<Object?> get props => [model];

  @override
  VendingState insertCoin(double amount) {
    print('  Please wait — dispensing in progress.');
    return this;
  }

  @override
  VendingState selectProduct(String code, Map<String, VendingProduct> inventory) {
    print('  Please wait — dispensing in progress.');
    return this;
  }

  @override
  VendingState cancel() {
    print('  Cannot cancel — already dispensing.');
    return this;
  }
}

// ─────────────────────────────────────────────
// Custom context (VendingMachine)
//
// Works entirely with VendingState — no casts needed. selectProduct checks
// whether the returned next state is a DispensingState and, if so, runs
// the dispense side-effect.
// ─────────────────────────────────────────────

class VendingMachine {
  VendingState _state = const IdleState();
  final Map<String, VendingProduct> _inventory = {};

  VendingMachine() {
    _inventory['A1'] = VendingProduct('Cola', 1.50, 5);
    _inventory['B2'] = VendingProduct('Chips', 2.00, 3);
  }

  void _transition(VendingState next) {
    if (_state == next) return;
    print('  [State] ${_state.runtimeType} → ${next.runtimeType}');
    _state = next;
  }

  void _dispense(DispensingState dispensing) {
    final product = _inventory[dispensing.model.code]!;
    final change = dispensing.model.balance - product.price;

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
    if (next is DispensingState) _dispense(next);
  }

  void cancel() => _transition(_state.cancel());
}

// ─────────────────────────────────────────────
// BLoC / Cubit (package:bloc)
//
// _currentState tracks the VendingState (behaviour); emit(next.model)
// keeps Cubit<VendingStateModel> in sync for reactive subscribers.
// _apply triggers the dispense side-effect when next is DispensingState.
//
// A full Bloc<Event, State> adds an explicit sealed event type:
//
//   sealed class VendingEvent {}
//   class InsertCoin    extends VendingEvent { final double amount; ... }
//   class SelectProduct extends VendingEvent { final String code;  ... }
//   class Cancel        extends VendingEvent {}
//
//   class VendingBloc extends Bloc<VendingEvent, VendingStateModel> {
//     VendingBloc() : super(const IdleModel()) {
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

  void _apply(VendingState next) {
    emit(next);
    if (next is DispensingState) _dispense(next);
  }

  void insertCoin(double amount)  => _apply(state.insertCoin(amount));
  void selectProduct(String code) => _apply(state.selectProduct(code, _inventory));
  void cancel()                   => _apply(state.cancel());

  void _dispense(DispensingState dispensing) {
    final product = _inventory[dispensing.model.code]!;
    final change = dispensing.model.balance - product.price;
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
// Same split as VendingCubit: _currentState tracks the VendingState;
// state= sets the VendingStateModel for reactive subscribers.
// ─────────────────────────────────────────────

class VendingNotifier extends Notifier<VendingState> {
  final Map<String, VendingProduct> _inventory = {
    'A1': VendingProduct('Cola', 1.50, 5),
    'B2': VendingProduct('Chips', 2.00, 3),
  };

  @override
  VendingState build() => const IdleState();

  void _apply(VendingState next) {
    state = next;
    if (next is DispensingState) _dispense(next);
  }

  void insertCoin(double amount)  => _apply(state.insertCoin(amount));
  void selectProduct(String code) => _apply(state.selectProduct(code, _inventory));
  void cancel()                   => _apply(state.cancel());

  void _dispense(DispensingState dispensing) {
    final product = _inventory[dispensing.model.code]!;
    final change = dispensing.model.balance - product.price;
    print('  Dispensing ${product.name}...');
    product.stock--;
    if (change > 0) print('  Change returned: \$${change.toStringAsFixed(2)}');
    if (product.stock == 0) print('  ${product.name} now out of stock.');
    state = const IdleState();
  }
}

final vendingProvider = NotifierProvider<VendingNotifier, VendingState>(
  VendingNotifier.new,
);

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
