// ============================================================
//  VALIDATE MIDDLEWARE — validate req.body bằng Zod schema
// ============================================================
//  Dùng:  router.post('/', validateBody(schema), controller.create)
//
//  Nếu hợp lệ → ghi đè req.body bằng data đã parse (đã coerce kiểu),
//  rồi gọi next(). Nếu fail → throw HttpError 400 → ErrorMiddleware bắt.
//
//  ≈ @Valid + @RequestBody trong Spring Boot.
// ============================================================
import type { Request, Response, NextFunction } from 'express';
import type { ZodType } from 'zod';
import { HttpError } from '@/utils/http-error';

export const validateBody =
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
