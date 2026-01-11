import 'dart:io';
import 'package:flutter/foundation.dart'; // Required to access 'kIsWeb' constant

/// Centralized configuration for Environment Variables and Endpoints.
/// 
/// This class handles the resolution of the host address depending on the 
/// running platform (Web, Android Emulator, or iOS/Desktop).
class Environment {
  
  /// Determines the appropriate host address.
  /// 
  /// Logic:
  /// 1. Web: Returns 'localhost' as it runs within the browser context.
  /// 2. Android Emulator: Returns '10.0.2.2' to bridge to the host machine's localhost.
  /// 3. Other (iOS/Desktop): Returns 'localhost'.
  /// 
  /// Note: 'kIsWeb' must be checked BEFORE 'Platform.isAndroid' to avoid 
  /// "Unsupported operation" errors in web builds, as 'dart:io' is not supported on the web.
  static String get _host {
    if (kIsWeb) {
      return 'localhost';
    }

    if (Platform.isAndroid) {
      return '10.0.2.2';
    }

    return 'localhost';
  }

  // ===========================================================================
  // Microservices Base URLs
  // All services are currently versioned under '/api/v1'
  // ===========================================================================

  /// Auth Service (Port 3000)
  static String get authBaseUrl => 'http://$_host:3000/api/v1';

  /// Patient Service (Port 3001)
  static String get patientBaseUrl => 'http://$_host:3001/api/v1';

  /// Appointment Service (Port 3002)
  static String get appointmentBaseUrl => 'http://$_host:3002/api/v1';

  /// Availability Service (Port 3003)
  static String get availabilityBaseUrl => 'http://$_host:3003/api/v1';
}