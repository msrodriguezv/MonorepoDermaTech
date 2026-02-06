export class AppointmentCancelledEvent {
  constructor(
    public readonly appointmentId: string,
    public readonly doctorId: string,
    public readonly startTime: Date,
  ) {}
}