import 'package:dio/dio.dart';
import 'package:dermatech_mobile/core/storage/storage_service.dart';
import '../../config/environment.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storage;        
  final Dio _dio;
  
  bool _isRefreshing = false;

  // Actualizar constructor para aceptar o instanciar StorageService
  AuthInterceptor(this._dio) : _storage = StorageService(); 

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Ahora _storage.read usa internamente SharedPreferences en Web, no fallará.
    final accessToken = await _storage.read(key: 'accessToken');

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refreshToken');

      if (refreshToken != null && !_isRefreshing) {
        _isRefreshing = true;

        try {
          final refreshDio = Dio(BaseOptions(baseUrl: Environment.authBaseUrl));
          
          final response = await refreshDio.post('/auth/refresh', data: {
            'refreshToken': refreshToken
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            final newAccessToken = response.data['accessToken'] ?? response.data['backendTokens']['accessToken'];
            final newRefreshToken = response.data['refreshToken'] ?? response.data['backendTokens']['refreshToken'];

            // Guardar nuevos tokens sin error
            await _storage.write(key: 'accessToken', value: newAccessToken);
            
            if (newRefreshToken != null) {
              await _storage.write(key: 'refreshToken', value: newRefreshToken);
            }

            _isRefreshing = false;

            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            
            final clonedRequest = await _dio.fetch(opts);
            return handler.resolve(clonedRequest);
          }
        } catch (e) {
          _isRefreshing = false;
          await _storage.deleteAll(); // Limpieza segura
        }
      }
    }
    return handler.next(err);
  }
}