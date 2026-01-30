import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// --- CORE & ARCHITECTURE IMPORTS ---
import '../../../../core/network/api_client.dart';

// --- DTO MODELS ---
import '../models/profile_status_model.dart';
import '../models/update_profile_model.dart';
import '../models/patient_profile_model.dart';
import '../../../appointments/data/models/appointment_model.dart';

abstract class PatientRemoteDataSource {
  Future<ProfileStatusModel> getProfileStatus();
  Future<void> updateProfile(UpdateProfileModel profileData);
  Future<PatientProfileModel> getPatientProfile();
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final ApiClient apiClient;

  PatientRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProfileStatusModel> getProfileStatus() async {
    const url = '/patients/profile/status';
    
    final response = await apiClient.get(url);

    final data = response.data['data'] ?? response.data;
    return ProfileStatusModel.fromJson(data);
  }

  @override
  Future<void> updateProfile(UpdateProfileModel profileData) async {
    const url = '/patients/me';
    
    try {
      await apiClient.put(
        url,
        profileData.toJson(),
      );
    } catch (error) {
      if (error is DioException) {
         final backendMessage = error.response?.data['message'] ?? 'Failed to update profile';
         throw Exception(backendMessage);
      }
      rethrow;
    }
  }

  @override
  Future<PatientProfileModel> getPatientProfile() async {
    const url = '/patients/me';
    
    try {
      final response = await apiClient.get(url);

      final data = response.data['data'] ?? response.data;
      return PatientProfileModel.fromJson(data);
    } catch (error) {
       if (error is DioException) {
         final backendMessage = error.response?.data['message'] ?? 'Failed to load profile';
         throw Exception(backendMessage);
       }
       rethrow;
    }
  }

  Future<List<AppointmentModel>> getMyAppointments() async {
    try {
      // Usamos la URL base de environment (asegúrate de que apunte a /appointments)
      // Si tu gateway separa servicios, ajusta la ruta. 
      // Asumo: GET /appointments/my-history
      final response = await apiClient.get('/appointments/my-history');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => AppointmentModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      debugPrint(" Error fetching appointments: $e");
      return [];
    }
  }
}