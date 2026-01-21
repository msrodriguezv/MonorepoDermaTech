import 'dart:io';
import 'package:flutter/foundation.dart';

class Environment {
  
  // En Web, usamos rutas relativas para que Nginx maneje el proxy.
  // En Móvil, necesitamos la URL completa.
  static String getBaseUrl(String servicePort) {
    if (kIsWeb) {
      // RETORNO CLAVE:
      // Dejamos que Nginx redirija '/api' al puerto 3000 internamente via Docker network.
      // No ponemos http://localhost ni puerto.
      return '/api/v1'; 
    }

    // Lógica para Android Emulator vs iOS/Desktop
    String host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    
    // En móvil sí necesitamos apuntar al puerto específico del Gateway o servicio
    // (Asumiendo que en local tienes el gateway en el 3000)
    return 'http://$host:3000/api/v1';
  }

  // ===========================================================================
  // Microservices Base URLs
  // Ahora todos apuntan al mismo Gateway (Puerto 3000) o Nginx Proxy (/api)
  // ===========================================================================

  static String get authBaseUrl => '${getBaseUrl('3000')}/auth';
  static String get patientBaseUrl => '${getBaseUrl('3000')}/patient';
  static String get appointmentBaseUrl => '${getBaseUrl('3000')}/appointment';
  static String get availabilityBaseUrl => '${getBaseUrl('3000')}/availability';
}