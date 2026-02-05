import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Importante para manejar DioException
import '../../../../core/network/api_client.dart';
import '../../../appointments/data/datasources/appointment_remote_data_source.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  late AppointmentRemoteDataSourceImpl _appointmentDataSource;
  
  final _symptomsController = TextEditingController();

  List<dynamic> _doctors = [];
  bool _isLoadingDoctors = true;

  // Variables de selección
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  String? _selectedDoctorSpecialty;
  String? _selectedDoctorLicense;

  DateTime? _selectedDate;

  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _appointmentDataSource = AppointmentRemoteDataSourceImpl(apiClient: apiClient);
    _fetchDoctors();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await _appointmentDataSource.getDoctors();
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoadingDoctors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDoctors = false);
        _showError("No pudimos cargar la lista de especialistas.");
      }
    }
  }

  Future<void> _fetchAvailability() async {
    if (_selectedDoctorId == null || _selectedDate == null) return;

    setState(() {
      _isLoadingSlots = true;
      _availableSlots = [];
      _selectedTime = null;
    });

    final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

    try {
      final slots = await _appointmentDataSource.getAvailability(_selectedDoctorId!, dateStr);
      
      // LÓGICA DE NEGOCIO (Frontend): Filtrar horarios pasados si es HOY
      final filteredSlots = _filterPastSlots(slots);

      if (mounted) {
        setState(() {
          _availableSlots = filteredSlots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
        _showError("Error consultando disponibilidad.");
      }
    }
  }

  // ✅ MÉTODO NUEVO: Filtra los slots que ya pasaron
  List<String> _filterPastSlots(List<String> slots) {
    if (_selectedDate == null) return slots;

    final now = DateTime.now();
    // Verificamos si la fecha seleccionada es HOY (ignorando la hora)
    final isToday = _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    if (!isToday) return slots; // Si es mañana o después, mostramos todo

    List<String> validSlots = [];
    
    // Obtenemos la hora actual (Ej: 14:30)
    final currentHour = now.hour;
    final currentMinute = now.minute;

    for (var slot in slots) {
      // Parseamos el slot "09:30" -> 9 y 30
      final parts = slot.split(':');
      final slotHour = int.parse(parts[0]);
      final slotMinute = int.parse(parts[1]);

      // Regla: El slot debe ser MAYOR a la hora actual
      if (slotHour > currentHour) {
        validSlots.add(slot);
      } else if (slotHour == currentHour && slotMinute > currentMinute) {
        validSlots.add(slot);
      }
    }
    
    return validSlots;
  }

  Future<void> _processBooking() async {
    if (_symptomsController.text.trim().isEmpty) {
      _showError("Por favor describe tus síntomas antes de continuar.");
      return;
    }

    Navigator.pop(context); // Cierra diálogo

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

    try {
      await _appointmentDataSource.createAppointment(
        doctorId: _selectedDoctorId!,
        date: dateStr,
        time: _selectedTime!,
        symptoms: _symptomsController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // Cierra loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Cita agendada exitosamente"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Regresa al Dashboard
      }
    } on DioException catch (e) {
      // ✅ MANEJO DE ERRORES PROFESIONAL (UX)
      if (mounted) Navigator.pop(context); // Cierra loading

      if (e.response?.statusCode == 409) {
        // Caso: Alguien ganó el slot hace milisegundos
        _showError("⚠️ Lo sentimos, ese horario acaba de ser reservado.");
        // Refrescamos la lista automáticamente para que desaparezca el slot ocupado
        _fetchAvailability();
      } else {
        _showError("No se pudo agendar la cita. Inténtalo de nuevo.");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Ocurrió un error inesperado.");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.red.shade700, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Agendar Cita", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A2342),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("1. Elige tu Especialista", Icons.person_search),
            const SizedBox(height: 15),
            
            if (_isLoadingDoctors)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_doctors.isEmpty)
              const Center(child: Text("No hay doctores disponibles."))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _doctors.length,
                itemBuilder: (context, index) {
                  return _buildDoctorCard(_doctors[index]);
                },
              ),

            const SizedBox(height: 30),
            _sectionHeader("2. Describe tus síntomas", Icons.medical_information),
            const SizedBox(height: 10),
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: "Ej: Dolor de cabeza intenso, fiebre desde ayer...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8))),
              ),
            ),
            
            const SizedBox(height: 30),
            _sectionHeader("3. Elige una Fecha", Icons.calendar_month),
            const SizedBox(height: 15),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedDate == null ? Colors.grey.shade300 : const Color(0xFF00A8E8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? "Seleccionar día"
                          : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null ? Colors.grey : const Color(0xFF0A2342),
                        fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            
            if (_selectedDate != null) ...[
              _sectionHeader("4. Horarios Disponibles", Icons.access_time),
              const SizedBox(height: 15),
              if (_isLoadingSlots)
                const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
              else if (_availableSlots.isEmpty)
                // Aquí es donde se mostrará el mensaje si ya es tarde (ej: 7 PM)
                Container(
                  padding: const EdgeInsets.all(15),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text("No hay horarios disponibles para esta fecha.", style: TextStyle(color: Colors.orange)),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableSlots.map((time) => _buildTimeChip(time)).toList(),
                )
            ],

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_selectedDoctorId != null && _selectedTime != null && _symptomsController.text.isNotEmpty)
                    ? _confirmAppointment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A8E8),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("CONFIRMAR CITA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ... WIDGETS AUXILIARES IGUALES ...

  Widget _buildDoctorCard(dynamic doctor) {
    final firstName = doctor['firstName'] ?? '';
    final lastName = doctor['lastName'] ?? '';
    final docName = "$firstName $lastName".trim();
    final docSpecialty = doctor['specialization'] ?? doctor['specialty'] ?? 'Medicina General';
    final docLicense = doctor['license_number'] ?? doctor['licenseNumber'] ?? 'N/A';
    final docId = doctor['id'];
    final isSelected = _selectedDoctorId == docId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDoctorId = docId;
          _selectedDoctorName = docName;
          _selectedDoctorSpecialty = docSpecialty;
          _selectedDoctorLicense = docLicense;
          _selectedDate = null;
          _selectedTime = null;
          _availableSlots = [];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE1F5FE) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? const Color(0xFF00A8E8) : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isSelected ? const Color(0xFF00A8E8) : Colors.grey[200],
              child: Icon(Icons.person, size: 35, color: isSelected ? Colors.white : Colors.grey[600]),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(docName.isEmpty ? 'Doctor' : docName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? const Color(0xFF0A2342) : Colors.black)),
                  const SizedBox(height: 2),
                  Text(docSpecialty, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: isSelected ? const Color(0xFFB3E5FC) : Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                    child: Text("Lic: $docLicense", style: TextStyle(fontSize: 10, color: isSelected ? const Color(0xFF0277BD) : Colors.grey[600], fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF00A8E8)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Primero selecciona un médico."), backgroundColor: Colors.orange));
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); 

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today, 
      firstDate: today, 
      lastDate: today.add(const Duration(days: 30)),
  
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A2342),
              onPrimary: Colors.white, 
              onSurface: Color(0xFF0A2342), 
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchAvailability();
    }
  }

  void _confirmAppointment() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Resumen de Cita"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow("Médico:", _selectedDoctorName ?? ""),
            _summaryRow("Especialidad:", _selectedDoctorSpecialty ?? ""),
            _summaryRow("Licencia:", _selectedDoctorLicense ?? "N/A"),
            const Divider(),
            _summaryRow("Fecha:", "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
            _summaryRow("Hora:", _selectedTime!),
            const SizedBox(height: 10),
            _summaryRow("Síntomas:", _symptomsController.text),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: _processBooking,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A2342)),
            child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0A2342)),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
      ],
    );
  }

  Widget _buildTimeChip(String time) {
    bool isSelected = _selectedTime == time;
    return ChoiceChip(
      label: Text(time),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedTime = selected ? time : null);
      },
      selectedColor: const Color(0xFF00A8E8),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
    );
  }
}