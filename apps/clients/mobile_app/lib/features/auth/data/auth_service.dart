import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../config/environment.dart';

/// Service responsible for handling authentication API requests.
class AuthService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  AuthService() {
    // Configure base URL from environment config
    _dio.options.baseUrl = Environment.apiUrl;
    
    // Set default headers if necessary
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Authenticates a user with email and password.
  /// 
  /// Returns `null` on success, or an `String` error message on failure.
  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      // Extract access token from response
      // Assuming backend structure: { "access_token": "eyJ..." }
      final token = response.data['access_token']; 
      
      // Persist token securely
      await _storage.write(key: 'jwt_token', value: token);
      
      return null; // Success
    } on DioException catch (e) {
      // Handle Dio-specific errors (4xx, 5xx)
      if (e.response != null) {
        // Return backend error message if available
        return e.response?.data['message'] ?? 'Credenciales incorrectas';
      }
      return 'Error de conexión con el servidor';
    } catch (e) {
      // Handle unexpected errors
      return 'Error inesperado: $e';
    }
  }

  /// Registers a new patient.
  /// 
  /// This typically hits the Auth Service or Patient Service depending on architecture.
  Future<String?> register(String fullName, String email, String password) async {
    try {
      // POST request to register endpoint
      await _dio.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': 'patient' // Explicitly setting role
      });
      return null; // Success
    } on DioException catch (e) {
      return e.response?.data['message'] ?? 'Error al registrarse';
    } catch (e) {
      return 'Error inesperado al registrar';
    }
  }

  /// Clears the stored session token.
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
}