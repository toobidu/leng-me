// ============================================================
//  HttpError — error có status code, dùng xuyên suốt app
// ============================================================
//  Service throw HttpError → ErrorMiddleware bắt → trả response chuẩn.
//  ≈ ResponseStatusException trong Spring Boot.
// ============================================================
export class HttpError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly details?: unknown,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}
