import 'dart:convert';

import 'package:api_amb_jwt/data/models/product.dart';
import 'package:api_amb_jwt/data/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Product _makeProduct({int id = 1, String title = 'P', double price = 5.0, String desc = 'D'}) {
  return Product(userId: 'u1', id: id, title: title, price: price, description: desc, createdAt: DateTime(2025));
}

void main() {
  group('ProductService', () {
    group('crearProducte', () {
      // Comprova que envia POST amb headers/body correctes i retorna Product (200)
      test('POST correcte retorna Product (200)', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), contains('/products'));
          expect(request.headers['Authorization'], 'Bearer my-token');
          expect(request.headers['apikey'], isNotEmpty);
          expect(request.headers['Content-Type'], 'application/json');
          expect(request.headers['Prefer'], 'return=representation');

          final body = jsonDecode(request.body);
          expect(body['title'], 'New Product');

          return http.Response(
            jsonEncode({
              'id': 10,
              'user_id': 'u1',
              'title': 'New Product',
              'price': 25.0,
              'description': 'Desc',
              'created_at': '2025-01-01T00:00:00Z',
            }),
            200,
          );
        });

        final service = ProductService(client: mockClient);
        final product = _makeProduct(id: 0, title: 'New Product', price: 25.0, desc: 'Desc');
        final result = await service.crearProducte('my-token', product);

        expect(result.id, 10);
        expect(result.title, 'New Product');
        expect(result.price, 25.0);
      });

      // Llanca excepcio si la resposta no es 200
      test('error en resposta no-200', () async {
        final mockClient = MockClient((_) async => http.Response('Error', 500));

        final service = ProductService(client: mockClient);

        expect(
          () => service.crearProducte('tok', _makeProduct()),
          throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('Failed to create product'))),
        );
      });
    });

    group('getProducts', () {
      // Comprova que envia GET amb headers correctes i retorna llista (200)
      test('GET correcte retorna llista (200)', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), contains('/products?select=*'));
          expect(request.headers['Authorization'], 'Bearer my-token');
          expect(request.headers['apikey'], isNotEmpty);

          return http.Response(
            jsonEncode([
              {'id': 1, 'user_id': 'u1', 'title': 'A', 'price': 10, 'description': 'DA', 'created_at': '2025-01-01T00:00:00Z'},
              {'id': 2, 'user_id': 'u2', 'title': 'B', 'price': 20, 'description': 'DB', 'created_at': '2025-02-01T00:00:00Z'},
            ]),
            200,
          );
        });

        final service = ProductService(client: mockClient);
        final products = await service.getProducts('my-token');

        expect(products.length, 2);
        expect(products[0].title, 'A');
        expect(products[1].title, 'B');
      });

      // Llanca excepcio si la resposta no es 200
      test('error en resposta no-200', () async {
        final mockClient = MockClient((_) async => http.Response('Unauthorized', 401));

        final service = ProductService(client: mockClient);

        expect(
          () => service.getProducts('bad-token'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('Failed to load products'))),
        );
      });
    });

    group('eliminarProducte', () {
      // Comprova DELETE amb URL i headers correctes, exit en 200 i 204
      test('DELETE correcte exit 200 i 204', () async {
        // Test 200
        var mockClient = MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.toString(), contains('/products?id=eq.42'));
          expect(request.headers['Authorization'], 'Bearer my-token');
          expect(request.headers['apikey'], isNotEmpty);
          return http.Response('', 200);
        });

        var service = ProductService(client: mockClient);
        await service.eliminarProducte('my-token', 42);

        // Test 204
        mockClient = MockClient((_) async => http.Response('', 204));
        service = ProductService(client: mockClient);
        await service.eliminarProducte('my-token', 1);
      });

      // Llanca excepcio en resposta d'error
      test('error en resposta DELETE', () async {
        final mockClient = MockClient((_) async => http.Response('Forbidden', 403));

        final service = ProductService(client: mockClient);

        expect(
          () => service.eliminarProducte('tok', 1),
          throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('Failed to delete product'))),
        );
      });
    });
  });
}
