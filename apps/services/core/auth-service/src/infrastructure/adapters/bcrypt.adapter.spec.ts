import { Test, TestingModule } from '@nestjs/testing';
import { BcryptAdapter } from './bcrypt.adapter';

describe('BcryptAdapter', () => {
  let service: BcryptAdapter;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [BcryptAdapter],
    }).compile();

    service = module.get<BcryptAdapter>(BcryptAdapter);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should hash a password correctly', async () => {
    const password = 'securePassword123';
    const hash = await service.hash(password);
    
    // El hash NO debe ser igual al texto plano
    expect(hash).not.toBe(password);
    // Un hash de bcrypt estándar suele tener 60 caracteres
    expect(hash.length).toBeGreaterThan(0);
  });

  it('should return true for valid password comparison', async () => {
    const password = 'mySecretPassword';
    const hash = await service.hash(password);
    const isMatch = await service.compare(password, hash);
    expect(isMatch).toBe(true);
  });

  it('should return false for invalid password comparison', async () => {
    const password = 'mySecretPassword';
    const hash = await service.hash(password);
    const isMatch = await service.compare('wrongPassword', hash);
    expect(isMatch).toBe(false);
  });
});