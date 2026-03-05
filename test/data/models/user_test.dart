import 'package:api_amb_jwt/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    group('fromJson', () {
      test('parses Supabase auth response with access_token and user', () {
        final json = {
          'access_token': 'my-jwt-token',
          'user': {
            'email': 'test@example.com',
            'id': 'some-uuid',
          },
        };

        final user = User.fromJson(json);

        expect(user.email, 'test@example.com');
        expect(user.password, '');
        expect(user.authenticated, isTrue);
        expect(user.accessToken, 'my-jwt-token');
      });

      test('parses Supabase auth response with missing email in user', () {
        final json = {
          'access_token': 'token-123',
          'user': <String, dynamic>{},
        };

        final user = User.fromJson(json);

        expect(user.email, '');
        expect(user.authenticated, isTrue);
        expect(user.accessToken, 'token-123');
      });

      test('parses alternative JSON format with email, password, accessToken',
          () {
        final json = {
          'email': 'user@test.com',
          'password': 'secret123',
          'accessToken': 'alt-token',
        };

        final user = User.fromJson(json);

        expect(user.email, 'user@test.com');
        expect(user.password, 'secret123');
        expect(user.authenticated, isTrue);
        expect(user.accessToken, 'alt-token');
      });

      test('throws FormatException for invalid JSON structure', () {
        final json = {
          'email': 'user@test.com',
          // Missing password and accessToken
        };

        expect(
          () => User.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException for empty JSON', () {
        final json = <String, dynamic>{};

        expect(
          () => User.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException when only email and password present', () {
        final json = {
          'email': 'test@test.com',
          'password': 'pass',
        };

        expect(
          () => User.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });

      test('Supabase format takes priority when both access_token and user exist', () {
        final json = {
          'access_token': 'supabase-token',
          'user': {'email': 'supabase@test.com'},
          'email': 'other@test.com',
          'password': 'pass',
          'accessToken': 'other-token',
        };

        final user = User.fromJson(json);

        // Should use Supabase format
        expect(user.email, 'supabase@test.com');
        expect(user.accessToken, 'supabase-token');
        expect(user.password, '');
      });
    });

    test('constructor creates User with all fields', () {
      final user = User(
        email: 'hello@world.com',
        password: 'p@ss',
        authenticated: false,
        accessToken: 'tok',
      );

      expect(user.email, 'hello@world.com');
      expect(user.password, 'p@ss');
      expect(user.authenticated, isFalse);
      expect(user.accessToken, 'tok');
    });
  });
}
