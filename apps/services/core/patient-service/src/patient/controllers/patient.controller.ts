import { Controller, Put, Get, Body, UseGuards, HttpStatus, Logger } from '@nestjs/common';
import { CommandBus, QueryBus } from '@nestjs/cqrs';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';

// [LIBS AUDIT]
// 1. Guards: Must be exported from your shared-guards library.
import { JwtAuthGuard, RolesGuard } from '@dermatech/shared-guards';
// 2. Decorators: Custom decorators to extract data safely.
import { Roles, User } from '@dermatech/shared-guards'; 
// 3. DTOs & Interfaces: Contracts shared across microservices.
import { UserRole, JwtPayload } from '@dermatech/shared-dtos';

// Local Domain Imports
import { UpdateProfileDto } from '../dto/update-profile.dto.';
import { UpdateProfileCommand } from '../cqrs/commands/impl/update-profile.command';
import { GetPatientProfileQuery } from '../cqrs/queries/impl/get-patient-profile.query';
import { Patient } from '../entities/patient.entity';

/**
 * PatientController
 * * Layer: Presentation (REST API).
 * * Architecture: Hybrid (Layered + CQRS).
 * * Security: Protected by Global JWT Strategy and RBAC (Role-Based Access Control).
 */
@ApiTags('Patients')
@ApiBearerAuth() // Swagger: Indicates this controller requires a Bearer Token.
@UseGuards(JwtAuthGuard, RolesGuard) // Security: Validates Token signature and User Roles.
@Controller('patients')
export class PatientController {
  private readonly logger = new Logger(PatientController.name);

  constructor(
    private readonly commandBus: CommandBus,
    private readonly queryBus: QueryBus,
  ) {}

  /**
   * Endpoint: Complete or Update Profile.
   * * Method: PUT /patients/me
   * * Access Control: Restricted to users with 'STUDENT' role.
   * * Flow: Controller -> CommandBus -> UpdateProfileHandler -> Service -> DB.
   */
  @Put('me')
  @Roles(UserRole.STUDENT) // [RBAC] Only Students can modify their own patient profile.
  @ApiOperation({ summary: 'Complete or update personal profile' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Profile updated successfully', type: Patient })
  async updateMyProfile(
    @User() user: JwtPayload, // [Security] We extract the UserID (sub) from the validated Token. Never from the body.
    @Body() dto: UpdateProfileDto,
  ) {
    this.logger.log(`REST Request: Update profile for UserID ${user.sub}`);

    // Dispatching the Command (Write Model)
    // user.sub comes from the JWT 'sub' claim, ensuring the user can only edit THEIR own profile.
    return await this.commandBus.execute(
      new UpdateProfileCommand(user.sub, dto),
    );
  }

  /**
   * Endpoint: Get My Profile.
   * * Method: GET /patients/me
   * * Access Control: Restricted to users with 'STUDENT' role.
   * * Flow: Controller -> QueryBus -> GetPatientProfileHandler -> Service -> DB.
   */
  @Get('me')
  @Roles(UserRole.STUDENT)
  @ApiOperation({ summary: 'Get current patient profile' })
  @ApiResponse({ status: HttpStatus.OK, description: 'Return patient profile data', type: Patient })
  async getMyProfile(@User() user: JwtPayload) {
    this.logger.log(`REST Request: Get profile for UserID ${user.sub}`);

    // Dispatching the Query (Read Model)
    return await this.queryBus.execute(
      new GetPatientProfileQuery(user.sub),
    );
  }
}