// ============================================================
//  TOKENS — Access token (JWT) + Refresh token (opaque, băm SHA-256)
// ============================================================
//  Chiến lược 2 token (chuẩn production):
//
//    • ACCESS TOKEN  : JWT ngắn hạn (15m). Client gửi kèm mỗi request
//                      qua header "Authorization: Bearer <token>".
//                      Server chỉ verify chữ ký, KHÔNG cần query DB.
//
//    • REFRESH TOKEN : chuỗi random dài hạn (7 ngày). KHÔNG phải JWT,
//                      chỉ là 32 byte random. Server lưu BẢN BĂM (SHA-256)
//                      vào bảng refresh_tokens → kể cả DB bị lộ cũng
//                      không dùng được. Dùng để xin access token mới.
//
//  ≈ Spring Security: access token như JWT filter, refresh token như
//    persistent token store.
// ============================================================
import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import { env } from '@/config/env.config';

// Payload nhét trong access token. Giữ TỐI THIỂU — token sẽ lộ ra client.
export interface AccessTokenPayload {
  sub: number; // user id (chuẩn JWT dùng "sub" cho subject)
  username: string;
}

// ─── Access token (JWT) ─────────────────────────────────────
export const sign_access_token = (payload: AccessTokenPayload): string =>
  jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_EXPIRES as jwt.SignOptions['expiresIn'],
  });

// Verify + trả payload. Sai chữ ký / hết hạn → jwt tự throw.
export const verify_access_token = (token: string): AccessTokenPayload => {
  const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET);
  // decoded có thể là string | JwtPayload — ta luôn ký object nên ép qua unknown.
  return decoded as unknown as AccessTokenPayload;
};

// ─── Refresh token (opaque) ─────────────────────────────────
//  Trả về { token, token_hash }:
//    • token      → gửi cho client (chỉ client giữ bản gốc)
//    • token_hash → lưu vào DB (server chỉ giữ bản băm)
export const generate_refresh_token = (): { token: string; token_hash: string } => {
  const token = crypto.randomBytes(32).toString('hex');
  return { token, token_hash: hash_token(token) };
};

// Băm 1 chiều để so khớp khi client gửi refresh token lên.
export const hash_token = (token: string): string =>
  crypto.createHash('sha256').update(token).digest('hex');

// Mốc hết hạn refresh token (Date) — dùng set cột expires_at.
export const refresh_token_expiry = (): Date =>
  new Date(Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000);
