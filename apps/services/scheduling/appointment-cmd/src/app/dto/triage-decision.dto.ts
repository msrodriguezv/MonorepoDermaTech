import { IsEnum, IsString, IsOptional } from 'class-validator';

export enum TriageOutcome {
  PASS_TO_DOCTOR = 'PASS_TO_DOCTOR',
  EMERGENCY_REFERRAL = 'EMERGENCY_REFERRAL'
}

export class TriageDecisionDto {
  @IsEnum(TriageOutcome)
  outcome: TriageOutcome;

  @IsString()
  @IsOptional()
  notes?: string;
}