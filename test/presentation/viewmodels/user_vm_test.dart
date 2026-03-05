import 'package:api_amb_jwt/data/models/user.dart';
import 'package:api_amb_jwt/data/repositories/user_repository.dart';
import 'package:api_amb_jwt/presentation/viewmodels/user_vm.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock manual de IUserRepository
class MockUserRepository implements IUserRepository {
  User? userToReturn;
  Exception? exceptionToThrow;
  String? lastEmail;
  String? lastPassword;

  @override
  bool get authenticated => userToReturn?.authenticated ?? false;

  @override
  User get email {
    if (userToReturn == null) throw Exception('User not authenticated');
    return userToReturn!;
  }

  @override
  Future<User> validateLogin(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return userToReturn!;
  }
}

void main() {
  late MockUserRepository mockUserRepository;
  late UserVM userVM;

  setUp(() {
    mockUserRepository = MockUserRepository();
    userVM = UserVM(userRepository: mockUserRepository);
  });

  tearDown(() {
    userVM.dispose();
  });

  group('UserVM', () {
    test('initial state is not authenticated', () {
      expect(userVM.authenticated, isFalse);
      expect(userVM.email, '');
      expect(userVM.password, '');
    });

    group('login', () {
      test('sets currentUser on successful login', () async {
        mockUserRepository.userToReturn = User(
          email: 'test@test.com',
          password: 'secret',
          authenticated: true,
          accessToken: 'token-123',
        );
        userVM.emailController.text = 'test@test.com';
        userVM.passwordController.text = 'secret';

        await userVM.login();

        expect(userVM.authenticated, isTrue);
        expect(userVM.email, 'test@test.com');
        expect(userVM.password, 'secret');
      });

      test('passes controller text to repository', () async {
        mockUserRepository.userToReturn = User(
          email: 'a@b.com',
          password: 'pass',
          authenticated: true,
          accessToken: 'tok',
        );
        userVM.emailController.text = 'a@b.com';
        userVM.passwordController.text = 'pass';

        await userVM.login();

        expect(mockUserRepository.lastEmail, 'a@b.com');
        expect(mockUserRepository.lastPassword, 'pass');
      });

      test('handles login exception gracefully (does not crash)', () async {
        mockUserRepository.exceptionToThrow =
            Exception('Invalid credentials');
        userVM.emailController.text = 'bad@email.com';
        userVM.passwordController.text = 'wrong';

        // Should not throw
        await userVM.login();

        expect(userVM.authenticated, isFalse);
      });

      test('notifies listeners on successful login', () async {
        mockUserRepository.userToReturn = User(
          email: 'x@y.com',
          password: '',
          authenticated: true,
          accessToken: 'tok',
        );
        userVM.emailController.text = 'x@y.com';
        userVM.passwordController.text = 'p';

        bool notified = false;
        userVM.addListener(() => notified = true);

        await userVM.login();

        expect(notified, isTrue);
      });
    });

    group('logout', () {
      test('resets authenticated to false after logout', () async {
        // First login
        mockUserRepository.userToReturn = User(
          email: 'test@test.com',
          password: '',
          authenticated: true,
          accessToken: 'token',
        );
        userVM.emailController.text = 'test@test.com';
        userVM.passwordController.text = 'pass';
        await userVM.login();
        expect(userVM.authenticated, isTrue);

        // Then logout
        await userVM.logout();

        expect(userVM.authenticated, isFalse);
        expect(userVM.email, '');
      });

      test('notifies listeners on logout', () async {
        mockUserRepository.userToReturn = User(
          email: 'x@y.com',
          password: '',
          authenticated: true,
          accessToken: 'tok',
        );
        userVM.emailController.text = 'x@y.com';
        userVM.passwordController.text = 'p';
        await userVM.login();

        bool notified = false;
        userVM.addListener(() => notified = true);

        await userVM.logout();

        expect(notified, isTrue);
      });
    });

    group('controllers', () {
      test('emailController and passwordController are initialized', () {
        expect(userVM.emailController, isNotNull);
        expect(userVM.passwordController, isNotNull);
        expect(userVM.emailController.text, '');
        expect(userVM.passwordController.text, '');
      });
    });
  });
}
