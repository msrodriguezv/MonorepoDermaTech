import { ApiProperty } from '@nestjs/swagger';

/// **CreateReferralDto**
/// Defines the structure for initiating a patient referral to an external partner.
export class CreateReferralDto {
  @ApiProperty({ example: '1755443322', description: 'Unique Patient National ID or UUID' })
  patientId: string;

  @ApiProperty({ example: 'CLINIC-ST-MARY', description: 'Target External Partner ID' })
  targetPartnerId: string;

  @ApiProperty({ example: 'Emergency Trauma - Open Fracture', description: 'Clinical justification for the referral' })
  reason: string;

  @ApiProperty({ example: 'HIGH', enum: ['LOW', 'MEDIUM', 'HIGH'], description: 'Triage Priority Level' })
  priority: string;
}

/// **WebhookPayloadDto**
/// Defines the structure of the payload received from external systems via Webhook.
export class WebhookPayloadDto {
  @ApiProperty({ example: 'REF-998877', description: 'Internal Referral Reference ID' })
  referralId: string;

  @ApiProperty({ example: 'ACCEPTED', description: 'New status code from the external system' })
  status: string;

  @ApiProperty({ example: '2026-01-12T10:00:00Z', description: 'ISO 8601 Timestamp of the event' })
  timestamp: string;
}