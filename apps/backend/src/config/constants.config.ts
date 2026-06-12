// ============================================================
//  CONSTANTS CONFIG — Hằng số dùng chung cho toàn app
// ============================================================
//  Mục đích: Gom tất cả "magic numbers", "magic strings" vào
//  một nơi duy nhất. Giúp code sạch, dễ đọc, dễ thay đổi.
// ============================================================

export const AppConstants = {
  // --- Security ---
  RATE_LIMIT_WINDOW_MS: 15 * 60 * 1000, // 15 minutes
  RATE_LIMIT_MAX_REQUESTS: 100,
  RATE_LIMIT_MESSAGE: 'Too many requests from this IP, please try again after 15 minutes',
  JSON_BODY_LIMIT: '1mb',

  // --- Validation: User Model ---
  USER: {
    USERNAME_MAX_LENGTH: 50,
    PHONE_NUMBER_MAX_LENGTH: 20,
    PASSWORD_MIN_LENGTH: 12,
    PASSWORD_MAX_LENGTH: 255,
    FULL_NAME_MAX_LENGTH: 100,
    FIRST_NAME_MAX_LENGTH: 50,
    LAST_NAME_MAX_LENGTH: 50,
  },
};
