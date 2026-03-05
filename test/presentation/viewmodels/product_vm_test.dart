import 'package:api_amb_jwt/data/models/product.dart';
import 'package:api_amb_jwt/data/repositories/product_repository.dart';
import 'package:api_amb_jwt/presentation/viewmodels/product_vm.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock manual de IProductRepository
class MockProductRepository implements IProductRepository {
  Product? productToReturn;
  List<Product>? productsToReturn;
  Exception? exceptionToThrow;
  Exception? exceptionOnGet;
  Exception? exceptionOnDelete;
  int? lastDeletedId;
  Product? lastAddedProduct;

  @override
  Future<Product> afegirProducte(Product product) async {
    lastAddedProduct = product;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return productToReturn!;
  }

  @override
  Future<List<Product>> getProducts() async {
    if (exceptionOnGet != null) throw exceptionOnGet!;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return productsToReturn ?? [];
  }

  @override
  Future<void> eliminarProducte(int id) async {
    lastDeletedId = id;
    if (exceptionOnDelete != null) throw exceptionOnDelete!;
    if (exceptionToThrow != null) throw exceptionToThrow!;
  }
}

void main() {
  late MockProductRepository mockProductRepository;
  late ProductVM productVM;

  setUp(() {
    mockProductRepository = MockProductRepository();
    productVM = ProductVM(productRepository: mockProductRepository);
  });

  group('ProductVM', () {
    test('initial state has empty products list', () {
      expect(productVM.products, isEmpty);
      expect(productVM.isLoading, isFalse);
      expect(productVM.errorMessage, isNull);
    });

    group('afegirProducte', () {
      test('adds product and updates list on success', () async {
        final createdProduct = Product(
          userId: 'u1',
          id: 1,
          title: 'New Product',
          price: 25.0,
          description: 'A description',
          createdAt: DateTime(2025, 6, 1),
        );
        mockProductRepository.productToReturn = createdProduct;
        mockProductRepository.productsToReturn = [createdProduct];

        await productVM.afegirProducte('New Product', 'A description', 25.0);

        expect(productVM.products.length, 1);
        expect(productVM.products[0].title, 'New Product');
        expect(productVM.isLoading, isFalse);
        expect(productVM.errorMessage, isNull);
      });

      test('sets errorMessage on failure', () async {
        mockProductRepository.exceptionToThrow =
            Exception('Failed to create');

        await productVM.afegirProducte('Fail', 'Desc', 10.0);

        expect(productVM.errorMessage, isNotNull);
        expect(productVM.errorMessage, contains('Failed to create'));
        expect(productVM.isLoading, isFalse);
      });

      test('sets isLoading to false after completion', () async {
        final product = Product(
          userId: '',
          id: 1,
          title: 'T',
          price: 1.0,
          description: 'D',
          createdAt: DateTime.now(),
        );
        mockProductRepository.productToReturn = product;
        mockProductRepository.productsToReturn = [product];

        await productVM.afegirProducte('T', 'D', 1.0);

        expect(productVM.isLoading, isFalse);
      });

      test('notifies listeners during the process', () async {
        final product = Product(
          userId: '',
          id: 1,
          title: 'T',
          price: 1.0,
          description: 'D',
          createdAt: DateTime.now(),
        );
        mockProductRepository.productToReturn = product;
        mockProductRepository.productsToReturn = [product];

        int notifyCount = 0;
        productVM.addListener(() => notifyCount++);

        await productVM.afegirProducte('T', 'D', 1.0);

        // Should notify at least twice: start (isLoading=true) and end (isLoading=false)
        expect(notifyCount, greaterThanOrEqualTo(2));
      });

      test('creates product with empty userId and id 0', () async {
        final createdProduct = Product(
          userId: 'server-assigned',
          id: 99,
          title: 'Widget',
          price: 5.0,
          description: 'Nice',
          createdAt: DateTime.now(),
        );
        mockProductRepository.productToReturn = createdProduct;
        mockProductRepository.productsToReturn = [createdProduct];

        await productVM.afegirProducte('Widget', 'Nice', 5.0);

        final sentProduct = mockProductRepository.lastAddedProduct!;
        expect(sentProduct.userId, '');
        expect(sentProduct.id, 0);
        expect(sentProduct.title, 'Widget');
        expect(sentProduct.description, 'Nice');
        expect(sentProduct.price, 5.0);
      });
    });

    group('eliminarProducte', () {
      test('removes product from list on success', () async {
        productVM.products = [
          Product(
            userId: 'u1',
            id: 1,
            title: 'P1',
            price: 10.0,
            description: 'D1',
            createdAt: DateTime(2025, 1, 1),
          ),
          Product(
            userId: 'u2',
            id: 2,
            title: 'P2',
            price: 20.0,
            description: 'D2',
            createdAt: DateTime(2025, 2, 1),
          ),
        ];

        await productVM.eliminarProducte(1);

        expect(productVM.products.length, 1);
        expect(productVM.products[0].id, 2);
        expect(productVM.isLoading, isFalse);
        expect(productVM.errorMessage, isNull);
      });

      test('calls repository with correct id', () async {
        await productVM.eliminarProducte(42);

        expect(mockProductRepository.lastDeletedId, 42);
      });

      test('sets errorMessage on failure', () async {
        mockProductRepository.exceptionOnDelete =
            Exception('Delete failed');

        await productVM.eliminarProducte(1);

        expect(productVM.errorMessage, isNotNull);
        expect(productVM.errorMessage, contains('Delete failed'));
        expect(productVM.isLoading, isFalse);
      });

      test('sets isLoading to false after completion', () async {
        await productVM.eliminarProducte(1);

        expect(productVM.isLoading, isFalse);
      });

      test('notifies listeners', () async {
        int notifyCount = 0;
        productVM.addListener(() => notifyCount++);

        await productVM.eliminarProducte(1);

        expect(notifyCount, greaterThanOrEqualTo(2));
      });
    });

    group('llistarProductes', () {
      test('loads products from repository', () async {
        mockProductRepository.productsToReturn = [
          Product(
            userId: 'u1',
            id: 1,
            title: 'P1',
            price: 10.0,
            description: 'D1',
            createdAt: DateTime(2025, 1, 1),
          ),
          Product(
            userId: 'u2',
            id: 2,
            title: 'P2',
            price: 20.0,
            description: 'D2',
            createdAt: DateTime(2025, 2, 1),
          ),
        ];

        await productVM.llistarProductes();

        expect(productVM.products.length, 2);
        expect(productVM.products[0].title, 'P1');
        expect(productVM.products[1].title, 'P2');
        expect(productVM.isLoading, isFalse);
        expect(productVM.errorMessage, isNull);
      });

      test('handles empty product list', () async {
        mockProductRepository.productsToReturn = [];

        await productVM.llistarProductes();

        expect(productVM.products, isEmpty);
        expect(productVM.isLoading, isFalse);
      });

      test('sets errorMessage on failure', () async {
        mockProductRepository.exceptionOnGet =
            Exception('Failed to load products');

        await productVM.llistarProductes();

        expect(productVM.errorMessage, isNotNull);
        expect(productVM.errorMessage, contains('Failed to load products'));
        expect(productVM.isLoading, isFalse);
      });

      test('notifies listeners', () async {
        mockProductRepository.productsToReturn = [];

        int notifyCount = 0;
        productVM.addListener(() => notifyCount++);

        await productVM.llistarProductes();

        expect(notifyCount, greaterThanOrEqualTo(2));
      });
    });
  });
}
