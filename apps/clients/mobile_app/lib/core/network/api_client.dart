import 'package:dio/dio.dart';
import '../../config/environment.dart';
import 'auth_interceptor.dart'; 

class ApiClient {
  late final Dio _dio;
  
  ApiClient() {
    // 1. Initialize Dio
    _dio = Dio(BaseOptions(
      baseUrl: Environment.authBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 2. Register the Interceptor
    // Ahora solo pasamos '_dio'. El interceptor ya sabe cómo buscar el token
    // usando el StorageService internamente.
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  // --- Wrapper Methods ---

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path, dynamic data, {Options? options}) async {
    return _dio.post(path, data: data, options: options);
  }

  Future<Response> put(String path, dynamic data, {Options? options}) async {
    return _dio.put(path, data: data, options: options);
  }

  Future<Response> delete(String path, {Options? options}) async {
    return _dio.delete(path, options: options);
  }
}