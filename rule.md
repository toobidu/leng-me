# Quy ước đặt tên (Naming Convention)

> Áp dụng cho toàn bộ monorepo: `apps/backend`, `apps/frontend`, `packages/shared`.

## Nguyên tắc chính

**Mọi thứ TỰ VIẾT dùng `snake_case`** — tên hàm và tên biến.

| Loại | Quy ước | Ví dụ |
|---|---|---|
| Tên hàm (tự viết) | `snake_case` | `sign_access_token`, `find_user_by_id`, `create_app` |
| Tên biến (tự viết) | `snake_case` | `access_token`, `token_hash`, `client_context` |
| Field JSON qua mạng (request/response) | `snake_case` | `access_token`, `refresh_token`, `created_at` |
| Tên type / interface / class | `PascalCase` (chuẩn TS) | `AuthResponse`, `HttpError`, `TokenPair`, `UserService` |
| Hằng số (constant) | `SCREAMING_SNAKE_CASE` | `BCRYPT_ROUNDS`, `JWT_ACCESS_SECRET` |

## Ngoại lệ — KHÔNG đổi

Những thứ thuộc về thư viện / framework, dùng `camelCase` thì **giữ nguyên** (không sửa được, hoặc sửa sẽ vỡ):

- **Prisma accessor tự sinh**: `prisma.refreshToken.create()`, `findUnique()`, `updateMany()`
- **API thư viện**: `jwt.sign()`, `bcrypt.hash()`, `res.status()`, `req.ip`, `process.uptime()`
- **Angular / RxJS**: `bootstrapApplication()`, `provideRouter()`, `ngOnInit`, lifecycle hooks, các `provide*()`
- **Built-in JS/DOM**: `querySelector`, `textContent`, `toString`...

## Ví dụ áp dụng

```ts
// ✅ Đúng
export const generate_refresh_token = (): { token: string; token_hash: string } => {
  const token = crypto.randomBytes(32).toString('hex'); // toString: thư viện → giữ
  return { token, token_hash: hash_token(token) };
};

interface TokenPair {        // PascalCase: tên type → giữ
  access_token: string;      // snake_case: field tự viết
  refresh_token: string;
}

// ❌ Sai
export const generateRefreshToken = () => { ... }   // hàm tự viết phải snake_case
interface tokenPair { accessToken: string }         // type phải PascalCase, field phải snake_case
```

## Lý do

Đồng bộ với tầng DB/Prisma (vốn đã `snake_case`: `user_id`, `password_hash`, `created_at`) trên toàn bộ monorepo, tránh lệch giữa các tầng và giữa FE ↔ BE.
