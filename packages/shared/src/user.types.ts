// ============================================================
//  USER types — dùng chung giữa Backend (Express) và Frontend (Angular)
// ============================================================
//  Khi backend đổi shape user → đây đổi → frontend compile fail ngay.
//  Không còn cảnh BE đổi mà FE không biết.
// ============================================================

export interface User {
  id: string;
  email: string;
  name: string;
  created_at: string; // ISO string khi qua JSON
  updated_at: string;
}

export interface CreateUserDto {
  email: string;
  name: string;
}

export interface UpdateUserDto {
  email?: string;
  name?: string;
}
