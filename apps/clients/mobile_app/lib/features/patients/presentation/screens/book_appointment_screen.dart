import 'package:flutter/material.dart';
import '../../../../services/booking_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _bookingService = BookingService();
  final _symptomsController = TextEditingController();

  List<dynamic> _doctors = [];
  bool _isLoadingDoctors = true;

  String? _selectedDoctorId;
  String? _selectedDoctorName;
  String? _selectedDoctorSpecialty;

  DateTime? _selectedDate;

  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final doctors = await _bookingService.getDoctors();
      setState(() {
        _doctors = doctors;
        _isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() => _isLoadingDoctors = false);
      _showError("Error cargando doctores: $e");
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
      final slots = await _bookingService.getAvailability(_selectedDoctorId!, dateStr);
      
      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() => _isLoadingSlots = false);
      _showError("Error buscando horarios: $e");
    }
  }

  Future<void> _processBooking() async {
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

    try {
      await _bookingService.createAppointment(
        _selectedDoctorId!,
        dateStr,
        _selectedTime!,
        _symptomsController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Cita agendada exitosamente"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Error al agendar: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
              const Center(child: CircularProgressIndicator())
            else if (_doctors.isEmpty)
              const Text("No hay doctores disponibles.")
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _doctors.length,
                itemBuilder: (context, index) {
                  final doctor = _doctors[index];
                  final docName = "${doctor['firstName']} ${doctor['lastName']}";
                  final docSpecialty = doctor['specialty'] ?? 'General';
                  final docId = doctor['id'];
                  final isSelected = _selectedDoctorId == docId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDoctorId = docId;
                        _selectedDoctorName = docName;
                        _selectedDoctorSpecialty = docSpecialty;
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
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00A8E8) : Colors.transparent,
                          width: 2,
                        ),
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
                                Text(
                                  docName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isSelected ? const Color(0xFF0A2342) : Colors.black,
                                  ),
                                ),
                                Text(
                                  docSpecialty,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF00A8E8)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
            _sectionHeader("2. Describe tus síntomas", Icons.medical_information),
            const SizedBox(height: 10),
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Ej: Picazón intensa, manchas rojas...",
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
                const Text("No hay horarios disponibles para esta fecha.", style: TextStyle(color: Colors.red))
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

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
            _summaryRow("Fecha:", "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
            _summaryRow("Hora:", _selectedTime!),
            const SizedBox(height: 10),
            const Text("Tu solicitud será procesada por nuestro sistema inteligente.", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
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