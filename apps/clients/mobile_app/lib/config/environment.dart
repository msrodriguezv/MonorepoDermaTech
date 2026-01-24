import 'dart:io';
import 'package:flutter/foundation.dart';

class Environment {
  
  // Centralized Gateway port configuration (Single Source of Truth)
  static const String gatewayPort = '3000';

  // Internal helper to determine the base URL based on the platform
  static String get _apiBaseUrl {
    if (kIsWeb) {
      // Web Production: Use relative path.
      // Nginx will handle the proxying to the internal API Gateway.
      return '/api/v1'; 
    }

    // Mobile/Desktop: Construct full URL pointing to the Gateway.
    // Android Emulator requires '10.0.2.2' to access the host localhost.
    String host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    
    return 'http://$host:$gatewayPort/api/v1';
  }

  // ===========================================================================
  // Microservices Base URLs
  // All services flow through the same API Gateway endpoint.
  // Suffixes (e.g., /auth, /patient) are removed here because 
  // the API Client or Interceptors append them dynamically.
  // ===========================================================================

  static String get authBaseUrl => _apiBaseUrl;

  static String get patientBaseUrl => _apiBaseUrl;

  static String get appointmentBaseUrl => _apiBaseUrl;

  static String get availabilityBaseUrl => _apiBaseUrl;
}