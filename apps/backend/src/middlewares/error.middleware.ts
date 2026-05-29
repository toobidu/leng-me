// ============================================================
//  ERROR MIDDLEWARE — handler lỗi tập trung
// ============================================================
//  Trong Express 5, mọi error throw từ async handler đều được
//  tự động chuyển đến middleware này (4 tham số err, req, res, next).
//
//  Thứ tự xử lý:
//    1. Nếu là HttpError → trả status code đã định nghĩa
//    2. Nếu là Prisma known error → map sang HTTP code phù hợp
//    3. Còn lại → 500 Internal Server Error (giấu chi tiết khi prod)
//
//  ≈ @ControllerAdvice + @ExceptionHandler trong Spring Boot.
// ============================================================
import type { ErrorRequestHandler } from 'express';
import { Prisma } from '@prisma/client';
import { HttpError } from '@/utils/http-error';
import { env } from '@/config/env.config';

export const errorMiddleware: ErrorRequestHandler = (err, _req, res, _next) => {
  // 1) Error mình tự throw — luôn có status rõ ràng
  if (err instanceof HttpError) {
    res.status(err.status).json({
      error: err.message,
      ...(err.details !== undefined && { details: err.details }),
    });
    return;
  }

  // 2) Error Prisma — chuyển sang HTTP code đúng nghĩa
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2025') {
      res.status(404).json({ error: 'Record not found' });
      return;
    }
    if (err.code === 'P2002') {
      res.status(409).json({
        error: 'Unique constraint violation',
        target: err.meta?.target,
      });
      return;
    }
  }

  // 3) Còn lại — 500. Chỉ leak stack ở dev.
  console.error('[UNHANDLED]', err);
  res.status(500).json({
    error: 'Internal server error',
    ...(env.NODE_ENV === 'development' && {
      message: err instanceof Error ? err.message : String(err),
      stack: err instanceof Error ? err.stack : undefined,
    }),
  });
};
