import 'dart:convert';

import 'package:api_amb_jwt/data/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  // Comprova que retorna User amb login correcte (codi 200)
  test('login correcte retorna User (200)', () async {
    final mockClient = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), contains('token?grant_type=password'));
      expect(request.headers['Content-Type'], 'application/json');
      expect(request.headers['apikey'], isNotEmpty);

      final body = jsonDecode(request.body);
      expect(body['email'], 'test@test.com');
      expect(body['password'], 'pass123');

      return http.Response(
        jsonEncode({
          'access_token': 'jwt-token',
          'user': {'email': 'test@test.com'},
        }),
        200,
      );
    });

    final service = UserService(client: mockClient);
    final user = await service.validateLogin('test@test.com', 'pass123');

    expect(user.email, 'test@test.com');
    expect(user.accessToken, 'jwt-token');
    expect(user.authenticated, isTrue);
  });

  // Comprova que llança excepció amb missatge quan credencials invàlides (400)
  test('credencials invàlides llança error (400)', () async {
    final mockClient = MockClient((_) async {
      return http.Response(
        jsonEncode({'message': 'Invalid login credentials'}),
        400,
      );
    });

    final service = UserService(client: mockClient);

    expect(
      () => service.validateLogin('bad@test.com', 'wrong'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid login credentials'),
        ),
      ),
    );
  });

  // Comprova que llança excepció genèrica en errors del servidor (500)
  test('error servidor llança excepció (500)', () async {
    final mockClient = MockClient((_) async {
      return http.Response('Server error', 500);
    });

    final service = UserService(client: mockClient);

    expect(
      () => service.validateLogin('test@test.com', 'pass'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Login error'),
        ),
      ),
    );
  });
}
