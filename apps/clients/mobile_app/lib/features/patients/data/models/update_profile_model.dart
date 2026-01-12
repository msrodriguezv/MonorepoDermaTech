/// Model representing the JSON body required by NestJS to update the profile.
class UpdateProfileModel {
  final String firstName;
  final String lastName;
  final String birthDate; // Format: YYYY-MM-DD
  final String phone;
  final String faculty;
  final String career;
  final int currentSemester;
  final String? avatarUrl;
  final String? insuranceProvider;
  final String bloodType; // Part of MedicalInfo
  final List<String>? allergies; // Part of MedicalInfo
  final List<String>? chronicConditions; // Part of MedicalInfo

  UpdateProfileModel({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.phone,
    required this.faculty,
    required this.career,
    required this.currentSemester,
    this.avatarUrl,
    this.insuranceProvider,
    required this.bloodType,
    this.allergies,
    this.chronicConditions,
  });

  /// Converts the model to the exact JSON structure expected by the Backend DTO.
  Map<String, dynamic> toJson() {
    return {
      "firstName": firstName,
      "lastName": lastName,
      "birthDate": birthDate,
      "phone": phone,
      "faculty": faculty,
      "career": career,
      "current_semester": currentSemester,
      "avatarUrl": avatarUrl,
      "insuranceProvider": insuranceProvider,
      // IMPORTANT: Mapping flat fields to the nested 'medicalInfo' expected by the Entity/DTO?
      // Based on your JSON example, if your backend DTO expects a flat structure that maps internally, use this.
      // If your backend expects explicit nesting, use the commented version below.
      
      // OPTION A: Flat structure (As per your provided JSON example)
      "bloodType": bloodType,
      "allergies": allergies ?? [],
      "chronicConditions": chronicConditions ?? [],

      // OPTION B: Nested structure (If Entity uses JSONB directly from body)
      // "medicalInfo": {
      //   "bloodType": bloodType,
      //   "allergies": allergies ?? [],
      //   "chronicConditions": chronicConditions ?? []
      // }
    };
  }
}