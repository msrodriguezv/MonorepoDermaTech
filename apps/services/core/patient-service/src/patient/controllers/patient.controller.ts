import { Controller, Put, Get, Body, UseGuards, HttpStatus, Logger } from '@nestjs/common';
import { CommandBus, QueryBus } from '@nestjs/cqrs';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';

// [LIBS AUDIT]
import { JwtAuthGuard, RolesGuard } from '@dermatech/shared-guards';
import { Roles, User } from '@dermatech/shared-guards'; 
import { UserRole, JwtPayload } from '@dermatech/shared-dtos';

// Local Domain Imports
import { UpdateProfileDto } from '../dto/update-profile.dto';
import { UpdateProfileCommand } from '../cqrs/commands/impl/update-profile.command';
import { GetPatientProfileQuery } from '../cqrs/queries/impl/get-patient-profile.query';
import { GetAllPatientsQuery } from '../cqrs/queries/impl/get-all-patients.query';
import { Patient } from '../entities/patient.entity';

/**
 * PatientController
 * * Layer: Presentation (REST API).
 * * Architecture: Hybrid (Layered + CQRS).
 * * Security: Protected by Global JWT Strategy and RBAC.
 */
@ApiTags('Patients')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('patients')
export class PatientController {
  private readonly logger = new Logger(PatientController.name);

  constructor(
    private readonly commandBus: CommandBus,
    private readonly queryBus: QueryBus,
  ) {}

  // ===========================================================================
  // 1. MOBILE APP CRITICAL FLOWS (Student/Patient)
  // ===========================================================================

  /**
   * Endpoint: Check Profile Completion Status.
   * * Method: GET /patients/profile/status
   * * Purpose: Used by Mobile Login to determine navigation (Dashboard vs Complete Profile).
   * * Logic: Reuses the GetProfile Query but projects only the boolean status.
   */
  @Get('profile/status')
  @Roles(UserRole.STUDENT)
  @ApiOperation({ summary: 'Check if the profile is fully completed' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Returns boolean status' })
  async getProfileStatus(@User() user: JwtPayload) {
    this.logger.log(`REST Request: Check profile status for UserID ${user.sub}`);

    // We reuse the existing Query to fetch the patient data
    const patient: Patient = await this.queryBus.execute(
      new GetPatientProfileQuery(user.sub),
    );

    // We map the response to the specific format expected by the Mobile App
    return {
      data: {
        isProfileComplete: patient.isProfileComplete
      }
    };
  }

  /**
   * Endpoint: Complete or Update Profile.
   * * Method: PUT /patients/me
   */
  @Put('me')
  @Roles(UserRole.STUDENT)
  @ApiOperation({ summary: 'Complete or update personal profile' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Profile updated successfully', type: Patient })
  async updateMyProfile(
    @User() user: JwtPayload,
    @Body() dto: UpdateProfileDto,
  ) {
    this.logger.log(`REST Request: Update profile for UserID ${user.sub}`);
    return await this.commandBus.execute(
      new UpdateProfileCommand(user.sub, dto),
    );
  }

  /**
   * Endpoint: Get My Profile.
   * * Method: GET /patients/me
   */
  @Get('me')
  @Roles(UserRole.STUDENT)
  @ApiOperation({ summary: 'Get current patient profile' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Return patient profile data', type: Patient })
  async getMyProfile(@User() user: JwtPayload) {
    this.logger.log(`REST Request: Get profile for UserID ${user.sub}`);
    return await this.queryBus.execute(
      new GetPatientProfileQuery(user.sub),
    );
  }

  // ===========================================================================
  // 2. ADMIN DASHBOARD FLOWS (Admin Only)
  // ===========================================================================

  /**
   * Endpoint: List All Patients.
   * * Method: GET /patients
   * * Access: Restricted to ADMIN.
   */
  @Get()
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'List all registered patients (Admin)' })
  @ApiResponse({ status: HttpStatus.OK, description: 'List of all patients', type: [Patient] })
  async findAllPatients() {
    this.logger.log('REST Request: Admin getting all patients');
    // You need to create this Query Handler if it doesn't exist, 
    // or call service directly if breaking CQRS for Admin reads (not recommended but faster).
    // Assuming GetAllPatientsQuery exists:
    return await this.queryBus.execute(new GetAllPatientsQuery());
  }
}