import { Controller, Post, Get, Patch, Body, Param, UseGuards, HttpStatus, Logger } from '@nestjs/common';
import { CommandBus, QueryBus } from '@nestjs/cqrs';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';

import { JwtAuthGuard, RolesGuard, Roles, User } from '@dermatech/shared-guards';
import { UserRole, JwtPayload } from '@dermatech/shared-dtos';

import { CreateDoctorDto } from '../dto/create-doctor.dto';
import { UpdateDoctorDto } from '../dto/update-doctor.dto';
import { CreateDoctorCommand } from '../cqrs/commands/impl/create-doctor.command';
import { UpdateDoctorCommand } from '../cqrs/commands/impl/update-doctor.command';
import { GetAllDoctorsQuery } from '../cqrs/queries/impl/get-all-doctors.query';
import { Doctor } from '../entities/doctor.entity';

@ApiTags('Doctors (Admin & Public)')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('doctors')
export class DoctorController {
  private readonly logger = new Logger(DoctorController.name);

  constructor(
    private readonly commandBus: CommandBus,
    private readonly queryBus: QueryBus,
  ) {}

  @Post()
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Register a new doctor profile (Admin)' })
  @ApiResponse({ status: HttpStatus.CREATED, type: Doctor })
  async createDoctor(@Body() dto: CreateDoctorDto): Promise<Doctor> {
    this.logger.log(`REST Request: Create Doctor for UserID ${dto.userId}`);
    return await this.commandBus.execute(new CreateDoctorCommand(dto));
  }

  @Get()
  @Roles(UserRole.ADMIN, UserRole.STUDENT) 
  @ApiOperation({ summary: 'List doctors (Students see Active only, Admins see All)' })
  @ApiResponse({ status: HttpStatus.OK, type: [Doctor] })
  async findAll(@User() user: JwtPayload): Promise<Doctor[]> {
    const isAdmin = user.role === UserRole.ADMIN;
    return await this.queryBus.execute(new GetAllDoctorsQuery(isAdmin));
  }

  @Patch(':id')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Update or Deactivate (Soft Delete) a Doctor' })
  @ApiResponse({ status: HttpStatus.OK, type: Doctor })
  async updateDoctor(
    @Param('id') id: string,
    @Body() dto: UpdateDoctorDto,
  ): Promise<Doctor> {
    this.logger.log(`REST Request: Update Doctor ${id}`);
    return await this.commandBus.execute(new UpdateDoctorCommand(id, dto));
  }
}