export class CancelAppointmentCommand {
  constructor(
    public readonly appointmentId: string,
    public readonly studentId: string,
  ) {}
}