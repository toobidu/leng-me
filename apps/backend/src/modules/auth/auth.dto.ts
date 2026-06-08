// ============================================================
//  AUTH DTO — schema validate input bằng Zod
// ============================================================
//  validate_body(schema) parse req.body theo đây. Sai → 400 kèm chi tiết.
//  z.infer<> sinh ra kiểu TS tương ứng → service nhận đúng kiểu, khỏi cast.
//
//  ≈ DTO class + @NotBlank/@Size trong Spring Boot.
// ============================================================
import { z } from 'zod';
import { Gender } from '@prisma/client';

export const register_schema = z.object({
  username: z
    .string()
    .trim()
    .min(3, 'Username tối thiểu 3 ký tự')
    .max(50, 'Username tối đa 50 ký tự'),
  password: z
    .string()
    .min(8, 'Mật khẩu tối thiểu 8 ký tự')
    .max(72, 'Mật khẩu tối đa 72 ký tự'), 
  // gender BẮT BUỘC vì cột NOT NULL không default trong schema DB.
  gender: z.nativeEnum(Gender),
  // Tuỳ chọn:
  email: z.string().trim().email('Email không hợp lệ').max(100).optional(),
  full_name: z.string().trim().max(100).optional(),
});

export const login_schema = z.object({
  username: z.string().trim().min(1, 'Nhập username'),
  password: z.string().min(1, 'Nhập mật khẩu'),
});

// Body cho /refresh và /logout — refresh token gửi trong body.
export const refresh_schema = z.object({
  refresh_token: z.string().min(1, 'Thiếu refresh_token'),
});

// Kiểu TS suy ra từ schema (dùng ở service).
export type RegisterInput = z.infer<typeof register_schema>;
export type LoginInput = z.infer<typeof login_schema>;
export type RefreshInput = z.infer<typeof refresh_schema>;
