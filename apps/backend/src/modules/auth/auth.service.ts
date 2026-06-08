// ============================================================
//  AUTH SERVICE — nghiệp vụ đăng ký / đăng nhập / refresh / logout
// ============================================================
//  Nơi chứa logic thật: băm mật khẩu, kiểm tra, cấp & xoay token.
//  Controller chỉ điều phối; service mới là "bộ não".
//
//  ≈ @Service trong Spring Boot.
// ============================================================
import bcrypt from 'bcryptjs';
import type { User } from '@prisma/client';
import { auth_repository } from './auth.repository';
import type { RegisterInput, LoginInput } from './auth.dto';
import {
  sign_access_token,
  generate_refresh_token,
  hash_token,
  refresh_token_expiry,
} from '@/lib/tokens';
import { HttpError } from '@/utils/http-error';

const BCRYPT_ROUNDS = 10;

// Thông tin client kèm theo (để lưu vào refresh_tokens, audit/bảo mật).
interface ClientContext {
  user_agent?: string | null;
  ip?: string | null;
}

// User "công khai" — BỎ password_hash và field nhạy cảm trước khi trả ra.
export type PublicUser = Omit<User, 'password_hash'>;

const to_public_user = (user: User): PublicUser => {
  const { password_hash: _omit, ...rest } = user;
  return rest;
};

// Gói token trả về client.
interface TokenPair {
  access_token: string;
  refresh_token: string;
}

// Tạo cặp access + refresh, đồng thời LƯU bản băm refresh vào DB.
const issue_tokens = async (
  user: User,
  ctx: ClientContext,
): Promise<TokenPair> => {
  const access_token = sign_access_token({ sub: user.id, username: user.username });
  const { token: refresh_token, token_hash } = generate_refresh_token();

  await auth_repository.create_refresh_token({
    user_id: user.id,
    token_hash: token_hash,
    expires_at: refresh_token_expiry(),
    user_agent: ctx.user_agent ?? null,
    ip_address: ctx.ip ?? null,
  });

  return { access_token, refresh_token };
};

export const auth_service = {
  // ─── Đăng ký ──────────────────────────────────────────────
  async register(input: RegisterInput, ctx: ClientContext) {
    // Username trùng? (email trùng sẽ do ràng buộc UNIQUE bắt → P2002 → 409)
    const existing = await auth_repository.find_user_by_username(input.username);
    if (existing) {
      throw new HttpError(409, 'Username đã tồn tại');
    }

    const password_hash = await bcrypt.hash(input.password, BCRYPT_ROUNDS);

    const user = await auth_repository.create_user({
      username: input.username,
      password_hash,
      gender: input.gender,
      email: input.email,
      full_name: input.full_name,
    });

    const tokens = await issue_tokens(user, ctx);
    return { user: to_public_user(user), ...tokens };
  },

  // ─── Đăng nhập ────────────────────────────────────────────
  async login(input: LoginInput, ctx: ClientContext) {
    const user = await auth_repository.find_user_by_username(input.username);

    // LƯU Ý BẢO MẬT: trả lỗi GIỐNG NHAU cho "sai user" và "sai password"
    // → tránh lộ username nào tồn tại.
    if (!user) {
      throw new HttpError(401, 'Username hoặc mật khẩu không đúng');
    }
    if (!user.is_active) {
      throw new HttpError(403, 'Tài khoản đã bị khoá');
    }

    const ok = await bcrypt.compare(input.password, user.password_hash);
    if (!ok) {
      throw new HttpError(401, 'Username hoặc mật khẩu không đúng');
    }

    const tokens = await issue_tokens(user, ctx);
    return { user: to_public_user(user), ...tokens };
  },

  // ─── Cấp access token mới từ refresh token (có XOAY VÒNG) ──
  async refresh(refresh_token: string, ctx: ClientContext): Promise<TokenPair> {
    const token_hash = hash_token(refresh_token);
    const record = await auth_repository.find_refresh_token_by_hash(token_hash);

    if (!record || record.revoked || record.expires_at < new Date()) {
      throw new HttpError(401, 'Refresh token không hợp lệ hoặc đã hết hạn');
    }

    const user = await auth_repository.find_user_by_id(record.user_id);
    if (!user || !user.is_active) {
      throw new HttpError(401, 'Tài khoản không khả dụng');
    }

    // XOAY VÒNG: thu hồi token cũ rồi cấp token mới. Nếu refresh token
    // bị đánh cắp và kẻ gian dùng lại token cũ → đã revoked → bị chặn.
    await auth_repository.revoke_refresh_token(record.id);
    return issue_tokens(user, ctx);
  },

  // ─── Đăng xuất — thu hồi refresh token hiện tại ───────────
  async logout(refresh_token: string): Promise<void> {
    const record = await auth_repository.find_refresh_token_by_hash(hash_token(refresh_token));
    if (record && !record.revoked) {
      await auth_repository.revoke_refresh_token(record.id);
    }
    // Không tồn tại / đã revoke → vẫn coi như logout thành công (idempotent).
  },

  // ─── Lấy thông tin user đang đăng nhập ────────────────────
  async get_me(user_id: number): Promise<PublicUser> {
    const user = await auth_repository.find_user_by_id(user_id);
    if (!user) {
      throw new HttpError(404, 'Không tìm thấy user');
    }
    return to_public_user(user);
  },
};
