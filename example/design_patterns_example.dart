import 'package:design_patterns/design_patterns.dart';

// ═══════════════════════════════════════════════════════════════
//  Dart Design Patterns Course — Interactive Runner
// ═══════════════════════════════════════════════════════════════
//
//  Run:  dart run example/design_patterns_example.dart
//  Run a single pattern:
//        dart run example/design_patterns_example.dart singleton
//
// Available patterns:
//   Creational : singleton, factory, abstract_factory, builder, prototype
//   Structural : adapter, decorator, facade, proxy, composite
//   Behavioral : observer, strategy, command, state, template, iterator, chain

Future<void> main(List<String> args) async {
  final filter = args.isNotEmpty ? args.first.toLowerCase() : null;

  final patterns = <String, Future<void> Function()>{
    // ── Creational ───────────────────────────────────────────
    'singleton':        () async => singletonExample(),
    'factory':          () async => factoryMethodExample(),
    'abstract_factory': () async => abstractFactoryExample(),
    'builder':          () async => builderExample(),
    'prototype':        () async => prototypeExample(),

    // ── Structural ───────────────────────────────────────────
    'adapter':          () async => await adapterExample(),
    'decorator':        () async => decoratorExample(),
    'facade':           () async => facadeExample(),
    'proxy':            () async => proxyExample(),
    'composite':        () async => compositeExample(),

    // ── Behavioral ───────────────────────────────────────────
    'observer':         () async => observerExample(),
    'strategy':         () async => strategyExample(),
    'command':          () async => commandExample(),
    'state':            () async => stateExample(),
    'template':         () async => templateMethodExample(),
    'iterator':         () async => iteratorExample(),
    'chain':            () async => chainOfResponsibilityExample(),
  };

  if (filter != null) {
    final fn = patterns[filter];
    if (fn == null) {
      print('Unknown pattern: "$filter"');
      print('Available: ${patterns.keys.join(', ')}');
      return;
    }
    await fn();
    return;
  }

  // Run all patterns grouped by category
  _header('CREATIONAL PATTERNS');
  for (final key in ['singleton', 'factory', 'abstract_factory', 'builder', 'prototype']) {
    await patterns[key]!();
  }

  _header('STRUCTURAL PATTERNS');
  for (final key in ['adapter', 'decorator', 'facade', 'proxy', 'composite']) {
    await patterns[key]!();
  }

  _header('BEHAVIORAL PATTERNS');
  for (final key in ['observer', 'strategy', 'command', 'state', 'template', 'iterator', 'chain']) {
    await patterns[key]!();
  }

  print('Done! All 17 design patterns demonstrated.');
}

void _header(String title) {
  print('\n');
  print('█' * 55);
  print('  $title');
  print('█' * 55);
}
