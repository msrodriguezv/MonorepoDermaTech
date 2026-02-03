export interface AppointmentCreatedPayload {
  appointment_id: string;
  doctor_id: string;
  student_id: string;
  start_time: string;
  symptoms: string;
}

export interface AiDiagnosisResponse {
  diagnosis: string;
  priority_level: number; // 1-5
  confidence: number;
}

export interface QrGenerationResponse {
  qr_code_base64: string; 
  qr_content: string;    
}