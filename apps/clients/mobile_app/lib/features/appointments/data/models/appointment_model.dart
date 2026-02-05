import 'package:intl/intl.dart';

class AppointmentModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String doctorName;
  final String doctorSpecialty;
  final String doctorLicense;
  final String symptoms;
  final String type;

  AppointmentModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.doctorLicense,
    required this.symptoms,
    required this.type,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    String docName = 'Por asignar';
    String docSpec = 'General';
    String docLic = '';

    if (json['doctor'] != null && json['doctor'] is Map) {
      final doc = json['doctor'];
      final first = doc['firstName'] ?? '';
      final last = doc['lastName'] ?? '';
      docName = "$first $last".trim();
      docSpec = doc['specialization'] ?? doc['specialty'] ?? 'General';
      docLic = doc['licenseNumber'] ?? doc['license_number'] ?? '';
    } else if (json['doctorName'] != null) {
      docName = json['doctorName'];
    }

    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(minutes: 30));

    final rawStart = json['startTime'] ?? json['start_time'] ?? json['date'];
    final rawEnd = json['endTime'] ?? json['end_time'];

    if (rawStart != null) {
      String cleanStart = rawStart.toString();
      if (cleanStart.endsWith('Z')) {
        cleanStart = cleanStart.substring(0, cleanStart.length - 1);
      }

      if (cleanStart.contains('+')) {
        cleanStart = cleanStart.split('+')[0];
      }
      
      start = DateTime.parse(cleanStart);
      
      if (rawEnd != null) {
        String cleanEnd = rawEnd.toString();
        if (cleanEnd.endsWith('Z')) {
          cleanEnd = cleanEnd.substring(0, cleanEnd.length - 1);
        }
        if (cleanEnd.contains('+')) {
          cleanEnd = cleanEnd.split('+')[0];
        }
        end = DateTime.parse(cleanEnd);
      } else {
        end = start.add(const Duration(minutes: 30));
      }
    }

    return AppointmentModel(
      id: json['appointment_id']?.toString() ?? json['id']?.toString() ?? '',
      startTime: start,
      endTime: end,
      status: json['status'] ?? 'UNKNOWN',
      doctorName: docName.isEmpty ? 'Por asignar' : docName,
      doctorSpecialty: docSpec,
      doctorLicense: docLic,
      symptoms: json['symptoms'] ?? 'Sin descripción',
      type: json['type'] ?? 'Consulta',
    );
  }

  String get formattedDate => DateFormat('dd MMM, yyyy', 'es').format(startTime);

  String get formattedTimeRange {
    final start = DateFormat('hh:mm a').format(startTime);
    final end = DateFormat('hh:mm a').format(endTime);
    return "$start - $end";
  }
}