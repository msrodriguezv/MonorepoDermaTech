import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/appointment_model.dart';

abstract class AuthRemoteDataSource {
  Future<TokenResponseModel> login(LoginRequestModel request);
  Future<void> register(RegisterRequestModel request);
  Future<void> logout(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<TokenResponseModel> login(LoginRequestModel request) async {
    const url = '/auth/login';
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
    // Explicit Authorization header for Logout to ensure correct token invalidation
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