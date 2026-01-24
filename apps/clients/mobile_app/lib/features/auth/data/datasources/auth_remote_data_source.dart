import 'package:dio/dio.dart'; // Required for Options
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

/// Contract for authentication-related remote interactions.
abstract class AuthRemoteDataSource {
  /// Authenticates a user and returns the JWT tokens.
  Future<TokenResponseModel> login(LoginRequestModel request);

  /// Registers a new user (Student, Doctor, etc.) in the Auth Service.
  Future<void> register(RegisterRequestModel request);

  /// Invalidates the user session on the backend (Redis Blacklist).
  Future<void> logout(String token);
}

/// Implementation communicating with Auth Microservice (Port 3000).
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<TokenResponseModel> login(LoginRequestModel request) async {
    const url = '/auth/login';
    // The ApiClient handles the base URL and default headers.
    final response = await apiClient.post(url, request.toJson());
    return TokenResponseModel.fromJson(response.data);
  }

  @override
  Future<void> register(RegisterRequestModel request) async {
    const url = '/auth/register';
    await apiClient.post(url, request.toJson());
  }

  @override
  Future<void> logout(String token) async {
    // For logout, we manually inject the token to ensure the specific 
    // token being discarded is the one sent to the blacklist.
    // While the interceptor *could* do this, explicit control is safer for logout flows.
    await apiClient.post(
      '/auth/logout', 
      null, 
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}