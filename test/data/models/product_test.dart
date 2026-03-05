import 'package:api_amb_jwt/data/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product', () {
    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'user_id': 'abc-123',
          'id': 42,
          'title': 'Test Product',
          'price': 19.99,
          'description': 'A test product',
          'created_at': '2025-01-15T10:30:00Z',
        };

        final product = Product.fromJson(json);

        expect(product.userId, 'abc-123');
        expect(product.id, 42);
        expect(product.title, 'Test Product');
        expect(product.price, 19.99);
        expect(product.description, 'A test product');
        expect(product.createdAt, DateTime.parse('2025-01-15T10:30:00Z'));
      });

      test('uses default values for missing fields', () {
        final json = <String, dynamic>{};

        final product = Product.fromJson(json);

        expect(product.userId, '');
        expect(product.id, 0);
        expect(product.title, '');
        expect(product.price, 0.0);
        expect(product.description, '');
        // createdAt should be close to now since created_at is null
        expect(
          product.createdAt.difference(DateTime.now()).inSeconds.abs(),
          lessThan(2),
        );
      });

      test('handles null created_at by using DateTime.now()', () {
        final json = {
          'title': 'No Date',
          'created_at': null,
        };

        final product = Product.fromJson(json);

        expect(
          product.createdAt.difference(DateTime.now()).inSeconds.abs(),
          lessThan(2),
        );
      });

      test('handles numeric user_id by converting to string', () {
        final json = {
          'user_id': 12345,
          'title': 'Numeric ID',
          'created_at': '2025-06-01T00:00:00Z',
        };

        final product = Product.fromJson(json);

        expect(product.userId, '12345');
      });

      test('handles integer price as num', () {
        final json = {
          'price': 10,
          'created_at': '2025-06-01T00:00:00Z',
        };

        final product = Product.fromJson(json);

        expect(product.price, 10.0);
      });

      test('handles null price', () {
        final json = {
          'price': null,
          'created_at': '2025-06-01T00:00:00Z',
        };

        final product = Product.fromJson(json);

        expect(product.price, 0.0);
      });

      test('handles null user_id', () {
        final json = {
          'user_id': null,
          'created_at': '2025-06-01T00:00:00Z',
        };

        final product = Product.fromJson(json);

        expect(product.userId, '');
      });
    });

    group('toJson', () {
      test('includes all fields when userId and id are valid', () {
        final product = Product(
          userId: 'user-1',
          id: 5,
          title: 'Widget',
          price: 29.99,
          description: 'A useful widget',
          createdAt: DateTime(2025, 1, 1),
        );

        final json = product.toJson();

        expect(json['title'], 'Widget');
        expect(json['price'], 29.99);
        expect(json['description'], 'A useful widget');
        expect(json['user_id'], 'user-1');
        expect(json['id'], 5);
      });

      test('excludes user_id when userId is empty', () {
        final product = Product(
          userId: '',
          id: 5,
          title: 'Widget',
          price: 29.99,
          description: 'A useful widget',
          createdAt: DateTime(2025, 1, 1),
        );

        final json = product.toJson();

        expect(json.containsKey('user_id'), isFalse);
        expect(json['id'], 5);
      });

      test('excludes id when id is 0', () {
        final product = Product(
          userId: 'user-1',
          id: 0,
          title: 'Widget',
          price: 29.99,
          description: 'A useful widget',
          createdAt: DateTime(2025, 1, 1),
        );

        final json = product.toJson();

        expect(json.containsKey('id'), isFalse);
        expect(json['user_id'], 'user-1');
      });

      test('excludes both user_id and id when empty/zero', () {
        final product = Product(
          userId: '',
          id: 0,
          title: 'Minimal',
          price: 0.0,
          description: '',
          createdAt: DateTime(2025, 1, 1),
        );

        final json = product.toJson();

        expect(json.containsKey('user_id'), isFalse);
        expect(json.containsKey('id'), isFalse);
        expect(json['title'], 'Minimal');
        expect(json['price'], 0.0);
        expect(json['description'], '');
      });
    });
  });
}
