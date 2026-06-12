// ============================================================
//  HttpError — error có status code, dùng xuyên suốt app
// ============================================================
//  Service throw HttpError → ErrorMiddleware bắt → trả response chuẩn.
//  ≈ ResponseStatusException trong Spring Boot.
// ============================================================
//  code  = mã lỗi nội bộ (≈ ThingsboardErrorCode). Client dựa vào code
//          để phân biệt loại lỗi mà KHÔNG cần parse message tiếng người.
export class HttpError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly details?: unknown,
    public readonly code: string = 'ERROR',
  ) {
    super(message);
    this.name = 'HttpError';
  }
}
