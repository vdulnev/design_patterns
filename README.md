# Dart Design Patterns Course

A complete, runnable course covering **17 of the most popular Gang-of-Four design patterns** implemented in idiomatic Dart 3.

## Patterns covered

### Creational
| Pattern | File | Real-world example |
|---------|------|--------------------|
| Singleton | `lib/src/creational/singleton.dart` | Logger, AppConfig |
| Factory Method | `lib/src/creational/factory_method.dart` | Notification channels (Email/SMS/Push) |
| Abstract Factory | `lib/src/creational/abstract_factory.dart` | Light/Dark UI theme families |
| Builder | `lib/src/creational/builder.dart` | Fluent HTTP request builder |
| Prototype | `lib/src/creational/prototype.dart` | Game enemy spawner with registry |

### Structural
| Pattern | File | Real-world example |
|---------|------|--------------------|
| Adapter | `lib/src/structural/adapter.dart` | Stripe & PayPal payment gateway wrappers |
| Decorator | `lib/src/structural/decorator.dart` | Stackable file encryption + compression + logging |
| Facade | `lib/src/structural/facade.dart` | E-commerce order pipeline |
| Proxy | `lib/src/structural/proxy.dart` | Lazy image, caching DB, protection proxy |
| Composite | `lib/src/structural/composite.dart` | File system tree, arithmetic expression tree |

### Behavioral
| Pattern | File | Real-world example |
|---------|------|--------------------|
| Observer | `lib/src/behavioral/observer.dart` | Stock market price alerts |
| Strategy | `lib/src/behavioral/strategy.dart` | Swappable sort algorithms, discount strategies |
| Command | `lib/src/behavioral/command.dart` | Text editor with undo/redo |
| State | `lib/src/behavioral/state.dart` | Vending machine lifecycle |
| Template Method | `lib/src/behavioral/template_method.dart` | CSV/JSON/DB data miners |
| Iterator | `lib/src/behavioral/iterator.dart` | Binary tree traversal, paginated API |
| Chain of Responsibility | `lib/src/behavioral/chain_of_responsibility.dart` | HTTP middleware, support escalation |

## Running the examples

```bash
# Run all 17 patterns
dart run example/design_patterns_example.dart

# Run a single pattern
dart run example/design_patterns_example.dart singleton
dart run example/design_patterns_example.dart factory
dart run example/design_patterns_example.dart abstract_factory
dart run example/design_patterns_example.dart builder
dart run example/design_patterns_example.dart prototype
dart run example/design_patterns_example.dart adapter
dart run example/design_patterns_example.dart decorator
dart run example/design_patterns_example.dart facade
dart run example/design_patterns_example.dart proxy
dart run example/design_patterns_example.dart composite
dart run example/design_patterns_example.dart observer
dart run example/design_patterns_example.dart strategy
dart run example/design_patterns_example.dart command
dart run example/design_patterns_example.dart state
dart run example/design_patterns_example.dart template
dart run example/design_patterns_example.dart iterator
dart run example/design_patterns_example.dart chain
```

## Project structure

```
lib/
  src/
    creational/
      singleton.dart
      factory_method.dart
      abstract_factory.dart
      builder.dart
      prototype.dart
    structural/
      adapter.dart
      decorator.dart
      facade.dart
      proxy.dart
      composite.dart
    behavioral/
      observer.dart
      strategy.dart
      command.dart
      state.dart
      template_method.dart
      iterator.dart
      chain_of_responsibility.dart
example/
  design_patterns_example.dart   ← entry point
```

## What each file contains

Every pattern file follows the same structure:
1. **Header comment** — intent, when to use, Dart-specific notes
2. **Interface / abstract class** definitions
3. **Concrete implementations** with realistic examples
4. **`*Example()` function** — runnable demo with printed output

## Requirements

- Dart SDK ≥ 3.0
