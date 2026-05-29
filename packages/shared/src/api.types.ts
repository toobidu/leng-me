// ============================================================
//  API response wrappers — chuẩn hóa response format
// ============================================================
//  Backend trả về theo format này, frontend type-check tự động.
// ============================================================

export interface ApiError {
  error: string;
  details?: unknown;
}

export type ApiResult<T> = T | ApiError;
