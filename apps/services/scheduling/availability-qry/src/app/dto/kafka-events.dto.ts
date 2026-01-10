/**
 * Defines the contract for the 'booking.appointment_created' event payload.
 * This ensures type safety when consuming messages from the Appointment Service.
 */
export interface AppointmentCreatedPayload {
  doctor_id: string;
  start_time: string; // ISO 8601 string expected
  student_id?: string;
  appointment_id?: string;
}

/**
 * Generic wrapper for Kafka messages coming from NestJS microservices.
 * Prevents the use of 'any' for the message container.
 */
export interface KafkaMessage<T> {
  type: string; // Event topic or action name
  data: T;      // The actual typed payload
}