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
    // Comprova que l'estat inicial te llista buida, sense carrega ni error
    test('estat inicial buit', () {
      expect(productVM.products, isEmpty);
      expect(productVM.isLoading, isFalse);
      expect(productVM.errorMessage, isNull);
    });

    group('afegirProducte', () {
      // Comprova que afegeix producte i actualitza la llista correctament
      test('afegeix producte i actualitza llista', () async {
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

      // Comprova que estableix missatge d'error si falla
      test('error al crear producte', () async {
        mockProductRepository.exceptionToThrow =
            Exception('Failed to create');

        await productVM.afegirProducte('Fail', 'Desc', 10.0);

        expect(productVM.errorMessage, isNotNull);
        expect(productVM.errorMessage, contains('Failed to create'));
        expect(productVM.isLoading, isFalse);
      });

      // Comprova que isLoading es false despres de completar
      test('isLoading false despres de crear', () async {
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

      // Comprova que notifica als listeners durant el proces
      test('notifica listeners al crear', () async {
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

        // Ha de notificar minim 2 cops: inici (isLoading=true) i fi (isLoading=false)
        expect(notifyCount, greaterThanOrEqualTo(2));
      });

      // Comprova que crea producte amb userId buit i id 0
      test('crea producte amb userId buit i id 0', () async {
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
      // Comprova que elimina producte de la llista correctament
      test('elimina producte de la llista', () async {
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

      // Comprova que crida el repositori amb l'id correcte
      test('crida repositori amb id correcte', () async {
        await productVM.eliminarProducte(42);

        expect(mockProductRepository.lastDeletedId, 42);
      });

      // Comprova que estableix missatge d'error si falla
      test('error al eliminar producte', () async {
        mockProductRepository.exceptionOnDelete =
            Exception('Delete failed');

        await productVM.eliminarProducte(1);

        expect(productVM.errorMessage, isNotNull);
        expect(productVM.errorMessage, contains('Delete failed'));
        expect(productVM.isLoading, isFalse);
      });

      // Comprova que isLoading es false despres d'eliminar
      test('isLoading false al eliminar', () async {
        await productVM.eliminarProducte(1);

        expect(productVM.isLoading, isFalse);
      });

      // Comprova que notifica als listeners
      test('notifica listeners al eliminar', () async {
        int notifyCount = 0;
        productVM.addListener(() => notifyCount++);

        await productVM.eliminarProducte(1);

        expect(notifyCount, greaterThanOrEqualTo(2));
      });
    });

    group('llistarProductes', () {
      // Comprova que carrega productes del repositori
      test('carrega productes del repositori', () async {
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

      // Comprova que gestiona llista buida correctament
      test('llista buida sense productes', () async {
        mockProductRepository.productsToReturn = [];

        await productVM.llistarProductes();

        expect(productVM.products, isEmpty);
        expect(productVM.isLoading, isFalse);
      });

      // Comprova que estableix missatge d'error si falla
      test('error al carregar productes', () async {
        mockProductRepository.exceptionOnGet =
            Exception('Failed to load products');

        await productVM.llistarProductes();

        expect(productVM.errorMessage, isNotNull);
        expect(productVM.errorMessage, contains('Failed to load products'));
        expect(productVM.isLoading, isFalse);
      });

      // Comprova que notifica als listeners
      test('notifica listeners al llistar', () async {
        mockProductRepository.productsToReturn = [];

        int notifyCount = 0;
        productVM.addListener(() => notifyCount++);

        await productVM.llistarProductes();

        expect(notifyCount, greaterThanOrEqualTo(2));
      });
    });
  });
}
