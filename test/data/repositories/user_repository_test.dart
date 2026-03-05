import 'package:api_amb_jwt/data/models/user.dart';
import 'package:api_amb_jwt/data/repositories/user_repository.dart';
import 'package:api_amb_jwt/data/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock manual de IUserService
class MockUserService implements IUserService {
  User? userToReturn;
  Exception? exceptionToThrow;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<User> validateLogin(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return userToReturn!;
  }
}

void main() {
  late MockUserService mockUserService;
  late UserRepository userRepository;

  setUp(() {
    mockUserService = MockUserService();
    userRepository = UserRepository(userService: mockUserService);
  });

  group('UserRepository', () {
    group('authenticated', () {
      test('returns false when no user is logged in', () {
        expect(userRepository.authenticated, isFalse);
      });

      test('returns true after successful login', () async {
        mockUserService.userToReturn = User(
          email: 'test@test.com',
          password: '',
          authenticated: true,
          accessToken: 'token',
        );

        await userRepository.validateLogin('test@test.com', 'pass');

        expect(userRepository.authenticated, isTrue);
      });

      test('returns false when user authenticated flag is false', () async {
        mockUserService.userToReturn = User(
          email: 'test@test.com',
          password: '',
          authenticated: false,
          accessToken: 'token',
        );

        await userRepository.validateLogin('test@test.com', 'pass');

        expect(userRepository.authenticated, isFalse);
      });
    });

    group('email', () {
      test('throws Exception when no user is authenticated', () {
        expect(
          () => userRepository.email,
          throwsA(isA<Exception>()),
        );
      });

      test('returns User object after successful login', () async {
        final user = User(
          email: 'john@example.com',
          password: '',
          authenticated: true,
          accessToken: 'my-token',
        );
        mockUserService.userToReturn = user;

        await userRepository.validateLogin('john@example.com', 'pass');

        final result = userRepository.email;
        expect(result.email, 'john@example.com');
        expect(result.accessToken, 'my-token');
      });
    });

    group('validateLogin', () {
      test('delegates to userService with correct credentials', () async {
        mockUserService.userToReturn = User(
          email: 'a@b.com',
          password: '',
          authenticated: true,
          accessToken: 'tok',
        );

        await userRepository.validateLogin('a@b.com', 'mypassword');

        expect(mockUserService.lastEmail, 'a@b.com');
        expect(mockUserService.lastPassword, 'mypassword');
      });

      test('returns User on success', () async {
        mockUserService.userToReturn = User(
          email: 'a@b.com',
          password: '',
          authenticated: true,
          accessToken: 'tok',
        );

        final result =
            await userRepository.validateLogin('a@b.com', 'mypassword');

        expect(result.email, 'a@b.com');
        expect(result.accessToken, 'tok');
      });

      test('throws when service throws', () async {
        mockUserService.exceptionToThrow = Exception('Invalid credentials');

        expect(
          () => userRepository.validateLogin('a@b.com', 'wrong'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
