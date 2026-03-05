import 'package:api_amb_jwt/data/models/product.dart';
import 'package:api_amb_jwt/data/models/user.dart';
import 'package:api_amb_jwt/data/repositories/product_repository.dart';
import 'package:api_amb_jwt/data/repositories/user_repository.dart';
import 'package:api_amb_jwt/data/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock manual de IProductService
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

// Mock manual de IUserRepository
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
    return userToReturn!;
  }
}

void main() {
  late MockProductService mockProductService;
  late MockUserRepository mockUserRepository;
  late ProductRepository productRepository;

  final authenticatedUser = User(
    email: 'test@test.com',
    password: '',
    authenticated: true,
    accessToken: 'test-jwt-token',
  );

  setUp(() {
    mockProductService = MockProductService();
    mockUserRepository = MockUserRepository();
    mockUserRepository.userToReturn = authenticatedUser;
    productRepository = ProductRepository(
      productService: mockProductService,
      userRepository: mockUserRepository,
    );
  });

  group('ProductRepository', () {
    group('afegirProducte', () {
      test('calls service with correct token and product', () async {
        final product = Product(
          userId: '',
          id: 0,
          title: 'Test',
          price: 10.0,
          description: 'Desc',
          createdAt: DateTime(2025, 1, 1),
        );
        final createdProduct = Product(
          userId: 'user-1',
          id: 1,
          title: 'Test',
          price: 10.0,
          description: 'Desc',
          createdAt: DateTime(2025, 1, 1),
        );
        mockProductService.productToReturn = createdProduct;

        final result = await productRepository.afegirProducte(product);

        expect(mockProductService.lastToken, 'test-jwt-token');
        expect(mockProductService.lastCreatedProduct, product);
        expect(result.id, 1);
        expect(result.title, 'Test');
      });

      test('throws when service throws', () {
        mockProductService.exceptionToThrow = Exception('Create failed');
        final product = Product(
          userId: '',
          id: 0,
          title: 'T',
          price: 1.0,
          description: 'D',
          createdAt: DateTime.now(),
        );

        expect(
          () => productRepository.afegirProducte(product),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getProducts', () {
      test('returns list of products from service', () async {
        mockProductService.productsToReturn = [
          Product(
            userId: 'u1',
            id: 1,
            title: 'P1',
            price: 5.0,
            description: 'D1',
            createdAt: DateTime(2025, 1, 1),
          ),
          Product(
            userId: 'u2',
            id: 2,
            title: 'P2',
            price: 15.0,
            description: 'D2',
            createdAt: DateTime(2025, 2, 1),
          ),
        ];

        final products = await productRepository.getProducts();

        expect(products.length, 2);
        expect(products[0].title, 'P1');
        expect(products[1].title, 'P2');
        expect(mockProductService.lastToken, 'test-jwt-token');
      });

      test('returns empty list when no products', () async {
        mockProductService.productsToReturn = [];

        final products = await productRepository.getProducts();

        expect(products, isEmpty);
      });

      test('throws when service throws', () {
        mockProductService.exceptionToThrow = Exception('Load failed');

        expect(
          () => productRepository.getProducts(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('eliminarProducte', () {
      test('calls service with correct token and id', () async {
        await productRepository.eliminarProducte(42);

        expect(mockProductService.lastToken, 'test-jwt-token');
        expect(mockProductService.lastDeletedId, 42);
      });

      test('throws when service throws', () {
        mockProductService.exceptionToThrow = Exception('Delete failed');

        expect(
          () => productRepository.eliminarProducte(1),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
