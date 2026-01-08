import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart'; // <--- Importamos el Local

class AuthRepositoryImpl {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource; // <--- Nueva dependencia

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// LOGIN: Conecta y guarda el token
  Future<void> login(String email, String password) async {
    // 1. Pide el token al Backend
    final response = await remoteDataSource.login(email, password);
    
    // 2. Extrae el token (Ajusta 'access_token' si tu backend usa ese nombre)
    // Intentamos leer 'token' o 'access_token' por si acaso.
    final token = response['token'] ?? response['access_token'];

    if (token != null) {
      // 3. Guárdalo en el celular de forma segura
      await localDataSource.saveToken(token);
      print("Token guardado exitosamente: $token"); // Debug
    } else {
      throw Exception("El backend no devolvió un token válido.");
    }
  }

  /// REGISTER: Crea usuario y guarda token (si el backend lo devuelve)
  Future<void> register(String email, String password, String fullName) async {
    final response = await remoteDataSource.register(email, password, fullName);
    
    final token = response['token'] ?? response['access_token'];
    
    if (token != null) {
      await localDataSource.saveToken(token);
    }
  }

  /// LOGOUT: Borra el token
  Future<void> logout() async {
    await localDataSource.deleteToken();
  }
}