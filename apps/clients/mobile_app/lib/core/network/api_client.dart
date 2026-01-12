import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/environment.dart';
import 'auth_interceptor.dart'; 

class ApiClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    // 1. Initialize Dio
    _dio = Dio(BaseOptions(
      baseUrl: Environment.authBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 2. Register the Interceptor (MUST BE INSIDE THE CONSTRUCTOR)
    _dio.interceptors.add(AuthInterceptor(_storage, _dio));
  }

  // --- Wrapper Methods ---

  Future<Response> get(String path, {Options? options}) async {
    return _dio.get(path, options: options);
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