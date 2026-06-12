// ============================================================
//  HTTP EXCEPTIONS — bộ exception có sẵn status + code
// ============================================================
//  Mỗi class = một HTTP status code thường gặp. Service/Controller
//  chỉ cần `throw new ConflictException('...')`, ErrorMiddleware lo
//  phần map ra response. Không bao giờ phải nhớ con số 409 nữa.
//
//  ≈ các exception của Spring:
//     BadRequestException        → 400
//     (Spring Security 401)      → 401
//     AccessDeniedException      → 403
//     EntityNotFoundException    → 404
//     DataIntegrityViolation     → 409
//     (Bean Validation 422)      → 422
//     (Bucket4j / RateLimit 429) → 429
// ============================================================
import { HttpError } from '@/utils/http-error';

// 400 — request sai cú pháp / thiếu field / sai kiểu (lỗi do client).
export class BadRequestException extends HttpError {
  constructor(message = 'Bad request', details?: unknown) {
    super(400, message, details, 'BAD_REQUEST');
  }
}

// 401 — chưa đăng nhập / token sai / token hết hạn.
export class UnauthorizedException extends HttpError {
  constructor(message = 'Unauthorized', details?: unknown) {
    super(401, message, details, 'UNAUTHORIZED');
  }
}

// 403 — đã đăng nhập nhưng KHÔNG đủ quyền.
export class ForbiddenException extends HttpError {
  constructor(message = 'Forbidden', details?: unknown) {
    super(403, message, details, 'FORBIDDEN');
  }
}

// 404 — không tìm thấy tài nguyên.
export class NotFoundException extends HttpError {
  constructor(message = 'Not found', details?: unknown) {
    super(404, message, details, 'NOT_FOUND');
  }
}

// 409 — xung đột trạng thái: trùng unique (username/email), version mismatch...
export class ConflictException extends HttpError {
  constructor(message = 'Conflict', details?: unknown) {
    super(409, message, details, 'CONFLICT');
  }
}

// 422 — cú pháp đúng nhưng nghiệp vụ không hợp lệ (vd: ngày sinh ở tương lai).
export class UnprocessableEntityException extends HttpError {
  constructor(message = 'Unprocessable entity', details?: unknown) {
    super(422, message, details, 'UNPROCESSABLE_ENTITY');
  }
}

// 429 — gọi quá nhiều (rate limit).
export class TooManyRequestsException extends HttpError {
  constructor(message = 'Too many requests', details?: unknown) {
    super(429, message, details, 'TOO_MANY_REQUESTS');
  }
}
