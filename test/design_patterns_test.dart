import 'package:design_patterns/design_patterns.dart';
import 'package:test/test.dart';

void main() {
  group('Singleton', () {
    test('returns the same instance', () {
      expect(identical(Logger.instance, Logger.instance), isTrue);
    });

    test('AppConfig factory returns same instance', () {
      expect(identical(AppConfig(), AppConfig()), isTrue);
    });

    test('shared state across references', () {
      Logger.instance.clear();
      Logger.instance.log('test');
      expect(Logger.instance.history.length, 1);
    });
  });

  group('Builder', () {
    test('builds a valid request', () {
      final req = HttpRequestBuilder()
          .method('POST')
          .url('https://example.com')
          .body('{}')
          .build();
      expect(req.method, 'POST');
      expect(req.url, 'https://example.com');
      expect(req.body, '{}');
    });

    test('throws if URL not set', () {
      expect(() => HttpRequestBuilder().build(), throwsStateError);
    });
  });

  group('Prototype', () {
    test('clone produces independent copy', () {
      final original = Enemy(
        name: 'Goblin',
        health: 30,
        damage: 5,
        position: const Position(0, 0),
        abilities: ['scratch'],
      );
      final clone = original.clone();
      clone.abilities.add('fire');
      expect(original.abilities.length, 1);
      expect(clone.abilities.length, 2);
    });
  });

  group('Composite', () {
    test('directory size equals sum of children', () {
      final dir = Directory('root')
        ..add(const File('a.txt', 100))
        ..add(const File('b.txt', 200));
      expect(dir.sizeBytes, 300);
    });
  });

  group('Observer', () {
    test('observer receives notifications', () {
      final market = StockMarket();
      final received = <String>[];
      market.subscribe(_TestObserver(received));
      market.updatePrice('AAPL', 100);
      market.updatePrice('AAPL', 120);
      expect(received, ['AAPL']);
    });
  });

  group('Command', () {
    test('insert and undo restores content', () {
      final editor = TextEditor();
      editor.execute(InsertTextCommand(editor.document, 0, 'Hello'));
      expect(editor.document.content, 'Hello');
      editor.undo();
      expect(editor.document.content, '');
    });
  });

  group('Iterator', () {
    test('in-order traversal is sorted', () {
      final tree = BinaryTree(
        TreeNode(2, left: TreeNode(1), right: TreeNode(3)),
      );
      expect(tree.toList(), [1, 2, 3]);
    });
  });
}

class _TestObserver implements StockObserver {
  final List<String> received;
  _TestObserver(this.received);

  @override
  void onPriceChanged(String symbol, double oldPrice, double newPrice) {
    received.add(symbol);
  }
}
