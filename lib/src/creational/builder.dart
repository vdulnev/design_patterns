// # Builder Pattern
//
// Intent: Separate the construction of a complex object from its
// representation so the same construction process can create different
// representations.
//
// When to use:
// - Construction of a complex object needs many optional parameters
// - You want to avoid "telescoping constructors"
// - The construction steps must be executed in a specific order
// - Examples: QueryBuilder, HTTP request builder, Pizza order, Report
//
// Key points in Dart:
// - Dart's named parameters already reduce the need for Builder in simple cases
// - Builder shines when construction is multi-step or produces different types
// - Inner builder class or a separate Builder class are both common

// ─────────────────────────────────────────────
// Product
// ─────────────────────────────────────────────

class HttpRequest {
  final String method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String? body;
  final Duration timeout;

  HttpRequest._({
    required this.method,
    required this.url,
    required this.headers,
    required this.queryParams,
    this.body,
    required this.timeout,
  });

  @override
  String toString() {
    final params = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final fullUrl = params.isEmpty ? url : '$url?$params';
    return '''
  $method $fullUrl
  Headers: $headers
  Timeout: ${timeout.inSeconds}s
  Body:    ${body ?? '(none)'}''';
  }
}

// ─────────────────────────────────────────────
// Builder
// ─────────────────────────────────────────────

class HttpRequestBuilder {
  String _method = 'GET';
  String _url = '';
  final Map<String, String> _headers = {};
  final Map<String, String> _queryParams = {};
  String? _body;
  Duration _timeout = const Duration(seconds: 30);

  HttpRequestBuilder method(String method) {
    _method = method.toUpperCase();
    return this;
  }

  HttpRequestBuilder url(String url) {
    _url = url;
    return this;
  }

  HttpRequestBuilder header(String key, String value) {
    _headers[key] = value;
    return this;
  }

  HttpRequestBuilder bearer(String token) =>
      header('Authorization', 'Bearer $token');

  HttpRequestBuilder contentJson() =>
      header('Content-Type', 'application/json');

  HttpRequestBuilder param(String key, String value) {
    _queryParams[key] = value;
    return this;
  }

  HttpRequestBuilder body(String body) {
    _body = body;
    return this;
  }

  HttpRequestBuilder timeout(Duration duration) {
    _timeout = duration;
    return this;
  }

  HttpRequest build() {
    if (_url.isEmpty) throw StateError('URL must be set before building');
    return HttpRequest._(
      method: _method,
      url: _url,
      headers: Map.unmodifiable(_headers),
      queryParams: Map.unmodifiable(_queryParams),
      body: _body,
      timeout: _timeout,
    );
  }
}

// ─────────────────────────────────────────────
// Director (optional): encodes common build recipes
// ─────────────────────────────────────────────

class RequestDirector {
  static HttpRequest authGetRequest(String url, String token) =>
      HttpRequestBuilder()
          .method('GET')
          .url(url)
          .bearer(token)
          .timeout(const Duration(seconds: 10))
          .build();

  static HttpRequest jsonPostRequest(String url, String jsonBody) =>
      HttpRequestBuilder()
          .method('POST')
          .url(url)
          .contentJson()
          .body(jsonBody)
          .build();
}

// ─────────────────────────────────────────────
// Example runner
// ─────────────────────────────────────────────

void builderExample() {
  print('═' * 50);
  print('BUILDER PATTERN');
  print('═' * 50);

  // Fluent builder
  final request = HttpRequestBuilder()
      .method('GET')
      .url('https://api.example.com/users')
      .bearer('eyJhbGciOiJIUzI1NiJ9...')
      .param('page', '1')
      .param('limit', '20')
      .timeout(const Duration(seconds: 15))
      .build();

  print('\nCustom GET request:');
  print(request);

  // POST via director
  final post = RequestDirector.jsonPostRequest(
    'https://api.example.com/orders',
    '{"productId": 42, "qty": 3}',
  );

  print('\nDirector POST request:');
  print(post);

  print('');
}
