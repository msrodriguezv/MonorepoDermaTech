/// Data Transfer Object to parse the profile status response.
class ProfileStatusModel {
  final bool isProfileComplete;

  ProfileStatusModel({required this.isProfileComplete});

  factory ProfileStatusModel.fromJson(Map<String, dynamic> json) {
    return ProfileStatusModel(
      // Safely extracting the boolean, defaulting to false if null/missing
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
    );
  }
}