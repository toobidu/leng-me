import type { Request, Response, NextFunction } from 'express';
import type { ZodType } from 'zod';
import { HttpError } from '@/utils/http-error';

export const validate_body =
  <T>(schema: ZodType<T>) =>
  (req: Request, _res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      throw new HttpError(
        400,
        'Validation failed',
        result.error.issues.map((i) => ({
          path: i.path.join('.'),
          message: i.message,
        })),
      );
    }

    req.body = result.data;
    next();
  };
