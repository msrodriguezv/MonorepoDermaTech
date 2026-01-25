import 'package:dio/dio.dart';
import '../storage/storage_service.dart';
import '../../config/environment.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storage = StorageService();
  final Dio _dio;

  bool _isRefreshing = false;

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'accessToken');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // ❌ No intentar refresh en endpoints de auth
    if (err.requestOptions.path.contains('/auth')) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refreshToken');

      if (refreshToken != null && !_isRefreshing) {
        _isRefreshing = true;

        try {
          final refreshDio = Dio(
            BaseOptions(baseUrl: Environment.apiGatewayBaseUrl),
          );

          final response = await refreshDio.post(
            '/api/v1/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newAccessToken = response.data['accessToken'];
          final newRefreshToken = response.data['refreshToken'];

          await _storage.write(
            key: 'accessToken',
            value: newAccessToken,
          );

          if (newRefreshToken != null) {
            await _storage.write(
              key: 'refreshToken',
              value: newRefreshToken,
            );
          }

          _isRefreshing = false;

          final RequestOptions opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';

          final Response retryResponse = await _dio.fetch(opts);
          return handler.resolve(retryResponse);
        } catch (_) {
          _isRefreshing = false;
          await _storage.deleteAll();
        }
      }
    }

    handler.next(err);
  }
}
