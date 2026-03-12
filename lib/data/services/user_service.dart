import 'dart:convert';

import 'package:api_amb_jwt/data/models/user.dart';
import 'package:http/http.dart' as http;

abstract class IUserService{
  Future<User> validateLogin(String email, String password);
}

// itvyvvxonnsdoqokvikw
class UserService implements IUserService {
  final http.Client _client;

  UserService({http.Client? client}) : _client = client ?? http.Client();

  @override
  //Aquest métode es el cridador de la api per poder validar el nostre usuari. En el meu cas, es el meu correu (pablomaso@iesebre.com) i contrasenya (flutter)
  /// Valida les credencials de l'usuari (email i contrasenya) contra l'API d'autenticació de Supabase.
  Future<User> validateLogin(String email, String password) async {
    final url = Uri.parse('https://itvyvvxonnsdoqokvikw.supabase.co/auth/v1/token?grant_type=password');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json',
      'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0dnl2dnhvbm5zZG9xb2t2aWt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0ODE1NTQsImV4cCI6MjA4MTA1NzU1NH0.6AxDj1flnnqtBvOjoKe9_MehqBwo0kNgxLGOf4VKQ5A'},
      body: jsonEncode({'email': email, 'password': password}),
      
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body)); // HTTP OK
    } else if (response.statusCode == 400) {
      final errorResponse = jsonDecode(response.body);
      throw Exception('${errorResponse['message']}'); // HTTP Bad Request
    } else {
      throw Exception('Login error'); // HTTP Error
    }
  }

}
