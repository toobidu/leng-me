// ============================================================
//  AUTH types — dùng chung Backend (Express) ↔ Frontend (Angular)
// ============================================================
//  Backend đổi shape request/response auth → đổi ở đây → FE compile fail
//  ngay nếu dùng sai. Tránh lệch hợp đồng API giữa FE và BE.
// ============================================================

export type Gender = 'MALE' | 'FEMALE';

// Body gửi lên khi đăng ký.
export interface RegisterRequest {
  username: string;
  password: string;
  gender: Gender;
  email?: string;
  full_name?: string;
}

// Body gửi lên khi đăng nhập.
export interface LoginRequest {
  username: string;
  password: string;
}

// User công khai (KHÔNG có password_hash). Chỉ liệt kê field FE hay dùng;
// backend có thể trả thêm field khác.
export interface AuthUser {
  id: number;
  username: string;
  email: string | null;
  full_name: string | null;
  gender: Gender;
  level: number;
  coin_balance: number;
  created_at: string; // ISO string sau khi qua JSON
}

// Response của /register và /login.
export interface AuthResponse {
  user: AuthUser;
  access_token: string;
  refresh_token: string;
}

// Response của /refresh.
export interface TokenResponse {
  access_token: string;
  refresh_token: string;
}
