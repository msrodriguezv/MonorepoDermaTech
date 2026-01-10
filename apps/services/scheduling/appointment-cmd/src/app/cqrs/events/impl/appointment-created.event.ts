/**
 * Event emitted after an appointment is successfully persisted.
 * Consumers:
 * 1. Notification Service (Send Email).
 * 2. Availability Query Service (Update Redis Cache).
 */
export class AppointmentCreatedEvent {
  constructor(
    public readonly appointmentId: string,
    public readonly doctorId: string,
    public readonly studentId: string,
    public readonly date: Date,
  ) {}
}