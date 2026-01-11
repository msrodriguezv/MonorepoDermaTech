import '../../../../config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

/// Contract for the Auth Remote Data Source.
abstract class AuthRemoteDataSource {
  Future<TokenResponseModel> login(LoginRequestModel request);
  Future<void> register(RegisterRequestModel request);
}

/// Implementation of [AuthRemoteDataSource].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<TokenResponseModel> login(LoginRequestModel request) async {
    final url = '${Environment.authBaseUrl}/auth/login';
    final response = await apiClient.post(url, data: request.toJson());
    // Extract 'data' field from standard API response
    final responseData = response.data['data']; 
    return TokenResponseModel.fromJson(responseData);
  }

  @override
  Future<void> register(RegisterRequestModel request) async {
    final url = '${Environment.authBaseUrl}/auth/register';
    // We don't expect a token return here immediately, just a 201 Created.
    await apiClient.post(url, data: request.toJson());
  }
}