import { Test, TestingModule } from '@nestjs/testing';
import { Logger, BadRequestException, ConflictException } from '@nestjs/common';
import { RegisterUserCommandHandler } from './register-user.handler';
import { RegisterUserCommand } from './register-user.command';
import { UserRole } from '@dermatech/shared-dtos';
import { User } from '../../../domain/entities/user.entity';
import { UserEmail } from '../../../domain/value-objects/user-email.vo';

// FIX 1: Export interfaces so Linter treats them as public API
export interface UserRepositoryPort {
  save(user: User): Promise<User>;
  findByEmail(email: string): Promise<User | null>;
}

export interface CryptoServicePort {
  hash(text: string): Promise<string>;
  compare(text: string, hash: string): Promise<boolean>;
}

describe('RegisterUserCommandHandler', () => {
  let handler: RegisterUserCommandHandler;
  
  // FIX 2: Simplified Spy type
  let loggerSpy: jest.SpyInstance; 
  let warnSpy: jest.SpyInstance;

  const mockUserEmail = 'student@uce.edu.ec';
  const mockPassword = 'Password123!';
  
  // Define mocks using the interfaces
  const mockUserRepository: UserRepositoryPort = {
    findByEmail: jest.fn(),
    save: jest.fn(),
  };

  const mockCryptoService: CryptoServicePort = {
    hash: jest.fn().mockResolvedValue('hashed_password'),
    compare: jest.fn(),
  };

  beforeEach(async () => {
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
      ],
    }).compile();

    handler = module.get<RegisterUserCommandHandler>(RegisterUserCommandHandler);

    // Spy on Logger
    loggerSpy = jest.spyOn(Logger.prototype, 'log').mockImplementation(() => undefined);
    warnSpy = jest.spyOn(Logger.prototype, 'warn').mockImplementation(() => undefined);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(handler).toBeDefined();
  });

  describe('execute', () => {
    it('should register a user successfully and NOT log PII', async () => {
      // Arrange
      const command = new RegisterUserCommand(mockUserEmail, mockPassword, UserRole.STUDENT);
      
      // Cast to jest.Mock to control behavior
      (mockUserRepository.findByEmail as jest.Mock).mockResolvedValue(null);
      (mockUserRepository.save as jest.Mock).mockImplementation((user) => Promise.resolve(user));

      // Act
      await handler.execute(command);

      // Assert
      expect(mockUserRepository.save).toHaveBeenCalled();
      
      // FIX 3: Ensure loggerSpy is used in assertion
      expect(loggerSpy).toHaveBeenCalledWith(expect.stringContaining('Processing new user registration'));
      expect(loggerSpy).not.toHaveBeenCalledWith(expect.stringContaining(mockUserEmail));
    });

    it('should throw error if user exists and NOT log PII in warnings', async () => {
      // Arrange
      const command = new RegisterUserCommand(mockUserEmail, mockPassword, UserRole.STUDENT);
      const existingUser = new User('id', new UserEmail(mockUserEmail), 'hash', UserRole.STUDENT);
      
      (mockUserRepository.findByEmail as jest.Mock).mockResolvedValue(existingUser);

      // Act & Assert
      await expect(handler.execute(command)).rejects.toThrow(ConflictException);
      
      // FIX 4: Ensure warnSpy is used in assertion
      expect(warnSpy).toHaveBeenCalled();
      expect(warnSpy).not.toHaveBeenCalledWith(expect.stringContaining(mockUserEmail));
    });

    it('should handle invalid email format', async () => {
        // Arrange
        const invalidCommand = new RegisterUserCommand('invalid-email', mockPassword, UserRole.STUDENT);
        
        // FIX CRITICAL: Force repository to return null so we bypass "User Exists" check
        // and hit the Value Object validation logic.
        (mockUserRepository.findByEmail as jest.Mock).mockResolvedValue(null);
        
        // Act & Assert
        await expect(handler.execute(invalidCommand)).rejects.toThrow(BadRequestException);
    });
  });
});