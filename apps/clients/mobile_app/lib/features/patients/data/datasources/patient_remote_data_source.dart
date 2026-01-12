import 'package:dio/dio.dart';

// --- CORE & ARCHITECTURE IMPORTS ---
import '../../../../core/network/api_client.dart';
import '../../../../config/environment.dart';

// --- DTO MODELS ---
import '../models/profile_status_model.dart';
import '../models/update_profile_model.dart';
import '../models/patient_profile_model.dart';

/// Contract for patient-related remote interactions.
/// Defines the methods required to communicate with the Patient Microservice.
abstract class PatientRemoteDataSource {
  /// Checks if the patient has completed their mandatory profile data.
  /// The Access Token is automatically injected by the AuthInterceptor.
  Future<ProfileStatusModel> getProfileStatus();

  /// Updates the patient's personal, academic, and medical information.
  /// The Access Token is automatically injected by the AuthInterceptor.
  Future<void> updateProfile(UpdateProfileModel profileData);
}

/// Implementation communicating with Patient Microservice (Port 3001).
/// Relies on ApiClient (and its Interceptor) for authentication details.
class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final ApiClient apiClient;

  PatientRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProfileStatusModel> getProfileStatus() async {
    // Endpoint: GET http://localhost:3001/api/v1/patients/profile/status
    // Uses 'patientBaseUrl' to target the specific microservice port.
    final url = '${Environment.patientBaseUrl}/patients/profile/status';
    
    // HTTP Request:
    // No manual headers needed. The AuthInterceptor handles the Bearer Token injection.
    final response = await apiClient.get(url);

    // Response Parsing:
    // Handles NestJS standard response structure { "data": ... } or direct payload.
    final data = response.data['data'] ?? response.data;
    return ProfileStatusModel.fromJson(data);
  }

  @override
  Future<void> updateProfile(UpdateProfileModel profileData) async {
    // Endpoint: PUT http://localhost:3001/api/v1/patients/me
    final url = '${Environment.patientBaseUrl}/patients/me';
    
    // HTTP Request Execution:
    // We pass the DTO directly. The Interceptor injects the Token.
    // Error handling is managed here to return readable messages to the UI.
    try {
      await apiClient.put(
        url,
        profileData.toJson(), // Serializes the DTO to JSON
      );
    } catch (error) {
      // Error Handling:
      // Intercepts DioExceptions to extract the specific error message sent by the Backend.
      if (error is DioException) {
         final backendMessage = error.response?.data['message'] ?? 'Failed to update profile';
         throw Exception(backendMessage);
      }
      // Re-throw unexpected Dart exceptions to be handled by the UI layer
      rethrow;
    }
  }

  @override
  Future<PatientProfileModel> getPatientProfile() async {
    final url = '${Environment.patientBaseUrl}/patients/me';
    
    try {
      // The AuthInterceptor automatically injects the Bearer Token.
      final response = await apiClient.get(url);

      // Parse response. Assuming NestJS structure { data: { ... } } or direct JSON.
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
}