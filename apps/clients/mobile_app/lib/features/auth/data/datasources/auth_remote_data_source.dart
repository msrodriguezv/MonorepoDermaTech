import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({required this.dio});

  // ⚠️ IMPORTANTE: Ajusta tu IP según corresponda
  // Android Emulator: 'http://10.0.2.2:3000/api'
  // Web: 'http://localhost:3000/api'
  final String baseUrl = 'http://10.0.2.2:3000/api'; 

  /// LOGIN
  Future<dynamic> login(String email, String password) async {
    try {
      final response = await dio.post(
        '$baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Error de credenciales');
      } else {
        throw Exception('Error de conexión con el servidor');
      }
    }
  }

  /// REGISTRO
  Future<dynamic> register(String email, String password, String fullName) async {
    try {
      final response = await dio.post(
        '$baseUrl/auth/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Error al registrarse');
      } else {
        throw Exception('Error de conexión');
      }
    }
  }
}