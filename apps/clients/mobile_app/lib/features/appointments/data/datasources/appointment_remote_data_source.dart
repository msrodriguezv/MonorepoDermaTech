import '../../../../core/network/api_client.dart';
import '../models/appointment_model.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<dynamic>> getDoctors();
  Future<List<String>> getAvailability(String doctorId, String date);
  Future<void> createAppointment({
    required String doctorId,
    required String date,
    required String time,
    required String symptoms,
  });
  Future<List<AppointmentModel>> getMyAppointments();
  Future<void> cancelAppointment(String appointmentId);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final ApiClient apiClient;

  AppointmentRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<dynamic>> getDoctors() async {
    const url = '/doctors'; 
    final response = await apiClient.get(url);
    
    if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'];
    }
    return response.data; 
  }

  @override
  Future<List<String>> getAvailability(String doctorId, String date) async {
    const url = '/availability';
    final response = await apiClient.get(url, queryParameters: {
      'doctorId': doctorId,
      'date': date, 
    });

    if (response.data is Map) {
      final dataObj = response.data['data'];
      if (dataObj != null && dataObj is Map && dataObj['availableSlots'] != null) {
         return List<String>.from(dataObj['availableSlots']);
      }
    }
    
    return []; 
  }

  @override
  Future<void> createAppointment({
    required String doctorId,
    required String date,
    required String time,
    required String symptoms,
  }) async {
    const url = '/appointments';
    
    final isoStartTime = "${date}T$time:00"; 

    await apiClient.post(url, {
      'doctorId': doctorId,
      'startTime': isoStartTime,
      'symptoms': symptoms,
    });
  }

  @override
  Future<List<AppointmentModel>> getMyAppointments() async {
    const url = '/appointments/my-history';
    final response = await apiClient.get(url);
    
    List<dynamic> listData = [];
    
    if (response.data is Map && response.data.containsKey('data')) {
       listData = response.data['data'];
    } else if (response.data is List) {
       listData = response.data;
    }

    return listData
        .map((json) => AppointmentModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    final url = '/appointments/$appointmentId/cancel';
    await apiClient.patch(url, {}); 
  }
}