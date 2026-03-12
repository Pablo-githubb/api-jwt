import 'dart:convert';

import 'package:api_amb_jwt/data/models/product.dart';
import 'package:http/http.dart' as http;

abstract class IProductService {
  Future<Product> crearProducte(String token, Product product);
  Future<List<Product>> getProducts(String token);
  Future<void> eliminarProducte(String token, int id);
}

///acces_token meu: eyJhbGciOiJIUzI1NiIsImtpZCI6ImlFVktCVVlobzdibjVZMWMiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2l0dnl2dnhvbm5zZG9xb2t2aWt3LnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiIwZTZlNWY3MS0xOWFiLTRhOTktYWZkYi04MDUyZDQwOGI5NTciLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzY5MDE5NTg5LCJpYXQiOjE3NjkwMTU5ODksImVtYWlsIjoicGFibG9tYXNvQGllc2VicmUuY29tIiwicGhvbmUiOiIiLCJhcHBfbWV0YWRhdGEiOnsicHJvdmlkZXIiOiJlbWFpbCIsInByb3ZpZGVycyI6WyJlbWFpbCJdfSwidXNlcl9tZXRhZGF0YSI6eyJlbWFpbF92ZXJpZmllZCI6dHJ1ZX0sInJvbGUiOiJhdXRoZW50aWNhdGVkIiwiYWFsIjoiYWFsMSIsImFtciI6W3sibWV0aG9kIjoicGFzc3dvcmQiLCJ0aW1lc3RhbXAiOjE3NjkwMTU5ODl9XSwic2Vzc2lvbl9pZCI6ImQ1NDRkMGFlLTc5YmUtNDhmZi04ODZmLWRlYTVlMjkwZDZmZSIsImlzX2Fub255bW91cyI6ZmFsc2V9.XaAkJ8e1mLWdwi99FSGx1ayDnPJ-PeJgPytEq5UfxKU
class ProductService implements IProductService {
  static const String _appUrl =
      'https://itvyvvxonnsdoqokvikw.supabase.co/rest/v1/products';
  static const String _apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0dnl2dnhvbm5zZG9xb2t2aWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0ODE1NTQsImV4cCI6MjA4MTA1NzU1NH0.6AxDj1flnnqtBvOjoKe9_MehqBwo0kNgxLGOf4VKQ5A';

  final http.Client _client;

  ProductService({http.Client? client}) : _client = client ?? http.Client();

  @override
  /// Envia una petició POST per crear un nou producte a Supabase.
  Future<Product> crearProducte(String token, Product product) async {
    final response = await _client.post(
      Uri.parse(_appUrl),
      //Aquest són els headers demanats a l'enunciat per a les capçaleres addicionals del Supabase
      headers: {
        'apikey': _apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',

        // Per aconseguir que la petició de creació només torni un producte i no una llista de productes heu d’incloure la capçalera:
        'Accept': 'application/vnd.pgrst.object+json',
        //Per aconseguir que la petició de creació de producte us retorni les dades del producte creat heu d’incloure la capçalera:
        'Prefer': 'return=representation',
      },
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Product.fromJson(data);
    } else {
      throw Exception('Failed to create product: ${response.body}');
    }
  }

  @override
  /// Obté la llista de productes des de l'API de Supabase.
  Future<List<Product>> getProducts(String token) async {
    final response = await _client.get(
      Uri.parse('$_appUrl?select=*'),
      headers: {'apikey': _apiKey, 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products: ${response.body}');
    }
  }

  @override
  /// Envia una petició DELETE per eliminar un producte identificat per [id].
  Future<void> eliminarProducte(String token, int id) async {
    final response = await _client.delete(
      Uri.parse('$_appUrl?id=eq.$id'),
      headers: {'apikey': _apiKey, 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }
}
