import 'package:api_amb_jwt/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    test('Constructor crea User', () {
      final user = User(email: 'hello@world.com', password: 'p@ss', authenticated: false, accessToken: 'tok');

      expect(user.email, 'hello@world.com');
      expect(user.password, 'p@ss');
      expect(user.authenticated, isFalse);
      expect(user.accessToken, 'tok');
    });

    test('Convertir JSON en Supabase', () {
      final user = User.fromJson({
        'access_token': 'my-jwt-token',
        'user': {'email': 'test@example.com', 'id': 'some-uuid'},
      });
      expect(user.email, 'test@example.com');
      expect(user.password, '');
      expect(user.authenticated, isTrue);
      expect(user.accessToken, 'my-jwt-token');

      // Missing email in user object
      final noEmail = User.fromJson({'access_token': 'token-123', 'user': <String, dynamic>{}});
      expect(noEmail.email, '');
      expect(noEmail.authenticated, isTrue);

      // Format Supabase
      final priority = User.fromJson({
        'access_token': 'supabase-token',
        'user': {'email': 'supabase@test.com'},
        'email': 'other@test.com',
        'password': 'pass',
        'accessToken': 'other-token',
      });
      expect(priority.email, 'supabase@test.com');
      expect(priority.accessToken, 'supabase-token');
      expect(priority.password, '');
    });

    test('Conversio JSON a Supabase (email, password, accesToken)', () {
      final user = User.fromJson({'email': 'user@test.com', 'password': 'secret123', 'accessToken': 'alt-token'});

      expect(user.email, 'user@test.com');
      expect(user.password, 'secret123');
      expect(user.authenticated, isTrue);
      expect(user.accessToken, 'alt-token');
    });

    test('Estructura incorrecta JSON', () {
      expect(() => User.fromJson({'email': 'user@test.com'}), throwsA(isA<FormatException>()));
      expect(() => User.fromJson(<String, dynamic>{}), throwsA(isA<FormatException>()));
      expect(() => User.fromJson({'email': 'test@test.com', 'password': 'pass'}), throwsA(isA<FormatException>()));
    });
  });
}
