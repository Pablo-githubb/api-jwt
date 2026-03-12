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
    // Comprova que l'estat inicial no esta autenticat
    test('estat inicial sense autenticacio', () {
      expect(userVM.authenticated, isFalse);
      expect(userVM.email, '');
      expect(userVM.password, '');
    });

    group('login', () {
      // Comprova que estableix currentUser amb login correcte
      test('login correcte estableix currentUser', () async {
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

      // Comprova que passa el text dels controllers al repositori
      test('envia credencials al repositori', () async {
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

      // Comprova que gestiona excepcio sense petar
      test('error login no peta', () async {
        mockUserRepository.exceptionToThrow =
            Exception('Invalid credentials');
        userVM.emailController.text = 'bad@email.com';
        userVM.passwordController.text = 'wrong';

        // No ha de llancar excepcio
        await userVM.login();

        expect(userVM.authenticated, isFalse);
      });

      // Comprova que notifica als listeners amb login correcte
      test('notifica listeners al login', () async {
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
      // Comprova que reseteja autenticacio despres de logout
      test('logout reseteja autenticacio', () async {
        // Primer login
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

        // Despres logout
        await userVM.logout();

        expect(userVM.authenticated, isFalse);
        expect(userVM.email, '');
      });

      // Comprova que notifica als listeners al fer logout
      test('notifica listeners al logout', () async {
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
      // Comprova que els controllers estan inicialitzats i buits
      test('controllers inicialitzats buits', () {
        expect(userVM.emailController, isNotNull);
        expect(userVM.passwordController, isNotNull);
        expect(userVM.emailController.text, '');
        expect(userVM.passwordController.text, '');
      });
    });
  });
}
