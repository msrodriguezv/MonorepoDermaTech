import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookingService {
  static const String baseUrl = 'http://dermatech-qa-alb-868632428.us-east-1.elb.amazonaws.com/api/v1';

  // 1. Obtener Doctores
  Future<List<dynamic>> getDoctors() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/doctors'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      // Validación: Si viene envuelto en { "data": [...] } lo extraemos
      if (data is Map && data.containsKey('data')) {
        return data['data'];
      } else if (data is List) {
        return data;
      }
      return [];
    } else {
      throw Exception('Error cargando doctores: ${response.statusCode}');
    }
  }

  // 2. Obtener Disponibilidad )
  Future<List<String>> getAvailability(String doctorId, String date) async {
    final token = await _getToken();
    
    final uri = Uri.parse('$baseUrl/availability').replace(queryParameters: {
      'doctorId': doctorId,
      'date': date,
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);

      if (jsonResponse is Map) {
        if (jsonResponse.containsKey('data') && 
            jsonResponse['data'] is Map && 
            jsonResponse['data']['availableSlots'] != null) {
          return List<String>.from(jsonResponse['data']['availableSlots']);
        } 
        else if (jsonResponse.containsKey('availableSlots')) {
          return List<String>.from(jsonResponse['availableSlots']);
        }
      }
      return [];
    } else {
      throw Exception('Error cargando horarios: ${response.statusCode}');
    }
  }

  // 3. Crear Cita
  Future<void> createAppointment(String doctorId, String dateStr, String timeStr, String symptoms) async {
    final token = await _getToken();
    final dateTimeIso = "${dateStr}T$timeStr:00.000Z";

    final response = await http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'doctorId': doctorId,
        'startTime': dateTimeIso,
        'symptoms': symptoms
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error creando cita: ${response.body}');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken') ?? '';
  }
}