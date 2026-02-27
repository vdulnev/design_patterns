// # Adapter Pattern
//
// Intent: Convert the interface of a class into another interface that clients
// expect. Adapter lets classes work together that couldn't otherwise because of
// incompatible interfaces.
//
// When to use:
// - You want to use an existing class but its interface doesn't match
// - You need to create a reusable class that cooperates with unrelated classes
// - Examples: Third-party library integration, legacy code reuse,
//   XML-to-JSON bridge, payment gateway wrappers
//
// Key points in Dart:
// - Object adapter (composition) is preferred over class adapter (inheritance)
// - The adapter holds a reference to the adaptee and translates calls

// ─────────────────────────────────────────────
// Target interface (what the client expects)
// ─────────────────────────────────────────────

abstract class PaymentGateway {
  Future<PaymentResult> charge({
    required String currency,
    required double amount,
    required String cardToken,
  });
}

class PaymentResult {
  final bool success;
  final String transactionId;
  final String? error;

  PaymentResult.ok(this.transactionId)
      : success = true,
        error = null;

  PaymentResult.fail(this.error)
      : success = false,
        transactionId = '';

  @override
  String toString() => success
      ? 'OK  txn=${transactionId.substring(0, 8)}...'
      : 'ERR $error';
}

// ─────────────────────────────────────────────
// Adaptee 1: Legacy Stripe-style SDK
// (incompatible interface — cannot change)
// ─────────────────────────────────────────────

class LegacyStripeSDK {
  Map<String, dynamic> createCharge({
    required int amountCents,   // takes cents, not dollars
    required String curr,       // abbreviated param names
    required String tok,
  }) {
    // Simulate API call
    final success = tok.isNotEmpty;
    return {
      'id': 'ch_${DateTime.now().millisecondsSinceEpoch}',
      'status': success ? 'succeeded' : 'failed',
      'amount': amountCents,
    };
  }
}

// ─────────────────────────────────────────────
// Adapter 1: wraps LegacyStripeSDK
// ─────────────────────────────────────────────

class StripeAdapter implements PaymentGateway {
  final LegacyStripeSDK _sdk;
  StripeAdapter(this._sdk);

  @override
  Future<PaymentResult> charge({
    required String currency,
    required double amount,
    required String cardToken,
  }) async {
    final response = _sdk.createCharge(
      amountCents: (amount * 100).round(), // translate dollars → cents
      curr: currency,
      tok: cardToken,
    );

    if (response['status'] == 'succeeded') {
      return PaymentResult.ok(response['id'] as String);
    }
    return PaymentResult.fail('Stripe charge failed');
  }
}

// ─────────────────────────────────────────────
// Adaptee 2: PayPal REST SDK (different shape)
// ─────────────────────────────────────────────

class PayPalRestClient {
  String executePayment(String json) {
    // Simulate parsing & execution
    return 'PAYPAL-${DateTime.now().millisecondsSinceEpoch}';
  }
}

// ─────────────────────────────────────────────
// Adapter 2: wraps PayPalRestClient
// ─────────────────────────────────────────────

class PayPalAdapter implements PaymentGateway {
  final PayPalRestClient _client;
  PayPalAdapter(this._client);

  @override
  Future<PaymentResult> charge({
    required String currency,
    required double amount,
    required String cardToken,
  }) async {
    final json =
        '{"amount":$amount,"currency":"$currency","token":"$cardToken"}';
    final txId = _client.executePayment(json);
    return PaymentResult.ok(txId);
  }
}

// ─────────────────────────────────────────────
// Client: works with any PaymentGateway
// ─────────────────────────────────────────────

class CheckoutService {
  final PaymentGateway _gateway;
  CheckoutService(this._gateway);

  Future<void> processOrder(double total) async {
    print('  Processing \$${total.toStringAsFixed(2)} via gateway...');
    final result = await _gateway.charge(
      currency: 'USD',
      amount: total,
      cardToken: 'tok_test_visa_4242',
    );
    print('  Result: $result');
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

Future<void> adapterExample() async {
  print('═' * 50);
  print('ADAPTER PATTERN');
  print('═' * 50);

  print('\n[Stripe adapter]');
  final stripe = CheckoutService(StripeAdapter(LegacyStripeSDK()));
  await stripe.processOrder(49.99);

  print('\n[PayPal adapter]');
  final paypal = CheckoutService(PayPalAdapter(PayPalRestClient()));
  await paypal.processOrder(99.00);

  print('');
}
