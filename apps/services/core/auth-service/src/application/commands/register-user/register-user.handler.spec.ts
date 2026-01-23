/// <reference types="jest" />
import { Test, TestingModule } from '@nestjs/testing';
import { Logger, BadRequestException, ConflictException } from '@nestjs/common';
import { RegisterUserCommandHandler } from './register-user.handler';
import { RegisterUserCommand } from './register-user.command';
import { UserRole } from '@dermatech/shared-dtos';
import { User } from '../../../domain/entities/user.entity';
import { UserEmail } from '../../../domain/value-objects/user-email.vo';

// --- PORTS IMPORTS ---
import { UserRepositoryPort } from '../../ports/user.repository.port';
import { CryptoServicePort } from '../../ports/crypto.service.port';
import { ExternalSystemPort } from '../../ports/external-system.port';
import { EventPublisherPort } from '../../ports/event.publisher.port';

describe('RegisterUserCommandHandler', () => {
  let handler: RegisterUserCommandHandler;
  
  // STRICT TYPING: We declare variables with their Interfaces to satisfy 'no-unused-vars'
  // and ensure strict type checking in tests.
  let userRepository: UserRepositoryPort;
  let cryptoService: CryptoServicePort;
  let externalSystem: ExternalSystemPort;
  let eventPublisher: EventPublisherPort;
  
  let loggerSpy: jest.SpyInstance; 
  let warnSpy: jest.SpyInstance;

  const mockUserEmail = 'student@uce.edu.ec';
  const mockPassword = 'Password123!';

  beforeEach(async () => {
    // 1. Create Mocks fulfilling the Interface contracts
    const mockUserRepository = {
      findByEmail: jest.fn(),
      save: jest.fn(),
      findById: jest.fn(),
    };

    const mockCryptoService = {
      hash: jest.fn().mockResolvedValue('hashed_password'),
      compare: jest.fn(),
    };

    const mockExternalSystem = {
      checkStudentEnrollment: jest.fn().mockResolvedValue(true),
    };

    const mockEventPublisher = {
      publish: jest.fn().mockResolvedValue(undefined),
    };

    // 2. Configure Testing Module
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RegisterUserCommandHandler,
        {
          provide: 'UserRepositoryPort',
          useValue: mockUserRepository,
        },
        {
          provide: 'CryptoServicePort',
          useValue: mockCryptoService,
        },
        {
          provide: 'ExternalSystemPort',
          useValue: mockExternalSystem,
        },
        {
          provide: 'EventPublisherPort',
          useValue: mockEventPublisher,
        },
      ],
    }).compile();

    handler = module.get<RegisterUserCommandHandler>(RegisterUserCommandHandler);
    
    // 3. Retrieve injected mocks ensuring strict typing
    // We assign them to the variables declared above, satisfying the "unused import" check.
    userRepository = module.get('UserRepositoryPort');
    cryptoService = module.get('CryptoServicePort');
    externalSystem = module.get('ExternalSystemPort');
    eventPublisher = module.get('EventPublisherPort');

    // Spy on Logger
    loggerSpy = jest.spyOn(Logger.prototype, 'log').mockImplementation(() => undefined);
    warnSpy = jest.spyOn(Logger.prototype, 'warn').mockImplementation(() => undefined);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
    // Verify dependencies are injected
    expect(userRepository).toBeDefined();
    expect(cryptoService).toBeDefined();
  });

  describe('execute', () => {
    it('should register a user successfully', async () => {
      // Arrange
      const command = new RegisterUserCommand(mockUserEmail, mockPassword, UserRole.STUDENT);
      
      // Mock: User does NOT exist
      // Use 'as jest.Mock' locally for configuration
      (userRepository.findByEmail as jest.Mock).mockResolvedValue(null);
      
      // Mock: Save returns the user
      (userRepository.save as jest.Mock).mockImplementation((user) => 
        Promise.resolve({ ...user, getId: () => '123-uuid', getEmail: () => new UserEmail(mockUserEmail), getRole: () => UserRole.STUDENT })
      );

      // Act
      await handler.execute(command);

      // Assert
      expect(externalSystem.checkStudentEnrollment).toHaveBeenCalledWith(mockUserEmail);
      expect(userRepository.save).toHaveBeenCalled();
      
      // Verify Event Publishing
      expect(eventPublisher.publish).toHaveBeenCalledWith(
        'auth.user.registered', 
        expect.objectContaining({ userId: '123-uuid' })
      );
      
      expect(loggerSpy).toHaveBeenCalledWith(expect.stringContaining('Processing registration for'));
    });

    it('should throw ConflictException if user already exists', async () => {
      // Arrange
      const command = new RegisterUserCommand(mockUserEmail, mockPassword, UserRole.STUDENT);
      const existingUser = new User('id', new UserEmail(mockUserEmail), 'hash', UserRole.STUDENT);
      
      // Mock: User EXISTS
      (userRepository.findByEmail as jest.Mock).mockResolvedValue(existingUser);

      // Act & Assert
      await expect(handler.execute(command)).rejects.toThrow(ConflictException);
      
      // Verify Timing Attack Mitigation (Hash called)
      expect(cryptoService.hash).toHaveBeenCalled();
      
      expect(warnSpy).toHaveBeenCalled();
      expect(eventPublisher.publish).not.toHaveBeenCalled();
    });

    it('should handle invalid email format', async () => {
        // Arrange
        const invalidCommand = new RegisterUserCommand('invalid-email', mockPassword, UserRole.STUDENT);
        
        (userRepository.findByEmail as jest.Mock).mockResolvedValue(null);
        
        // Act & Assert
        await expect(handler.execute(invalidCommand)).rejects.toThrow(BadRequestException);
    });
  });
});