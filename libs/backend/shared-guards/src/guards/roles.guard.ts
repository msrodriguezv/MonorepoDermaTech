import { Injectable, CanActivate, ExecutionContext, Logger } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@dermatech/shared-dtos';
import { ROLES_KEY } from '../decorators/roles.decorator';

/**
 * RolesGuard
 * * Aspect: Security (RBAC - Role Based Access Control).
 * * Responsibility: Determines if the current user possesses the required role 
 * * to access a specific route handler.
 * * Usage: Must be used AFTER JwtAuthGuard, as it relies on request.user being populated.
 */
@Injectable()
export class RolesGuard implements CanActivate {
  private readonly logger = new Logger(RolesGuard.name);

  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    // 1. Retrieve the required roles from the route metadata (set by @Roles decorator)
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    // 2. If no roles are defined for this route, allow access by default (Public endpoint inside a protected controller)
    if (!requiredRoles) {
      return true;
    }

    // 3. Extract the user object attached to the request by JwtStrategy
    const { user } = context.switchToHttp().getRequest();

    if (!user || !user.role) {
      this.logger.warn('Access Denied: No user or role found in request context.');
      return false;
    }

    // 4. Check if the user's role is strictly included in the allowed roles
    const hasRole = requiredRoles.includes(user.role);
    
    if (!hasRole) {
      this.logger.warn(`Access Denied: User role '${user.role}' does not match required roles: [${requiredRoles}]`);
    }

    return hasRole;
  }
}