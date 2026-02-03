export class GetAllDoctorsQuery {
  constructor(
    public readonly includeInactive: boolean
  ) {}
}