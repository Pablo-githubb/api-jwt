import 'package:api_amb_jwt/data/models/product.dart';
import 'package:api_amb_jwt/data/models/user.dart';
import 'package:api_amb_jwt/data/repositories/product_repository.dart';
import 'package:api_amb_jwt/data/repositories/user_repository.dart';
import 'package:api_amb_jwt/data/screen/login_page.dart';
import 'package:api_amb_jwt/data/screen/home_page.dart';
import 'package:api_amb_jwt/data/services/product_service.dart';
import 'package:api_amb_jwt/data/services/user_service.dart';
import 'package:api_amb_jwt/presentation/viewmodels/product_vm.dart';
import 'package:api_amb_jwt/presentation/viewmodels/user_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// -- Mocks --

class MockUserService implements IUserService {
  User? userToReturn;
  Exception? exceptionToThrow;

  @override
  Future<User> validateLogin(String email, String password) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return userToReturn!;
  }
}

class MockUserRepository implements IUserRepository {
  User? userToReturn;
  Exception? exceptionToThrow;

  @override
  bool get authenticated => userToReturn?.authenticated ?? false;

  @override
  User get email {
    if (userToReturn == null) throw Exception('User not authenticated');
    return userToReturn!;
  }

  @override
  Future<User> validateLogin(String email, String password) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    userToReturn = User(
      email: email,
      password: '',
      authenticated: true,
      accessToken: 'token',
    );
    return userToReturn!;
  }
}

class MockProductService implements IProductService {
  @override
  Future<Product> crearProducte(String token, Product product) async {
    return product;
  }

  @override
  Future<List<Product>> getProducts(String token) async => [];

  @override
  Future<void> eliminarProducte(String token, int id) async {}
}

class MockProductRepository implements IProductRepository {
  @override
  Future<Product> afegirProducte(Product product) async => product;

  @override
  Future<List<Product>> getProducts() async => [];

  @override
  Future<void> eliminarProducte(int id) async {}
}

// -- Helpers --

Widget createTestApp({
  required MockUserRepository mockUserRepo,
  required MockProductRepository mockProductRepo,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => UserVM(userRepository: mockUserRepo),
      ),
      ChangeNotifierProvider(
        create: (_) => ProductVM(productRepository: mockProductRepo),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: LoginPage()),
    ),
  );
}

void main() {
  group('LoginPage Widget', () {
    late MockUserRepository mockUserRepo;
    late MockProductRepository mockProductRepo;

    setUp(() {
      mockUserRepo = MockUserRepository();
      mockProductRepo = MockProductRepository();
    });

    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(createTestApp(
        mockUserRepo: mockUserRepo,
        mockProductRepo: mockProductRepo,
      ));

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Introduix el email'), findsOneWidget);
      expect(find.text('Introduix la contrasenya'), findsOneWidget);
    });

    testWidgets('renders login button', (tester) async {
      await tester.pumpWidget(createTestApp(
        mockUserRepo: mockUserRepo,
        mockProductRepo: mockProductRepo,
      ));

      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('can enter email and password', (tester) async {
      await tester.pumpWidget(createTestApp(
        mockUserRepo: mockUserRepo,
        mockProductRepo: mockProductRepo,
      ));

      await tester.enterText(
        find.widgetWithText(TextField, 'Introduix el email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Introduix la contrasenya'),
        'password123',
      );

      await tester.pump();

      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('tapping login calls the VM login method', (tester) async {
      mockUserRepo.userToReturn = null; // not authenticated initially

      await tester.pumpWidget(createTestApp(
        mockUserRepo: mockUserRepo,
        mockProductRepo: mockProductRepo,
      ));

      await tester.enterText(
        find.widgetWithText(TextField, 'Introduix el email'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Introduix la contrasenya'),
        'pass',
      );

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // After login, the user should be authenticated in the mock
      expect(mockUserRepo.userToReturn?.authenticated, isTrue);
    });
  });

  group('MainArea Widget', () {
    testWidgets('renders child page inside Expanded container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: const [
                MainArea(page: Text('Test Page')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Page'), findsOneWidget);
      expect(find.byType(Expanded), findsOneWidget);
    });
  });

  group('MyHomePage Widget', () {
    testWidgets('shows LoginPage when not authenticated', (tester) async {
      final mockUserRepo = MockUserRepository();
      final mockProductRepo = MockProductRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => UserVM(userRepository: mockUserRepo),
            ),
            ChangeNotifierProvider(
              create: (_) => ProductVM(productRepository: mockProductRepo),
            ),
          ],
          child: const MaterialApp(
            home: MyHomePage(title: 'Test'),
          ),
        ),
      );

      // Should show login page since user is not authenticated
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
