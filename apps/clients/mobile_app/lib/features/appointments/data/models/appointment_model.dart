class AppointmentModel {
  final String id;
  final DateTime date;
  final String status;
  final String doctorName;
  final String type;

  AppointmentModel({
    required this.id,
    required this.date,
    required this.status,
    required this.doctorName,
    required this.type,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'UNKNOWN',
      doctorName: json['doctorName'] ?? 'Por asignar',
      type: json['type'] ?? 'Consulta',
    );
  }
}