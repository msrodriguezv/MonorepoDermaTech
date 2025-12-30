import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { PatientService } from './patient.service';
import { Patient } from './entities/patient.entity'; 
import { BadRequestException } from '@nestjs/common';

describe('PatientService', () => {
  let service: PatientService;

  const mockPatient = {
    id: 'uuid-test-1',
    firstName: 'Gio',
    lastName: 'Rodriguez',
    email: 'gio@test.com',
    userId: 'user-123',
    birthDate: '1995-05-15',
    phone: '0991234567',
  };

  // 2. Simulamos el Repositorio de TypeORM
  const mockPatientRepository = {
    create: jest.fn().mockReturnValue(mockPatient),
    save: jest.fn().mockResolvedValue(mockPatient),
    find: jest.fn().mockResolvedValue([mockPatient]),
    // CAMBIO CLAVE: Por defecto no encuentra nada para que el "create" funcione
    findOne: jest.fn().mockResolvedValue(null), 
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PatientService,
        {
          provide: getRepositoryToken(Patient), 
          useValue: mockPatientRepository,
        },
      ],
    }).compile();

    service = module.get<PatientService>(PatientService);
    
    // Limpiamos los mocks antes de cada prueba
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('debería crear y retornar un paciente', async () => {
      const dto = {
        firstName: 'Gio',
        lastName: 'Rodriguez',
        email: 'gio@test.com',
        userId: 'user-123',
        birthDate: '1995-05-15',
        phone: '0991234567',
      };

      // Nos aseguramos que para esta prueba findOne devuelva null (no existe duplicado)
      mockPatientRepository.findOne.mockResolvedValueOnce(null);

      const result = await service.create(dto as any);

      expect(result).toEqual(mockPatient);
      expect(mockPatientRepository.save).toHaveBeenCalled();
    });

    it('debería lanzar un error si el paciente ya existe', async () => {
      const dto = { userId: 'user-123' };

      // Simulamos que findOne SI encuentra un paciente existente
      mockPatientRepository.findOne.mockResolvedValueOnce(mockPatient);

      await expect(service.create(dto as any)).rejects.toThrow(BadRequestException);
    });
  });

  describe('findAll', () => {
    it('debería retornar un array de pacientes', async () => {
      const result = await service.findAll();
      expect(result).toEqual([mockPatient]);
      expect(mockPatientRepository.find).toHaveBeenCalled();
    });
  });
});