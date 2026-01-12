import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/environment.dart';

/// Interceptor responsible for injecting the Authorization header
/// and handling automatic token refresh upon 401 Unauthorized errors.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  
  // Semaphore to prevent multiple concurrent refresh requests
  bool _isRefreshing = false;

  AuthInterceptor(this._storage, this._dio);

  /// Intercepts outgoing requests to inject the Access Token.
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await _storage.read(key: 'accessToken');

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  /// Intercepts errors to handle token expiration (401).
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refreshToken');

      // Attempt refresh only if a refresh token exists and a refresh is not already in progress
      if (refreshToken != null && !_isRefreshing) {
        _isRefreshing = true;

        try {
          // Create a dedicated Dio instance for the refresh call to avoid circular dependencies
          final refreshDio = Dio(BaseOptions(baseUrl: Environment.authBaseUrl));
          
          final response = await refreshDio.post('/auth/refresh', data: {
            'refreshToken': refreshToken
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Extract new tokens from response
            // Adjust key names based on exact Backend DTO structure
            final newAccessToken = response.data['accessToken'] ?? response.data['backendTokens']['accessToken'];
            final newRefreshToken = response.data['refreshToken'] ?? response.data['backendTokens']['refreshToken'];

            // Update local storage with fresh tokens
            await _storage.write(key: 'accessToken', value: newAccessToken);
            
            if (newRefreshToken != null) {
              await _storage.write(key: 'refreshToken', value: newRefreshToken);
            }

            _isRefreshing = false;

            // Retry the original failed request with the new token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            
            final clonedRequest = await _dio.fetch(opts);
            return handler.resolve(clonedRequest);
          }
        } catch (e) {
          _isRefreshing = false;
          // If refresh fails, clear storage to force a clean login flow
          await _storage.deleteAll();
        }
      }
    }
    return handler.next(err);
  }
}