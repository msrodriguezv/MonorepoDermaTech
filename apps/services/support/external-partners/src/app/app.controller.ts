import { Body, Controller, Get, Param, Post, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CreateReferralDto, WebhookPayloadDto } from './dtos'; 

@ApiTags('External Partners & Interoperability')
@Controller('partners')
export class AppController {
  
  // --- ENDPOINT 1: PARTNER DISCOVERY ---
  @Get()
  @ApiOperation({ 
    summary: 'Retrieve available external partners', 
    description: 'Returns a list of allied medical centers and their current availability status.' 
  })
  @ApiResponse({ status: 200, description: 'Partners list retrieved successfully.' })
  getAvailablePartners() {
    // Simulation: Fetching from a registry database
    return [
      { 
        id: 'CLINIC-ST-MARY', 
        name: 'Saint Mary Clinic', 
        specialty: 'Traumatology', 
        availability: 'AVAILABLE',
        integrationType: 'HL7-FHIR' 
      },
      { 
        id: 'METRO-HOSPITAL', 
        name: 'Metropolitan Hospital', 
        specialty: 'Cardiology', 
        availability: 'BUSY',
        integrationType: 'REST-API'
      },
      { 
        id: 'SWISS-LABS', 
        name: 'Swiss Laboratories', 
        specialty: 'Imaging & Diagnostics', 
        availability: 'AVAILABLE',
        integrationType: 'SOAP'
      }
    ];
  }

  // --- ENDPOINT 2: CREATE REFERRAL (Transaction) ---
  @Post('referral')
  @ApiOperation({ 
    summary: 'Initiate Patient Referral', 
    description: 'Transmits patient clinical data to the target partner system via secure channel.' 
  })
  @ApiResponse({ status: 201, description: 'Referral created and queued for transmission.' })
  createReferral(@Body() referralData: CreateReferralDto) {
    // Simulation: Generating a tracking ID and simulating downstream latency
    const mockRefId = 'REF-' + Math.floor(Math.random() * 1000000);
    
    return {
      success: true,
      message: 'Referral request successfully transmitted to external provider.',
      data: {
        referralId: mockRefId,
        status: 'PENDING_PARTNER_APPROVAL',
        estimatedResponseTime: '15 minutes',
        submittedData: referralData
      }
    };
  }

  // --- ENDPOINT 3: STATUS POLLING ---
  @Get('referral/:id')
  @ApiOperation({ 
    summary: 'Check Referral Status', 
    description: 'Queries the current state of a referral transaction.' 
  })
  checkReferralStatus(@Param('id') id: string) {
    // Simulation: Mocking a completed response
    return {
      referralId: id,
      status: 'ACCEPTED',
      partnerResponse: {
        bedAssigned: 'ICU-405',
        admissionTime: new Date().toISOString(),
        notes: 'Patient accepted. Ambulance transfer authorized.'
      },
      lastUpdated: new Date().toISOString()
    };
  }

  // --- ENDPOINT 4: WEBHOOK RECEIVER (Mandatory Communication Pattern) ---
  @Post('webhook/status-update')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Inbound Webhook: Partner Status Updates', 
    description: 'Public endpoint for external systems to push asynchronous updates regarding patient status.' 
  })
  @ApiResponse({ status: 200, description: 'Event received and acknowledged.' })
  handlePartnerWebhook(@Body() payload: WebhookPayloadDto) {
    // Logic: This simulates receiving a "Fire-and-Forget" event from the partner
    console.log('🔗 [Webhook Inbound] Received event from External Partner:', payload);
    
    // In a real scenario, this would trigger a CQRS Command to update the local database
    return { 
      received: true, 
      processingId: 'EVT-' + Date.now(), 
      timestamp: new Date().toISOString() 
    };
  }
}