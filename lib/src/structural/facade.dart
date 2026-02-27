// # Facade Pattern
//
// Intent: Provide a simplified interface to a complex subsystem.
//
// When to use:
// - You want a simple interface to a complex body of code
// - There are many dependencies between clients and implementation details
// - You want to layer your subsystems
// - Examples: Home theater system, compiler frontend, video conversion,
//   e-commerce checkout

// ─────────────────────────────────────────────
// Complex subsystem classes
// ─────────────────────────────────────────────

class InventoryService {
  bool checkStock(String productId, int quantity) {
    print('  [Inventory] Checking stock for $productId × $quantity');
    return true; // assume in stock
  }

  void reserve(String productId, int quantity) {
    print('  [Inventory] Reserved $quantity × $productId');
  }
}

class PricingService {
  double getPrice(String productId) {
    print('  [Pricing] Fetching price for $productId');
    return 29.99;
  }

  double applyDiscount(double price, String? coupon) {
    if (coupon == 'SAVE10') {
      print('  [Pricing] Applying 10% coupon');
      return price * 0.9;
    }
    return price;
  }
}

class TaxService {
  double calculateTax(double amount, String country) {
    print('  [Tax] Calculating tax for $country');
    final rate = country == 'US' ? 0.08 : 0.20;
    return amount * rate;
  }
}

class PaymentProcessor {
  bool charge(String cardToken, double total) {
    print('  [Payment] Charging \$${total.toStringAsFixed(2)} to $cardToken');
    return true;
  }
}

class ShippingService {
  String createShipment(String orderId, String address) {
    print('  [Shipping] Creating shipment for order $orderId → $address');
    return 'TRACK-${orderId.hashCode.abs() % 100000}';
  }
}

class NotificationDispatcher {
  void sendConfirmation(String email, String orderId) {
    print('  [Notify] Sending confirmation to $email for order $orderId');
  }
}

// ─────────────────────────────────────────────
// Order model
// ─────────────────────────────────────────────

class OrderSummary {
  final String orderId;
  final double subtotal;
  final double tax;
  final double total;
  final String trackingNumber;

  const OrderSummary({
    required this.orderId,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.trackingNumber,
  });

  @override
  String toString() => '''
  Order:    $orderId
  Subtotal: \$${subtotal.toStringAsFixed(2)}
  Tax:      \$${tax.toStringAsFixed(2)}
  Total:    \$${total.toStringAsFixed(2)}
  Tracking: $trackingNumber''';
}

// ─────────────────────────────────────────────
// Facade: hides all subsystem complexity
// ─────────────────────────────────────────────

class OrderFacade {
  final _inventory  = InventoryService();
  final _pricing    = PricingService();
  final _tax        = TaxService();
  final _payment    = PaymentProcessor();
  final _shipping   = ShippingService();
  final _notifier   = NotificationDispatcher();

  OrderSummary? placeOrder({
    required String productId,
    required int quantity,
    required String cardToken,
    required String email,
    required String address,
    required String country,
    String? coupon,
  }) {
    print('  --- Starting order pipeline ---');

    // 1. Check stock
    if (!_inventory.checkStock(productId, quantity)) {
      print('  ERROR: Out of stock');
      return null;
    }

    // 2. Calculate price
    final basePrice  = _pricing.getPrice(productId) * quantity;
    final discounted = _pricing.applyDiscount(basePrice, coupon);
    final taxAmount  = _tax.calculateTax(discounted, country);
    final total      = discounted + taxAmount;

    // 3. Charge
    if (!_payment.charge(cardToken, total)) {
      print('  ERROR: Payment failed');
      return null;
    }

    // 4. Reserve & ship
    _inventory.reserve(productId, quantity);
    final orderId  = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    final tracking = _shipping.createShipment(orderId, address);

    // 5. Notify
    _notifier.sendConfirmation(email, orderId);

    return OrderSummary(
      orderId: orderId,
      subtotal: discounted,
      tax: taxAmount,
      total: total,
      trackingNumber: tracking,
    );
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void facadeExample() {
  print('═' * 50);
  print('FACADE PATTERN');
  print('═' * 50);

  print('\nClient calls one method on the facade:');
  final facade = OrderFacade();
  final summary = facade.placeOrder(
    productId: 'DART-BOOK-01',
    quantity: 2,
    cardToken: 'tok_visa_4242',
    email: 'buyer@example.com',
    address: '123 Main St, Springfield',
    country: 'US',
    coupon: 'SAVE10',
  );

  if (summary != null) {
    print('\n  ✓ Order placed successfully!');
    print(summary);
  }

  print('');
}

void main() => facadeExample();
