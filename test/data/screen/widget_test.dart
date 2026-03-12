import 'package:api_amb_jwt/data/models/product.dart';
import 'package:api_amb_jwt/data/models/user.dart';
import 'package:api_amb_jwt/data/repositories/product_repository.dart';
import 'package:api_amb_jwt/data/repositories/user_repository.dart';
import 'package:api_amb_jwt/data/screen/creation_page.dart';
import 'package:api_amb_jwt/data/screen/list_page.dart';
import 'package:api_amb_jwt/data/screen/login_page.dart';
import 'package:api_amb_jwt/data/screen/home_page.dart';
import 'package:api_amb_jwt/presentation/viewmodels/product_vm.dart';
import 'package:api_amb_jwt/presentation/viewmodels/user_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// -- Mocks --

class MockUserRepository implements IUserRepository {
  User? userToReturn;

  @override
  bool get authenticated => userToReturn?.authenticated ?? false;

  @override
  User get email {
    if (userToReturn == null) throw Exception('User not authenticated');
    return userToReturn!;
  }

  @override
  Future<User> validateLogin(String email, String password) async {
    userToReturn = User(
      email: email,
      password: '',
      authenticated: true,
      accessToken: 'token',
    );
    return userToReturn!;
  }
}

class MockProductRepository implements IProductRepository {
  List<Product> productsToReturn = [];
  Product? productToReturn;
  Exception? exceptionToThrow;
  int? lastDeletedId;

  @override
  Future<Product> afegirProducte(Product product) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return productToReturn ?? product;
  }

  @override
  Future<List<Product>> getProducts() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return productsToReturn;
  }

  @override
  Future<void> eliminarProducte(int id) async {
    lastDeletedId = id;
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }
}

// -- Helpers --

Product _makeProduct({
  int id = 1,
  String title = 'P',
  double price = 5.0,
  String desc = 'D',
}) {
  return Product(
    userId: 'u1',
    id: id,
    title: title,
    price: price,
    description: desc,
    createdAt: DateTime(2025),
  );
}

Widget _loginApp(
  MockUserRepository userRepo,
  MockProductRepository productRepo,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserVM(userRepository: userRepo)),
      ChangeNotifierProvider(
        create: (_) => ProductVM(productRepository: productRepo),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: LoginPage())),
  );
}

Widget _creationApp(MockProductRepository productRepo) {
  return ChangeNotifierProvider(
    create: (_) => ProductVM(productRepository: productRepo),
    child: const MaterialApp(home: ProductCreationPage()),
  );
}

Widget _listApp(MockProductRepository productRepo) {
  return ChangeNotifierProvider(
    create: (_) => ProductVM(productRepository: productRepo),
    child: const MaterialApp(home: ProductListPage()),
  );
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required MockUserRepository userRepo,
  required MockProductRepository productRepo,
  required double width,
  required double height,
  bool authenticated = true,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  UserVM userVM = UserVM(userRepository: userRepo);
  if (authenticated) {
    userVM.emailController.text = 'test@test.com';
    userVM.passwordController.text = 'pass';
    await userVM.login();
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserVM>.value(value: userVM),
        ChangeNotifierProvider(
          create: (_) => ProductVM(productRepository: productRepo),
        ),
      ],
      child: const MaterialApp(home: MyHomePage(title: 'Test')),
    ),
  );
  await tester.pumpAndSettle();
}

// ===================== TESTS =====================

void main() {
  // ===== LoginPage =====
  late MockUserRepository userRepo;
  late MockProductRepository productRepo;

  setUp(() {
    userRepo = MockUserRepository();
    productRepo = MockProductRepository();
  });

  // Comprova que es mostren els camps del formulari i el boto de login
  testWidgets('mostra formulari i boto login', (tester) async {
    await tester.pumpWidget(_loginApp(userRepo, productRepo));

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Introduix el email'), findsOneWidget);
    expect(find.text('Introduix la contrasenya'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.textContaining('You are logged in as:'), findsNothing);
  });

  // Comprova que es pot escriure text i fer login correctament
  testWidgets('escriure text i login correcte', (tester) async {
    await tester.pumpWidget(_loginApp(userRepo, productRepo));

    await tester.enterText(
      find.widgetWithText(TextField, 'Introduix el email'),
      'user@test.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Introduix la contrasenya'),
      'pass',
    );
    await tester.pump();

    expect(find.text('user@test.com'), findsOneWidget);
    expect(find.text('pass'), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(userRepo.userToReturn?.authenticated, isTrue);
    expect(find.textContaining('You are logged in as:'), findsOneWidget);
  });

  // ===== ProductCreationPage =====

  setUp(() {
    productRepo = MockProductRepository();
  });

  // Comprova que es mostra AppBar, camps i boto de creacio
  testWidgets('mostra formulari amb AppBar i camps', (tester) async {
    await tester.pumpWidget(_creationApp(productRepo));

    expect(find.text('Nou Producte'), findsOneWidget);
    expect(find.text('Títol'), findsOneWidget);
    expect(find.text('Descripció'), findsOneWidget);
    expect(find.text('Preu'), findsOneWidget);
    expect(find.text('Crear Producte'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  // Comprova validacio de camps buits al enviar
  testWidgets('valida camps buits', (tester) async {
    await tester.pumpWidget(_creationApp(productRepo));

    // Empty title
    await tester.tap(find.text('Crear Producte'));
    await tester.pumpAndSettle();
    expect(
      find.text('Si us plau, introdueix un títol per al producte'),
      findsOneWidget,
    );

    // Fill title, empty description
    await tester.enterText(find.byType(TextFormField).at(0), 'Title');
    await tester.tap(find.text('Crear Producte'));
    await tester.pumpAndSettle();
    expect(
      find.text('Si us plau, introdueix una descripció per al producte'),
      findsOneWidget,
    );

    // Fill description, empty price
    await tester.enterText(find.byType(TextFormField).at(1), 'Desc');
    await tester.tap(find.text('Crear Producte'));
    await tester.pumpAndSettle();
    expect(find.text('Si us plau, introdueix un preu'), findsOneWidget);

    // Invalid price
    await tester.enterText(find.byType(TextFormField).at(2), 'abc');
    await tester.tap(find.text('Crear Producte'));
    await tester.pumpAndSettle();
    expect(find.text('Si us plau, introdueix un número vàlid'), findsOneWidget);
  });

  // Comprova que crea producte, mostra snackbar i neteja camps
  testWidgets('crea producte i neteja camps', (tester) async {
    productRepo.productToReturn = _makeProduct(
      title: 'New',
      price: 10.0,
      desc: 'Desc',
    );
    productRepo.productsToReturn = [productRepo.productToReturn!];

    await tester.pumpWidget(_creationApp(productRepo));

    await tester.enterText(find.byType(TextFormField).at(0), 'New');
    await tester.enterText(find.byType(TextFormField).at(1), 'Desc');
    await tester.enterText(find.byType(TextFormField).at(2), '10.0');
    await tester.tap(find.text('Crear Producte'));
    await tester.pumpAndSettle();

    expect(find.text('Producte creat!!!'), findsOneWidget);

    final titleField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
    expect(titleField.controller?.text, '');
  });

  // Comprova que es pot escriure text a tots els camps
  testWidgets('escriure text als camps', (tester) async {
    await tester.pumpWidget(_creationApp(productRepo));

    await tester.enterText(find.byType(TextFormField).at(0), 'Test Title');
    await tester.enterText(find.byType(TextFormField).at(1), 'Test Desc');
    await tester.enterText(find.byType(TextFormField).at(2), '99.99');
    await tester.pump();

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Desc'), findsOneWidget);
    expect(find.text('99.99'), findsOneWidget);
  });

  // ===== ProductListPage =====
  setUp(() {
    productRepo = MockProductRepository();
  });

  // Comprova que mostra productes amb titol, subtitol i icona esborrar
  testWidgets('mostra productes amb detalls', (tester) async {
    productRepo.productsToReturn = [
      _makeProduct(id: 1, title: 'Product A', price: 10.0, desc: 'Desc A'),
      _makeProduct(id: 2, title: 'Product B', price: 20.5, desc: 'Desc B'),
    ];

    await tester.pumpWidget(_listApp(productRepo));
    await tester.pumpAndSettle();

    expect(find.text('Llista de Productes'), findsOneWidget);
    expect(find.text('Product A'), findsOneWidget);
    expect(find.text('Product B'), findsOneWidget);
    expect(find.text('Desc A - 10.0€'), findsOneWidget);
    expect(find.text('Desc B - 20.5€'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNWidgets(2));
  });

  // Comprova que tocar esborrar crida eliminarProducte
  testWidgets('esborrar crida eliminarProducte', (tester) async {
    productRepo.productsToReturn = [_makeProduct(id: 42, title: 'To Delete')];

    await tester.pumpWidget(_listApp(productRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(productRepo.lastDeletedId, 42);
  });

  // Comprova que mostra llista buida sense productes
  testWidgets('llista buida sense productes', (tester) async {
    await tester.pumpWidget(_listApp(productRepo));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNothing);
  });

  // Comprova que mostra missatge d'error si falla la carrega
  testWidgets('mostra error si falla carrega', (tester) async {
    productRepo.exceptionToThrow = Exception('Network error');

    await tester.pumpWidget(_listApp(productRepo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  // ===== MainArea =====
  // Comprova que renderitza fill dins Expanded amb color primaryContainer
  testWidgets('renderitza fill amb Expanded i color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Row(children: const [MainArea(page: Text('Test Page'))]),
        ),
      ),
    );

    expect(find.text('Test Page'), findsOneWidget);
    expect(find.byType(Expanded), findsOneWidget);
    final container = tester.widget<Container>(find.byType(Container).last);
    expect(container.color, isNotNull);
  });

  // ===== MyHomePage =====
  setUp(() {
    userRepo = MockUserRepository();
    productRepo = MockProductRepository();
  });

  // Comprova que mostra LoginPage si no esta autenticat
  testWidgets('mostra LoginPage sense autenticacio', (tester) async {
    await _pumpHome(
      tester,
      userRepo: userRepo,
      productRepo: productRepo,
      width: 800,
      height: 600,
      authenticated: false,
    );

    expect(find.byType(LoginPage), findsOneWidget);
  });

  // Comprova layout ample: NavigationRail estes amb destinacions correctes
  testWidgets('layout ample: NavigationRail estes', (tester) async {
    await _pumpHome(
      tester,
      userRepo: userRepo,
      productRepo: productRepo,
      width: 800,
      height: 600,
    );

    expect(find.byType(ProductCreationPage), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(MainArea), findsOneWidget);
    expect(find.byType(SafeArea), findsWidgets);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);

    expect(find.text('Crear'), findsOneWidget);
    expect(find.text('Llistar'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.list), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  // Comprova layout mitja: NavigationRail no estes
  testWidgets('layout mitja: NavigationRail compacte', (tester) async {
    await _pumpHome(
      tester,
      userRepo: userRepo,
      productRepo: productRepo,
      width: 500,
      height: 600,
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
  });

  // Comprova layout estret: NavigationBar amb destinacions
  testWidgets('layout estret: NavigationBar', (tester) async {
    await _pumpHome(
      tester,
      userRepo: userRepo,
      productRepo: productRepo,
      width: 400,
      height: 800,
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Crear'), findsOneWidget);
    expect(find.text('Llista'), findsOneWidget);
    expect(find.text('Sortir'), findsOneWidget);
  });

  // Comprova navegacio entre pagines amb NavigationRail
  testWidgets('NavigationRail: navegar entre pagines', (tester) async {
    await _pumpHome(
      tester,
      userRepo: userRepo,
      productRepo: productRepo,
      width: 800,
      height: 600,
    );

    // Go to list
    await tester.tap(find.text('Llistar'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductListPage), findsOneWidget);
    expect(find.byType(ProductCreationPage), findsNothing);

    // Go back to create
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductCreationPage), findsOneWidget);
  });

  // Comprova que logout torna a LoginPage amb NavigationRail
  testWidgets('NavigationRail: logout torna a LoginPage', (tester) async {
    await _pumpHome(
      tester,
      userRepo: userRepo,
      productRepo: productRepo,
      width: 800,
      height: 600,
    );

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  // Comprova navegacio i logout amb NavigationBar (layout estret)
  testWidgets('NavigationBar: navegar i logout', (tester) async {
    await _pumpHome(
      tester,
      userRepo: userRepo,
      productRepo: productRepo,
      width: 400,
      height: 800,
    );

    // Navigate to list
    await tester.tap(find.text('Llista'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductListPage), findsOneWidget);

    // Logout
    await tester.tap(find.text('Sortir'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  // Comprova que logout reseteja a pagina creacio despres de re-login
  testWidgets('logout reseteja a creacio post re-login', (tester) async {
    await _pumpHome(
      tester,
      userRepo: userRepo,
      productRepo: productRepo,
      width: 800,
      height: 600,
    );

    // Navigate to list, then logout
    await tester.tap(find.text('Llistar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    // Login again
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

    expect(find.byType(ProductCreationPage), findsOneWidget);
  });
}
