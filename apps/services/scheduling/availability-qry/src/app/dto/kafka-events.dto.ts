/**
 * Payload expected from 'booking.appointment_created' event.
 * Must match the object emitted by appointment-cmd.
 */
export interface AppointmentCreatedPayload {
  appointment_id: string;
  doctor_id: string;
  student_id: string;
  start_time: string; // ISO 8601
  symptoms: string;
}