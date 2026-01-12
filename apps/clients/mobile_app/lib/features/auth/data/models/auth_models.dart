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
class RegisterRequestModel {
  final String email;
  final String password;
  final String role; 

  RegisterRequestModel({
    required this.email,
    required this.password,
    this.role = 'STUDENT', 
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'role': role,
    };
  }
}

/// Data Transfer Object (DTO) for the Token Response.
/// 
/// Handles response parsing specifically for the NestJS structure,
/// including robust fallback strategies for token and role extraction.
class TokenResponseModel {
  final String accessToken;
  final String refreshToken;
  final String firstName;
  final String lastName;
  final String role; // <--- Field declared here

  TokenResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.firstName,
    required this.lastName,
    required this.role, // <--- FIX: Must be initialized here
  });

  /// Factory constructor to parse JSON data into a TokenResponseModel instance.
  factory TokenResponseModel.fromJson(Map<String, dynamic> json) {
    // 1. Determine the Root Payload
    // Prioritize 'json['data']' if the backend wraps the response (standard NestJS pattern).
    final Map<String, dynamic> payload = 
        (json['data'] != null && json['data'] is Map<String, dynamic>) 
        ? json['data'] 
        : json;

    // 2. Extract User Object (if nested)
    final user = payload['user'] ?? {}; 
    final backendTokens = payload['backendTokens'] ?? {};

    // 3. Access Token Extraction Strategy
    // Tries to find the access token in various common keys.
    String extractedAccess = '';
    
    if (payload['accessToken'] != null) {
      extractedAccess = payload['accessToken'];
    } else if (payload['access_token'] != null) {
      extractedAccess = payload['access_token'];
    } else if (backendTokens['accessToken'] != null) {
      extractedAccess = backendTokens['accessToken'];
    } else if (backendTokens['access_token'] != null) {
      extractedAccess = backendTokens['access_token'];
    }

    // 4. Refresh Token Extraction Strategy
    String extractedRefresh = '';
    
    if (payload['refreshToken'] != null) {
      extractedRefresh = payload['refreshToken'];
    } else if (payload['refresh_token'] != null) {
      extractedRefresh = payload['refresh_token'];
    } else if (backendTokens['refreshToken'] != null) {
      extractedRefresh = backendTokens['refreshToken'];
    } else if (backendTokens['refresh_token'] != null) {
      extractedRefresh = backendTokens['refresh_token'];
    }

    // 5. Role Extraction Strategy
    // Priorities: Root payload -> User object -> Default to STUDENT
    String extractedRole = 'STUDENT';
    if (payload['role'] != null) {
      extractedRole = payload['role'];
    } else if (user['role'] != null) {
      extractedRole = user['role'];
    }

    // 6. Return Normalized Model
    return TokenResponseModel(
      accessToken: extractedAccess,
      refreshToken: extractedRefresh,
      firstName: payload['firstName'] ?? user['firstName'] ?? 'Usuario',
      lastName: payload['lastName'] ?? user['lastName'] ?? '',
      role: extractedRole,
    );
  }
}