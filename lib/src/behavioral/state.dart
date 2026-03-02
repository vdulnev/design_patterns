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
// Key points — split model/interface variant (Dart 3+):
// - VendingStateModel: sealed, pure data — used as the state type by BLoC
//   and Riverpod; switch exhaustiveness is enforced by the sealed keyword
// - VendingState: abstract interface, behaviour only — used by VendingMachine
// - Concrete states (IdleState, HasMoneyState, DispensingState) extend their
//   model class AND implement VendingState, satisfying both roles with one class

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
// Declares the three operations; VendingMachine holds a VendingState and
// delegates to it, passing itself so the state can trigger transitions.
// ─────────────────────────────────────────────

abstract interface class VendingState {
  void insertCoin(VendingMachine machine, double amount);
  void selectProduct(VendingMachine machine, String code);
  void cancel(VendingMachine machine);
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

class HasMoneyState extends HasMoneyModel implements VendingState {
  const HasMoneyState(super.balance);

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

class DispensingState extends DispensingModel implements VendingState {
  const DispensingState({required super.code, required super.balance});

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
// _state is typed as VendingState (interface); concrete instances are
// always one of the three concrete states, which are also VendingStateModel
// subtypes — but VendingMachine never needs to know that.
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

  void insertCoin(double amount)  => _state.insertCoin(this, amount);
  void selectProduct(String code) => _state.selectProduct(this, code);
  void cancel()                   => _state.cancel(this);
}

// ─────────────────────────────────────────────
// BLoC / Cubit (package:bloc)
//
// Uses VendingStateModel as the state type — pure data, sealed.
// Cubit owns the transition logic via exhaustive switch on `state`.
// Because IdleState/HasMoneyState/DispensingState extend the sealed model
// subtypes, emitting them satisfies Cubit<VendingStateModel>.
// Pattern matching uses the model subtypes (IdleModel, HasMoneyModel, …)
// which also match their subclasses.
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

  void insertCoin(double amount) {
    switch (state) {
      case IdleModel():
        print('  Inserted \$${amount.toStringAsFixed(2)}.'
            ' Balance: \$${amount.toStringAsFixed(2)}');
        emit(HasMoneyState(amount));
      case HasMoneyModel(:final balance):
        final newBalance = balance + amount;
        print('  Added \$${amount.toStringAsFixed(2)}.'
            ' Balance: \$${newBalance.toStringAsFixed(2)}');
        emit(HasMoneyState(newBalance));
      case DispensingModel():
        print('  Please wait — dispensing in progress.');
    }
  }

  void selectProduct(String code) {
    switch (state) {
      case IdleModel():
        print('  Please insert coins first.');
      case DispensingModel():
        print('  Please wait — dispensing in progress.');
      case HasMoneyModel(:final balance):
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
      case IdleModel():
        print('  Nothing to cancel.');
      case HasMoneyModel(:final balance):
        print('  Cancelled. Refunding \$${balance.toStringAsFixed(2)}');
        emit(const IdleState());
      case DispensingModel():
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
// Riverpod — Notifier<VendingStateModel> (package:riverpod)
//
// Same split: VendingStateModel as the state type, exhaustive switch on
// the model subtypes, state= setter for transitions.
// ─────────────────────────────────────────────

class VendingNotifier extends Notifier<VendingStateModel> {
  final Map<String, VendingProduct> _inventory = {
    'A1': VendingProduct('Cola', 1.50, 5),
    'B2': VendingProduct('Chips', 2.00, 3),
  };

  @override
  VendingStateModel build() => const IdleState();

  void insertCoin(double amount) {
    switch (state) {
      case IdleModel():
        print('  Inserted \$${amount.toStringAsFixed(2)}.'
            ' Balance: \$${amount.toStringAsFixed(2)}');
        state = HasMoneyState(amount);
      case HasMoneyModel(:final balance):
        final newBalance = balance + amount;
        print('  Added \$${amount.toStringAsFixed(2)}.'
            ' Balance: \$${newBalance.toStringAsFixed(2)}');
        state = HasMoneyState(newBalance);
      case DispensingModel():
        print('  Please wait — dispensing in progress.');
    }
  }

  void selectProduct(String code) {
    switch (state) {
      case IdleModel():
        print('  Please insert coins first.');
      case DispensingModel():
        print('  Please wait — dispensing in progress.');
      case HasMoneyModel(:final balance):
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
      case IdleModel():
        print('  Nothing to cancel.');
      case HasMoneyModel(:final balance):
        print('  Cancelled. Refunding \$${balance.toStringAsFixed(2)}');
        state = const IdleState();
      case DispensingModel():
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
