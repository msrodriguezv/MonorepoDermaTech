import 'package:dio/dio.dart';
import '../../config/environment.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        // ✅ SIEMPRE EL API GATEWAY
        baseUrl: Environment.apiGatewayBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ✅ Interceptor JWT
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path,
    dynamic data, {
    Options? options,
  }) {
    return _dio.post(path, data: data, options: options);
  }

  Future<Response> put(
    String path,
    dynamic data, {
    Options? options,
  }) {
    return _dio.put(path, data: data, options: options);
  }

  Future<Response> delete(
    String path, {
    Options? options,
  }) {
    return _dio.delete(path, options: options);
  }
}
