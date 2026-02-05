import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dermatech_mobile/core/storage/storage_service.dart';
import '../../config/environment.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final StorageService _storage;
  
  // Semaphore to handle concurrent refresh requests
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  AuthInterceptor(this._dio) : _storage = StorageService();

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await _storage.read(key: 'accessToken');

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // If a refresh is already in progress, wait for it to complete
      if (_isRefreshing) {
        if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
          await _refreshCompleter!.future;
        }
        return _retry(err, handler);
      }

      // Start the refresh process
      _isRefreshing = true;
      _refreshCompleter = Completer<void>();

      try {
        final refreshToken = await _storage.read(key: 'refreshToken');

        if (refreshToken == null) {
          await _performLogout(handler, err);
          return;
        }

        // Use a separate Dio instance to avoid circular interceptors
        final tokenDio = Dio(BaseOptions(baseUrl: Environment.authBaseUrl));
        
        // Backend expects { "refreshToken": "..." }
        final response = await tokenDio.post('/auth/refresh', data: {
          'refreshToken': refreshToken
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          // --- CORRECCIÓN CRÍTICA AQUÍ ---
          final responseData = response.data;
          
          // Tu backend envuelve la respuesta en 'data', así que buscamos ahí primero.
          // Estructura: { success: true, message: "...", data: { accessToken: "..." } }
          final tokensData = responseData['data'] ?? responseData;

          final newAccessToken = tokensData['accessToken'];
          final newRefreshToken = tokensData['refreshToken'];

          if (newAccessToken != null) {
            await _storage.write(key: 'accessToken', value: newAccessToken);
          } else {
            // Si el backend dice OK pero no hay token, algo está muy mal -> Logout
            throw Exception("Access Token not found in refresh response");
          }
          
          if (newRefreshToken != null) {
            await _storage.write(key: 'refreshToken', value: newRefreshToken);
          }

          // Complete the semaphore to let waiting requests proceed
          _isRefreshing = false;
          _refreshCompleter?.complete();
          
          // Retry the original failed request
          return _retry(err, handler);
        } else {
          await _performLogout(handler, err);
        }
      } catch (e) {
        // Si el refresh falla (ej: refresh token expirado), hacemos logout forzoso
        await _performLogout(handler, err);
      } finally {
        _isRefreshing = false;
        if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete();
        }
      }
    } else {
      return handler.next(err);
    }
  }

  /// Helper method to retry the failed request with the new token
  Future<void> _retry(DioException err, ErrorInterceptorHandler handler) async {
    try {
      final newAccessToken = await _storage.read(key: 'accessToken');
      
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccessToken';

      final clonedRequest = await _dio.fetch(opts);
      return handler.resolve(clonedRequest);
    } catch (e) {
      return handler.next(err);
    }
  }

  /// Clears storage and propagates the error to trigger UI logout
  Future<void> _performLogout(ErrorInterceptorHandler handler, DioException err) async {
    await _storage.deleteAll();
    // Propagamos el error para que la UI (router) detecte el estado y redirija a Login
    return handler.next(err);
  }
}