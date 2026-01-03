import { RolesGuard } from './roles.guard';
import { Reflector } from '@nestjs/core';
import { ExecutionContext } from '@nestjs/common';
import { UserRole } from '../../../shared-dtos/src/enums/user-role.enum';
import { Test, TestingModule } from '@nestjs/testing';

/**
 * Unit Test: RolesGuard
 * * Aspect: Security & Authorization.
 * * Quality: Strict typing applied (No 'any').
 */
describe('RolesGuard', () => {
  let guard: RolesGuard;
  let reflector: Reflector;

  // Mock Reflector with strict typing using Jest functions
  const mockReflector = {
    getAllAndOverride: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RolesGuard,
        {
          provide: Reflector,
          useValue: mockReflector,
        },
      ],
    }).compile();

    guard = module.get<RolesGuard>(RolesGuard);
    reflector = module.get<Reflector>(Reflector);
  });

  // Helper to create a strictly typed Mock Context
  function createMockContext(user: { role?: UserRole } | undefined): ExecutionContext {
    return {
      getHandler: jest.fn(),
      getClass: jest.fn(),
      switchToHttp: jest.fn().mockReturnValue({
        getRequest: jest.fn().mockReturnValue({ user }), // The user object simulates the JWT payload attached to request
      }),
    } as unknown as ExecutionContext; // We cast to unknown first, then context, to satisfy the full interface safely
  }

  it('should allow access if no roles are required', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(undefined);
    const context = createMockContext(undefined); 
    
    expect(guard.canActivate(context)).toBe(true);
  });

  it('should deny access if user object is missing in request', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([UserRole.ADMIN]);
    const context = createMockContext(undefined); // No user in request
    
    expect(guard.canActivate(context)).toBe(false);
  });

  it('should deny access if user has no role defined', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([UserRole.ADMIN]);
    const context = createMockContext({}); // User exists but has no role property
    
    expect(guard.canActivate(context)).toBe(false);
  });

  it('should deny access if user role does not match required roles', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([UserRole.ADMIN]);
    const context = createMockContext({ role: UserRole.STUDENT }); // Role Mismatch
    
    expect(guard.canActivate(context)).toBe(false);
  });

  it('should allow access if user role matches one of the required roles', () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([UserRole.ADMIN, UserRole.STUDENT]);
    const context = createMockContext({ role: UserRole.STUDENT }); // Role Match
    
    expect(guard.canActivate(context)).toBe(true);
  });
});