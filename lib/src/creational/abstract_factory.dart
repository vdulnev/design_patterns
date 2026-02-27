// # Abstract Factory Pattern
//
// Intent: Provide an interface for creating families of related or dependent
// objects without specifying their concrete classes.
//
// When to use:
// - A system must be independent of how its products are created
// - A system should work with multiple families of products
// - Examples: UI toolkits (light/dark theme), cross-platform widgets,
//   database drivers (MySQL/PostgreSQL)
//
// Key points in Dart:
// - Define abstract factory + abstract product interfaces
// - Each concrete factory produces a consistent family of products
// - Client code only depends on abstractions

// ─────────────────────────────────────────────
// Abstract products
// ─────────────────────────────────────────────

abstract class Button {
  void render();
  void onClick();
}

abstract class TextField {
  void render();
  String getValue();
}

abstract class Checkbox {
  void render();
  bool isChecked();
}

// ─────────────────────────────────────────────
// Light theme family
// ─────────────────────────────────────────────

class LightButton implements Button {
  @override
  void render() => print('  [Light] Rendering flat white button');
  @override
  void onClick() => print('  [Light] Button clicked (light ripple)');
}

class LightTextField implements TextField {
  @override
  void render() => print('  [Light] Rendering white input field');
  @override
  String getValue() => 'light_input';
}

class LightCheckbox implements Checkbox {
  final bool _checked = false;
  @override
  void render() => print('  [Light] Rendering □ checkbox');
  @override
  bool isChecked() => _checked;
}

// ─────────────────────────────────────────────
// Dark theme family
// ─────────────────────────────────────────────

class DarkButton implements Button {
  @override
  void render() => print('  [Dark]  Rendering elevated dark button');
  @override
  void onClick() => print('  [Dark]  Button clicked (dark ripple)');
}

class DarkTextField implements TextField {
  @override
  void render() => print('  [Dark]  Rendering dark input field');
  @override
  String getValue() => 'dark_input';
}

class DarkCheckbox implements Checkbox {
  final bool _checked = true;
  @override
  void render() => print('  [Dark]  Rendering ■ checkbox');
  @override
  bool isChecked() => _checked;
}

// ─────────────────────────────────────────────
// Abstract factory
// ─────────────────────────────────────────────

abstract class UIFactory {
  Button createButton();
  TextField createTextField();
  Checkbox createCheckbox();
}

// ─────────────────────────────────────────────
// Concrete factories
// ─────────────────────────────────────────────

class LightThemeFactory implements UIFactory {
  @override
  Button createButton() => LightButton();
  @override
  TextField createTextField() => LightTextField();
  @override
  Checkbox createCheckbox() => LightCheckbox();
}

class DarkThemeFactory implements UIFactory {
  @override
  Button createButton() => DarkButton();
  @override
  TextField createTextField() => DarkTextField();
  @override
  Checkbox createCheckbox() => DarkCheckbox();
}

// ─────────────────────────────────────────────
// Client: doesn't know which factory it uses
// ─────────────────────────────────────────────

class LoginForm {
  final UIFactory _factory;

  late final Button _submitButton;
  late final TextField _usernameField;
  late final TextField _passwordField;
  late final Checkbox _rememberMe;

  LoginForm(this._factory) {
    _submitButton   = _factory.createButton();
    _usernameField  = _factory.createTextField();
    _passwordField  = _factory.createTextField();
    _rememberMe     = _factory.createCheckbox();
  }

  void render() {
    print('  --- Login Form ---');
    _usernameField.render();
    _passwordField.render();
    _rememberMe.render();
    _submitButton.render();
  }

  void submit() => _submitButton.onClick();
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void abstractFactoryExample() {
  print('═' * 50);
  print('ABSTRACT FACTORY PATTERN');
  print('═' * 50);

  for (final factory in [LightThemeFactory(), DarkThemeFactory()]) {
    final theme = factory is LightThemeFactory ? 'Light' : 'Dark';
    print('\n[$theme Theme]');
    final form = LoginForm(factory);
    form.render();
    form.submit();
  }

  print('');
}
