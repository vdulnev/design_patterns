// # Chain of Responsibility Pattern
//
// Intent: Avoid coupling the sender of a request to its receiver by giving
// more than one object a chance to handle the request. Chain the receiving
// objects and pass the request along the chain until an object handles it.
//
// When to use:
// - More than one object may handle a request, and the handler isn't known
// - You want to issue a request to one of several objects without specifying
//   the receiver explicitly
// - The set of objects that can handle a request should be specified dynamically
// - Examples: HTTP middleware, support ticket escalation, logging levels,
//   UI event propagation, auth/validation pipelines
//
// Key points in Dart:
// - Each handler has a final reference to the next handler (successor)
// - Successor is injected via the constructor — immutable after creation
// - A handler either handles the request or passes it to the next

// ─────────────────────────────────────────────
// Example 1: HTTP Middleware pipeline
// ─────────────────────────────────────────────

class HttpContext {
  final String path;
  final String method;
  final Map<String, String> headers;
  bool handled = false;
  int statusCode = 200;
  String body = '';

  HttpContext({
    required this.path,
    required this.method,
    this.headers = const {},
  });

  @override
  String toString() => '$method $path → $statusCode: $body';
}

abstract class Middleware {
  final Middleware? _next;

  const Middleware([this._next]);

  void handle(HttpContext ctx) {
    _next?.handle(ctx);
  }
}

class RateLimiterMiddleware extends Middleware {
  final int maxRequests;
  int _count = 0;

  RateLimiterMiddleware({this.maxRequests = 5, Middleware? next}) : super(next);

  @override
  void handle(HttpContext ctx) {
    _count++;
    if (_count > maxRequests) {
      ctx.statusCode = 429;
      ctx.body = 'Too Many Requests';
      ctx.handled = true;
      print('  [RateLimit] Request #$_count blocked (429)');
      return;
    }
    print('  [RateLimit] OK — request #$_count of $maxRequests');
    super.handle(ctx);
  }
}

class AuthMiddleware extends Middleware {
  final List<String> _validTokens;

  AuthMiddleware(this._validTokens, {Middleware? next}) : super(next);

  @override
  void handle(HttpContext ctx) {
    final token = ctx.headers['Authorization'];
    if (token == null || !_validTokens.contains(token)) {
      ctx.statusCode = 401;
      ctx.body = 'Unauthorized';
      ctx.handled = true;
      print('  [Auth] Rejected — missing or invalid token (401)');
      return;
    }
    print('  [Auth] Token valid — proceeding');
    super.handle(ctx);
  }
}

class LoggingMiddleware extends Middleware {
  const LoggingMiddleware({Middleware? next}) : super(next);

  @override
  void handle(HttpContext ctx) {
    print('  [Log] → ${ctx.method} ${ctx.path}');
    super.handle(ctx);
    print('  [Log] ← ${ctx.statusCode}');
  }
}

class RouterMiddleware extends Middleware {
  const RouterMiddleware() : super(null);

  @override
  void handle(HttpContext ctx) {
    ctx.body = switch (ctx.path) {
      '/health' => 'OK',
      '/users'  => '[{"id":1,"name":"Alice"}]',
      _         => (() { ctx.statusCode = 404; return 'Not Found'; })(),
    };
    ctx.handled = true;
    print('  [Router] Handled ${ctx.path} → ${ctx.statusCode}');
  }
}

// ─────────────────────────────────────────────
// Example 2: Support ticket escalation
// ─────────────────────────────────────────────

class SupportTicket {
  final String issue;
  final int priority; // 1=low, 2=medium, 3=high, 4=critical
  SupportTicket(this.issue, this.priority);
}

abstract class SupportHandler {
  final SupportHandler? _next;

  const SupportHandler([this._next]);

  void handle(SupportTicket ticket);

  void escalate(SupportTicket ticket) {
    if (_next != null) {
      _next.handle(ticket);
    } else {
      print('  [$runtimeType] No handler available — ticket dropped: "${ticket.issue}"');
    }
  }
}

class Level1Support extends SupportHandler {
  const Level1Support([super.next]);

  @override
  void handle(SupportTicket ticket) {
    if (ticket.priority <= 1) {
      print('  [L1 Support] Resolved: "${ticket.issue}"');
    } else {
      print('  [L1 Support] Escalating priority=${ticket.priority} ticket...');
      escalate(ticket);
    }
  }
}

class Level2Support extends SupportHandler {
  const Level2Support([super.next]);

  @override
  void handle(SupportTicket ticket) {
    if (ticket.priority <= 2) {
      print('  [L2 Support] Resolved: "${ticket.issue}"');
    } else {
      print('  [L2 Support] Escalating priority=${ticket.priority} ticket...');
      escalate(ticket);
    }
  }
}

class EngineeringTeam extends SupportHandler {
  const EngineeringTeam([super.next]);

  @override
  void handle(SupportTicket ticket) {
    if (ticket.priority <= 3) {
      print('  [Engineering] Resolved: "${ticket.issue}"');
    } else {
      print('  [Engineering] Escalating critical ticket to CTO...');
      escalate(ticket);
    }
  }
}

class CTO extends SupportHandler {
  const CTO() : super(null);

  @override
  void handle(SupportTicket ticket) {
    print('  [CTO] Personally handling critical issue: "${ticket.issue}"');
  }
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void chainOfResponsibilityExample() {
  print('═' * 50);
  print('CHAIN OF RESPONSIBILITY PATTERN');
  print('═' * 50);

  // Build middleware chain via constructor injection (inside-out)
  final chain = RateLimiterMiddleware(
    maxRequests: 2,
    next: LoggingMiddleware(
      next: AuthMiddleware(
        ['Bearer token123', 'Bearer admin456'],
        next: const RouterMiddleware(),
      ),
    ),
  );

  void request(String method, String path, {String? token}) {
    print('\n${'-' * 35}');
    final ctx = HttpContext(
      method: method,
      path: path,
      headers: token != null ? {'Authorization': token} : {},
    );
    chain.handle(ctx);
    print('  Result: $ctx');
  }

  print('\n[Middleware Chain]');
  request('GET', '/health', token: 'Bearer token123');
  request('GET', '/users');           // no token → 401
  request('GET', '/users', token: 'Bearer token123'); // rate limit hit

  // Support ticket chain — also constructed inside-out
  print('\n[Support Escalation Chain]');
  const l1 = Level1Support(
    Level2Support(
      EngineeringTeam(
        CTO(),
      ),
    ),
  );

  final tickets = [
    SupportTicket('Password reset', 1),
    SupportTicket('App crashes on login', 2),
    SupportTicket('Data loss in production', 3),
    SupportTicket('Security breach — all systems down', 4),
  ];

  for (final ticket in tickets) {
    print('\n  Ticket: "${ticket.issue}" (priority=${ticket.priority})');
    l1.handle(ticket);
  }

  print('');
}

void main() => chainOfResponsibilityExample();
