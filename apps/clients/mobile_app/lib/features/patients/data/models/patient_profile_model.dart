/// Data Transfer Object (DTO) representing the Patient Profile fetched from the server.
class PatientProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String faculty;
  final String career;
  final int currentSemester;
  final String bloodType;

  PatientProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.faculty,
    required this.career,
    required this.currentSemester,
    required this.bloodType,
  });

  /// Factory method to parse JSON response from GET /patients/me
  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      faculty: json['faculty'] ?? 'No asignada',
      career: json['career'] ?? 'No asignada',
      // Handles both string or int input for semester to be safe1
      currentSemester: int.tryParse(json['current_semester']?.toString() ?? '1') ?? 1,
      bloodType: json['bloodType'] ?? 'N/A',
    );
  }

  /// Helper getter to generate a display code (e.g., QR Code label)
  String get studentCode => "STU-${id.substring(0, 5).toUpperCase()}";
  
  /// Helper getter for full name
  String get fullName => "$firstName $lastName";
}