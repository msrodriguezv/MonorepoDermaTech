export class AppointmentCreatedEvent {
  constructor(
    public readonly appointmentId: string,
    public readonly doctorId: string,
    public readonly studentId: string,
    public readonly date: Date,
    public readonly symptoms: string,
  ) {}
}