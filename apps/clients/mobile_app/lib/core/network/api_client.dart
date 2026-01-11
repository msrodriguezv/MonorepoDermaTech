import 'package:dio/dio.dart';

/// A generic HTTP client wrapper around Dio.
/// 
/// Responsibilities:
/// - Provides a singleton-like configuration for HTTP requests.
/// - Handles global timeouts and default headers.
/// - Standardizes error handling logic for the application.
class ApiClient {
  final Dio _dio;

  ApiClient()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  /// Performs a POST request to the specified [path].
  /// 
  /// [data] - The body of the request (usually a Map/JSON).
  /// [queryParameters] - Optional query parameters.
  /// 
  /// Throws a [DioException] if the request fails.
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs a GET request to the specified [path].
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Parses [DioException] and returns a user-friendly or domain-specific exception.
  /// 
  /// This ensures that the UI layer receives processed error messages 
  /// rather than raw HTTP status codes.
  Exception _handleError(DioException error) {
    if (error.response != null) {
      // Extract the error message from the backend standard response (ApiResponse)
      final errorMessage = error.response?.data['message'] ?? 'Unknown server error';
      return Exception('Server Error (${error.response?.statusCode}): $errorMessage');
    } else {
      return Exception('Connection Error: Unable to reach the server. Please check your internet connection or service status.');
    }
  }
}