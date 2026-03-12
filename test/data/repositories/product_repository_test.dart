import 'package:api_amb_jwt/data/models/product.dart';
import 'package:api_amb_jwt/data/models/user.dart';
import 'package:api_amb_jwt/data/repositories/product_repository.dart';
import 'package:api_amb_jwt/data/repositories/user_repository.dart';
import 'package:api_amb_jwt/data/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

class MockProductService implements IProductService {
  Product? productToReturn;
  List<Product>? productsToReturn;
  Exception? exceptionToThrow;
  int? lastDeletedId;
  Product? lastCreatedProduct;
  String? lastToken;

  @override
  Future<Product> crearProducte(String token, Product product) async {
    lastToken = token;
    lastCreatedProduct = product;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return productToReturn!;
  }

  @override
  Future<List<Product>> getProducts(String token) async {
    lastToken = token;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return productsToReturn!;
  }

  @override
  Future<void> eliminarProducte(String token, int id) async {
    lastToken = token;
    lastDeletedId = id;
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }
}

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
  Future<User> validateLogin(String email, String password) async => userToReturn!;
}

Product _makeProduct({int id = 0, String title = 'T', double price = 1.0, String desc = 'D'}) {
  return Product(userId: '', id: id, title: title, price: price, description: desc, createdAt: DateTime(2025));
}

void main() {
  late MockProductService mockService;
  late MockUserRepository mockUserRepo;
  late ProductRepository repo;

  setUp(() {
    mockService = MockProductService();
    mockUserRepo = MockUserRepository();
    mockUserRepo.userToReturn = User(email: 'test@test.com', password: '', authenticated: true, accessToken: 'test-jwt-token');
    repo = ProductRepository(productService: mockService, userRepository: mockUserRepo);
  });

  group('ProductRepository', () {
    // Comprova que afegirProducte envia el token correcte i retorna el producte creat
    test('afegirProducte amb token i resultat', () async {
      final product = _makeProduct(title: 'Test', price: 10.0, desc: 'Desc');
      mockService.productToReturn = _makeProduct(id: 1, title: 'Test', price: 10.0, desc: 'Desc');

      final result = await repo.afegirProducte(product);

      expect(mockService.lastToken, 'test-jwt-token');
      expect(mockService.lastCreatedProduct, product);
      expect(result.id, 1);
      expect(result.title, 'Test');
    });

    // Comprova que afegirProducte llança excepció si el servei falla
    test('afegirProducte error del servei', () {
      mockService.exceptionToThrow = Exception('Create failed');

      expect(() => repo.afegirProducte(_makeProduct()), throwsA(isA<Exception>()));
    });

    // Comprova que getProducts retorna la llista i gestiona llista buida
    test('getProducts llista i llista buida', () async {
      mockService.productsToReturn = [
        _makeProduct(id: 1, title: 'P1'),
        _makeProduct(id: 2, title: 'P2'),
      ];

      final products = await repo.getProducts();
      expect(products.length, 2);
      expect(products[0].title, 'P1');
      expect(products[1].title, 'P2');
      expect(mockService.lastToken, 'test-jwt-token');

      // Empty list
      mockService.productsToReturn = [];
      expect(await repo.getProducts(), isEmpty);
    });

    // Comprova que getProducts llança excepció si el servei falla
    test('getProducts error del servei', () {
      mockService.exceptionToThrow = Exception('Load failed');

      expect(() => repo.getProducts(), throwsA(isA<Exception>()));
    });

    // Comprova que eliminarProducte envia token i id correctes
    test('eliminarProducte amb token i id', () async {
      await repo.eliminarProducte(42);

      expect(mockService.lastToken, 'test-jwt-token');
      expect(mockService.lastDeletedId, 42);
    });

    // Comprova que eliminarProducte llança excepció si el servei falla
    test('eliminarProducte error del servei', () {
      mockService.exceptionToThrow = Exception('Delete failed');

      expect(() => repo.eliminarProducte(1), throwsA(isA<Exception>()));
    });
  });
}
