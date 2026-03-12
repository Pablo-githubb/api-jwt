import 'package:api_amb_jwt/data/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product', () {
    group('fromJson', () {
      test('registra JSON CORRECTAMENT', () {
        final product = Product.fromJson({
          'user_id': 'abc-123',
          'id': 42,
          'title': 'Test Product',
          'price': 19.99,
          'description': 'A test product',
          'created_at': '2025-01-15T10:30:00Z',
        });

        expect(product.userId, 'abc-123');
        expect(product.id, 42);
        expect(product.title, 'Test Product');
        expect(product.price, 19.99);
        expect(product.description, 'A test product');
        expect(product.createdAt, DateTime.parse('2025-01-15T10:30:00Z'));
      });

      test('fica valor per defecte en nulls/string buida', () {
        // Json buid -> a Default
        final empty = Product.fromJson(<String, dynamic>{});
        expect(empty.userId, '');
        expect(empty.id, 0);
        expect(empty.title, '');
        expect(empty.price, 0.0);
        expect(empty.description, '');
        expect(empty.createdAt.difference(DateTime.now()).inSeconds.abs(), lessThan(2));

        // Null en creat -> DateTime.now()
        final nullDate = Product.fromJson({'created_at': null});
        expect(nullDate.createdAt.difference(DateTime.now()).inSeconds.abs(), lessThan(2));

        // Número user_id -> convertit a String
        expect(Product.fromJson({'user_id': 12345, 'created_at': '2025-06-01T00:00:00Z'}).userId, '12345');

        // Null user_id -> convertit en String buida
        expect(Product.fromJson({'user_id': null, 'created_at': '2025-06-01T00:00:00Z'}).userId, '');

        // Integer preu -> Double preu
        expect(Product.fromJson({'price': 10, 'created_at': '2025-06-01T00:00:00Z'}).price, 10.0);

        // Null price -> 0.0
        expect(Product.fromJson({'price': null, 'created_at': '2025-06-01T00:00:00Z'}).price, 0.0);
      });
    });

    group('toJson', () {
      test('comprovar userId valid', () {
        // Tots els camps válids
        final full = Product(userId: 'user-1', id: 5, title: 'Widget', price: 29.99, description: 'Desc', createdAt: DateTime(2025));
        final fullJson = full.toJson();
        expect(fullJson['title'], 'Widget');
        expect(fullJson['price'], 29.99);
        expect(fullJson['description'], 'Desc');
        expect(fullJson['user_id'], 'user-1');
        expect(fullJson['id'], 5);

        // Buit userId
        final noUser = Product(userId: '', id: 5, title: 'W', price: 1.0, description: 'D', createdAt: DateTime(2025));
        expect(noUser.toJson().containsKey('user_id'), isFalse);
        expect(noUser.toJson()['id'], 5);

        // 0 id
        final noId = Product(userId: 'user-1', id: 0, title: 'W', price: 1.0, description: 'D', createdAt: DateTime(2025));
        expect(noId.toJson().containsKey('id'), isFalse);
        expect(noId.toJson()['user_id'], 'user-1');

        // Buid/0 id
        final minimal = Product(userId: '', id: 0, title: 'Min', price: 0.0, description: '', createdAt: DateTime(2025));
        final minJson = minimal.toJson();
        expect(minJson.containsKey('user_id'), isFalse);
        expect(minJson.containsKey('id'), isFalse);
        expect(minJson['title'], 'Min');
      });
    });
  });
}
