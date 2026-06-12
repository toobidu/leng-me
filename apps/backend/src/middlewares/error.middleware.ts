import type { ErrorRequestHandler } from 'express';
import { ZodError } from 'zod';
import { Prisma } from '@prisma/client';
import jwt from 'jsonwebtoken';
import { HttpError } from '@/utils/http-error';
import { env } from '@/config/env.config';

// Gom mọi nhánh về 1 hàm trả response → đảm bảo shape luôn giống nhau.
interface ErrorBody {
  status: number;
  code: string;
  message: string;
  details?: unknown;
}

export const error_middleware: ErrorRequestHandler = (err, req, res, _next) => {
  const body = resolve_error(err);

  // Log: chỉ ồn ào với lỗi 5xx (lỗi server). 4xx là "lỗi do client", không cần log đỏ.
  if (body.status >= 500) {
    console.error('[ERROR]', req.method, req.originalUrl, err);
  }

  res.status(body.status).json({
    status: body.status,
    code: body.code,
    message: body.message,
    timestamp: new Date().toISOString(),
    path: req.originalUrl,
    ...(body.details !== undefined && { details: body.details }),
  });
};

// ─── Bộ não map lỗi → { status, code, message, details } ──────
function resolve_error(err: unknown): ErrorBody {
  // 1) Lỗi mình tự throw (ConflictException, BadRequestException, ...).
  if (err instanceof HttpError) {
    return { status: err.status, code: err.code, message: err.message, details: err.details };
  }

  // 2) Validation Zod — liệt kê CHÍNH XÁC field nào sai, sai gì.
  if (err instanceof ZodError) {
    return {
      status: 400,
      code: 'VALIDATION_FAILED',
      message: 'Dữ liệu không hợp lệ',
      details: err.issues.map((i) => ({
        field: i.path.join('.') || '(root)',
        message: i.message,
      })),
    };
  }

  // 3) JWT — token hết hạn vs token sai chữ ký (phân biệt để client xử lý refresh).
  if (err instanceof jwt.TokenExpiredError) {
    return { status: 401, code: 'TOKEN_EXPIRED', message: 'Token đã hết hạn' };
  }
  if (err instanceof jwt.JsonWebTokenError) {
    return { status: 401, code: 'INVALID_TOKEN', message: 'Token không hợp lệ' };
  }

  // 4) Prisma — lỗi DB có mã rõ ràng → map sang HTTP đúng nghĩa.
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    return resolve_prisma_error(err);
  }

  // 5) Prisma validation — gọi query với kiểu/field sai (lỗi lúc dev là chính).
  if (err instanceof Prisma.PrismaClientValidationError) {
    return { status: 400, code: 'DB_VALIDATION', message: 'Tham số truy vấn không hợp lệ' };
  }

  // 6) Body JSON hỏng — express.json() ném SyntaxError có .body.
  if (err instanceof SyntaxError && 'body' in err) {
    return { status: 400, code: 'MALFORMED_JSON', message: 'Body JSON không hợp lệ' };
  }

  // 7) Ngoài dự đoán → 500. Đây là chỗ DUY NHẤT được phép 500.
  return {
    status: 500,
    code: 'INTERNAL_ERROR',
    message:
      env.NODE_ENV === 'development' && err instanceof Error
        ? err.message
        : 'Đã có lỗi xảy ra, vui lòng thử lại sau',
  };
}

// Map mã lỗi Prisma → HTTP. Xem: https://www.prisma.io/docs/orm/reference/error-reference
function resolve_prisma_error(err: Prisma.PrismaClientKnownRequestError): ErrorBody {
  switch (err.code) {
    case 'P2002': // Unique constraint — vd username/email đã tồn tại.
      return {
        status: 409,
        code: 'CONFLICT',
        message: 'Dữ liệu đã tồn tại',
        details: { fields: err.meta?.target },
      };
    case 'P2025': // Record cần thao tác không tồn tại (update/delete).
      return { status: 404, code: 'NOT_FOUND', message: 'Không tìm thấy bản ghi' };
    case 'P2003': // Foreign key constraint.
      return { status: 409, code: 'FK_CONSTRAINT', message: 'Vi phạm ràng buộc khóa ngoại' };
    case 'P2000': // Giá trị quá dài so với cột.
      return { status: 400, code: 'VALUE_TOO_LONG', message: 'Giá trị vượt quá độ dài cho phép' };
    case 'P2011': // Null constraint.
      return { status: 400, code: 'NULL_CONSTRAINT', message: 'Thiếu trường bắt buộc' };
    default: // Known error nhưng chưa map riêng → coi là lỗi DB phía server.
      return { status: 500, code: `PRISMA_${err.code}`, message: 'Lỗi cơ sở dữ liệu' };
  }
}
