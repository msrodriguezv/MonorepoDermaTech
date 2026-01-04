import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { JwtPayload } from '../../../shared-dtos/src/interfaces/jwt-payload.interface';

export const User = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): JwtPayload => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);