/// Data Transfer Object (DTO) for the Login Request.
class LoginRequestModel {
  final String email;
  final String password;

  LoginRequestModel({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Data Transfer Object (DTO) for the Register Request.
/// UPDATED: Matched strictly to the Backend ValidationPipe requirements.
/// Removed 'firstName', 'lastName' (not accepted by Auth Service).
/// Changed 'roles' (array) to 'role' (singular Enum string).
class RegisterRequestModel {
  final String email;
  final String password;
  final String role; // Changed from List<String> roles to String role

  RegisterRequestModel({
    required this.email,
    required this.password,
    this.role = 'STUDENT', // Default to uppercase Enum value
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'role': role, // Sending singular field as expected by Backend DTO
    };
  }
}

/// Data Transfer Object (DTO) for the Token Response.
class TokenResponseModel {
  final String accessToken;
  final String refreshToken;
  final String firstName;
  final String lastName;

  TokenResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.firstName,
    required this.lastName,
  });

  factory TokenResponseModel.fromJson(Map<String, dynamic> json) {
    // Handling nested user object if present, or flat structure
    final user = json['user'] ?? {}; 
    
    return TokenResponseModel(
      accessToken: json['accessToken'] ?? json['backendTokens']?['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? json['backendTokens']?['refreshToken'] ?? '',
      // Fallback to "Usuario" if names are not yet set in profile
      firstName: json['firstName'] ?? user['firstName'] ?? 'Usuario',
      lastName: json['lastName'] ?? user['lastName'] ?? '',
    );
  }
}