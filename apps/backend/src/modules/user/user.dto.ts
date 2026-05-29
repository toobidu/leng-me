// ============================================================
//  USER DTO — Zod schema cho input + type tự suy ra
// ============================================================
//  ≈ DTO class với @NotNull, @Email, @Size trong Spring Boot.
//  Điểm hay: KHÔNG cần viết type riêng — z.infer<> tự sinh.
// ============================================================
import { z } from 'zod';

// ─── Create ─────────────────────────────────────────────────
export const createUserSchema = z.object({
  email: z.string().email('Email không hợp lệ'),
  name: z.string().min(1, 'Tên không được rỗng').max(100, 'Tên tối đa 100 ký tự'),
});

// ─── Update ─────────────────────────────────────────────────
//  .partial() = tất cả field optional → cho phép update từng phần (PATCH-like)
export const updateUserSchema = createUserSchema.partial();

// ─── Types (inferred) ───────────────────────────────────────
export type CreateUserDto = z.infer<typeof createUserSchema>;
export type UpdateUserDto = z.infer<typeof updateUserSchema>;
