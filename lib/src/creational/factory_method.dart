// # Factory Method Pattern
//
// Intent: Define an interface for creating an object, but let subclasses
// decide which class to instantiate. Factory Method lets a class defer
// instantiation to subclasses.
//
// When to use:
// - A class cannot anticipate the type of objects it must create
// - Subclasses should specify the objects they create
// - Examples: UI frameworks, parsers, loggers by type
//
// Key points in Dart:
// - Define an abstract creator with a factory method
// - Concrete creators override the factory method
// - The product interface ensures all products are compatible

// ─────────────────────────────────────────────
// Product interface
// ─────────────────────────────────────────────

abstract class Notification {
  void send(String message);
  String get channel;
}

// ─────────────────────────────────────────────
// Concrete products
// ─────────────────────────────────────────────

class EmailNotification implements Notification {
  final String _recipient;
  EmailNotification(this._recipient);

  @override
  void send(String message) =>
      print('  [Email → $_recipient] $message');

  @override
  String get channel => 'Email';
}

class SmsNotification implements Notification {
  final String _phoneNumber;
  SmsNotification(this._phoneNumber);

  @override
  void send(String message) =>
      print('  [SMS → $_phoneNumber] ${message.substring(0, message.length.clamp(0, 160))}');

  @override
  String get channel => 'SMS';
}

class PushNotification implements Notification {
  final String _deviceToken;
  PushNotification(this._deviceToken);

  @override
  void send(String message) =>
      print('  [Push → ${_deviceToken.substring(0, 8)}...] $message');

  @override
  String get channel => 'Push';
}

// ─────────────────────────────────────────────
// Abstract creator
// ─────────────────────────────────────────────

abstract class NotificationService {
  // Factory method — subclasses override this
  Notification createNotification(String target);

  // Template that uses the factory method
  void notify(String target, String message) {
    final notification = createNotification(target);
    print('Sending via ${notification.channel}...');
    notification.send(message);
  }
}

// ─────────────────────────────────────────────
// Concrete creators
// ─────────────────────────────────────────────

class EmailService extends NotificationService {
  @override
  Notification createNotification(String target) =>
      EmailNotification(target);
}

class SmsService extends NotificationService {
  @override
  Notification createNotification(String target) =>
      SmsNotification(target);
}

class PushService extends NotificationService {
  @override
  Notification createNotification(String target) =>
      PushNotification(target);
}

// ─────────────────────────────────────────────
// Bonus: Static factory method (common Dart variant)
// ─────────────────────────────────────────────

class NotificationFactory {
  static Notification create(String type, String target) {
    return switch (type) {
      'email' => EmailNotification(target),
      'sms'   => SmsNotification(target),
      'push'  => PushNotification(target),
      _       => throw ArgumentError('Unknown notification type: $type'),
    };
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void factoryMethodExample() {
  print('═' * 50);
  print('FACTORY METHOD PATTERN');
  print('═' * 50);

  // Using polymorphic creators
  final services = <NotificationService>[
    EmailService(),
    SmsService(),
    PushService(),
  ];

  final targets = ['user@example.com', '+1234567890', 'abc123token'];

  for (var i = 0; i < services.length; i++) {
    services[i].notify(targets[i], 'Hello! Your order has shipped.');
  }

  print('\nUsing static factory:');
  final n = NotificationFactory.create('email', 'admin@example.com');
  n.send('Server restarted successfully.');

  print('');
}

void main() => factoryMethodExample();
