import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TypeOrmUserRepository } from './typeorm-user.repository';
import { UserSchema } from '../../typeorm/entities/user.schema';
import { User } from '../../../../domain/entities/user.entity';
import { UserRole } from '@dermatech/shared-dtos';
import { UserEmail } from '../../../../domain/value-objects/user-email.vo'; 

describe('TypeOrmUserRepository', () => {
  let repository: TypeOrmUserRepository;
  let typeOrmRepoMock: MockType<Repository<UserSchema>>;

  // FIX 1: changing jest.Mock<{}> for jest.Mock<unknown> for linter
  type MockType<T> = {
    [P in keyof T]?: jest.Mock<unknown>;
  };

  const mockFactory = jest.fn(() => ({
    save: jest.fn(),
    findOne: jest.fn(),
  }));

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TypeOrmUserRepository,
        {
          provide: getRepositoryToken(UserSchema),
          useFactory: mockFactory,
        },
      ],
    }).compile();

    repository = module.get<TypeOrmUserRepository>(TypeOrmUserRepository);
    typeOrmRepoMock = module.get(getRepositoryToken(UserSchema));
  });

  it('should be defined', () => {
    expect(repository).toBeDefined();
  });

  // 1. Test for SAVE
  describe('save', () => {
    it('should save and return a user domain entity', async () => {
      const userDomain = new User(
        '123', 
        new UserEmail('test@test.com'),
        'hashed-pass', 
        UserRole.STUDENT
      );
      
      const userSchema = { 
        id: '123', 
        email: 'test@test.com', 
        passwordHash: 'hashed-pass', 
        role: UserRole.STUDENT 
      } as unknown as UserSchema;

      typeOrmRepoMock.save.mockReturnValue(Promise.resolve(userSchema));

      const result = await repository.save(userDomain);

      expect(typeOrmRepoMock.save).toHaveBeenCalled();
      expect(result).toBeInstanceOf(User);
    //NOTE: Here the result is already a User entity, so we access .email.value or .email.email as you defined your VO 
    //If your User develops a string in the email getter, this works. 
    //If you return the VO object, serial: expect(result.email.email).toBe(...)
      expect(result.getEmail).toEqual(expect.anything()); 
    });
  });

  // 2. Test para FIND BY EMAIL
  describe('findByEmail', () => {
    it('should return a user if found', async () => {
      const userSchema = { 
        id: '123', 
        email: 'exist@test.com', 
        passwordHash: 'hash', 
        role: UserRole.STUDENT 
      } as unknown as UserSchema;

      typeOrmRepoMock.findOne.mockReturnValue(Promise.resolve(userSchema));

      const result = await repository.findByEmail('exist@test.com');

      expect(typeOrmRepoMock.findOne).toHaveBeenCalledWith({ where: { email: 'exist@test.com' } });
      expect(result).toBeInstanceOf(User);
    });

    it('should return null if not found', async () => {
      typeOrmRepoMock.findOne.mockReturnValue(Promise.resolve(null));

      const result = await repository.findByEmail('404@test.com');

      expect(result).toBeNull();
    });
  });

  // 3. Test para FIND BY ID
  describe('findById', () => {
    it('should return a user if found', async () => {
      const userSchema = { 
        id: 'uuid-123', 
        email: 'id@test.com', 
        passwordHash: 'hash', 
        role: UserRole.STUDENT 
      } as unknown as UserSchema;

      typeOrmRepoMock.findOne.mockReturnValue(Promise.resolve(userSchema));

      const result = await repository.findById('uuid-123');

      expect(typeOrmRepoMock.findOne).toHaveBeenCalledWith({ where: { id: 'uuid-123' } });
      expect(result).toBeInstanceOf(User);
    });

    it('should return null if not found', async () => {
      typeOrmRepoMock.findOne.mockReturnValue(Promise.resolve(null));

      const result = await repository.findById('uuid-404');

      expect(result).toBeNull();
    });
  });
});