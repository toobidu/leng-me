# 📘 Hướng dẫn chạy & phát triển — Monorepo Express + Prisma + Angular

> File này là cheat-sheet đầy đủ các lệnh và workflow. Đặt cạnh project, mở khi cần.

---

## 📂 Cấu trúc tổng quan

```
leng-me/
├── apps/
│   ├── backend/        # Express + Prisma + TS — port 8080
│   └── frontend/       # Angular 21              — port 4200 (proxy /api → 8080)
├── packages/
│   └── shared/         # @leng/shared — types dùng chung FE+BE
├── docker/
│   └── postgres/init/  # Init script tạo DB khi container start lần đầu
└── docker-compose.yml  # Postgres container
```

Workspace tool: **npm workspaces** (built-in, không cần Lerna/Nx/Turbo).

---

## 🚀 Khởi tạo lần đầu (clone repo / setup mới)

Chạy LẦN LƯỢT 5 lệnh sau, từ thư mục root `leng-me/`:

```powershell
# 1. Cài deps cho cả 3 workspace (backend + frontend + shared)
npm install

# 2. Khởi động Postgres container
npm run db:up

# 3. Đợi 10-15s cho Postgres init xong (chỉ lần đầu) — có thể check bằng:
docker logs --tail 5 postgres-dev
# Khi thấy "database system is ready to accept connections" là OK

# 4. Build shared package (BE+FE cần dist/ của nó để import)
npm run build -w @leng/shared

# 5. Apply migration vào DB + generate Prisma Client
npm run db:migrate -- --name init
```

Sau đó:

```powershell
# Chạy cả BE và FE cùng lúc
npm run dev
```

→ Backend: <http://localhost:8080>
→ Frontend: <http://localhost:4200>
→ Health: <http://localhost:8080/health>
→ API: <http://localhost:8080/api/users>

---

## ⚙️ Daily development

### Chạy app

| Lệnh | Tác dụng |
|---|---|
| `npm run dev` | Chạy CẢ backend + frontend song song (concurrently) |
| `npm run dev:backend` | Chỉ backend |
| `npm run dev:frontend` | Chỉ frontend |

### Database (Docker)

| Lệnh | Tác dụng |
|---|---|
| `npm run db:up` | Start Postgres container |
| `npm run db:down` | Stop container (giữ data) |
| `npm run db:logs` | Xem log Postgres realtime |

### Prisma — schema & migration

| Lệnh | Tác dụng |
|---|---|
| `npm run db:migrate -- --name <ten>` | Tạo + apply migration mới khi đổi schema |
| `npm run db:reset` | DROP DB + recreate + chạy lại migration (mất data) |
| `npm run db:studio` | Mở Prisma Studio (GUI xem/sửa data) trên port 5555 |
| `npm run db:generate` | Regenerate Prisma Client types (sau khi sửa schema) |

### Shared package

```powershell
# Build 1 lần
npm run build -w @leng/shared

# Hoặc auto-rebuild khi save (chạy ở terminal riêng)
npm run dev -w @leng/shared
```

### Type-check & build production

| Lệnh | Tác dụng |
|---|---|
| `npm run typecheck` | Check TS toàn bộ backend không build |
| `npm run build` | Build cả 3 workspace ra `dist/` |
| `npm start -w backend` | Chạy backend đã build (production mode) |

---

## 🔄 Workflow thường gặp

### 1. Thêm field mới vào User (ví dụ thêm `phone`)

```powershell
# 1. Sửa apps/backend/prisma/schema.prisma — thêm field phone String?
# 2. Tạo migration
npm run db:migrate -- --name add_user_phone

# 3. Sửa packages/shared/src/user.types.ts — thêm phone? string
# 4. Rebuild shared
npm run build -w @leng/shared

# 5. Sửa apps/backend/src/modules/user/user.dto.ts — thêm validation
# (Không cần restart dev — ts-node-dev auto reload)
```

### 2. Thêm entity mới (ví dụ Post)

```powershell
# 1. Thêm model Post trong schema.prisma
# 2. Tạo migration
npm run db:migrate -- --name add_post

# 3. Tạo apps/backend/src/modules/post/ với 5 file:
#    post.dto.ts, post.repository.ts, post.service.ts,
#    post.controller.ts, post.routes.ts

# 4. Mount router trong apps/backend/src/app.ts:
#    app.use('/api/posts', postRouter)

# 5. Thêm types vào packages/shared/src/post.types.ts
# 6. Export từ packages/shared/src/index.ts
# 7. Rebuild shared: npm run build -w @leng/shared
```

### 3. Reset toàn bộ DB (khi schema bị rối, muốn làm lại từ đầu)

```powershell
npm run db:reset
```

→ Tương đương: drop database → recreate → re-run tất cả migration.

### 4. Reset CỨNG (xóa luôn volume Docker)

```powershell
docker compose down -v       # -v = xóa volume
npm run db:up
# Đợi 10s
npm run db:migrate -- --name init
```

---

## 🐛 Lỗi thường gặp & cách fix

### ❌ `P1001: Can't reach database server at localhost:5432`

**Nguyên nhân**: Postgres container chưa sẵn sàng (đang init) hoặc chưa start.

**Fix**:
```powershell
docker ps                          # Check container có chạy không
docker logs --tail 20 postgres-dev # Xem log
# Đợi đến khi log có "ready to accept connections"
```

Nếu container đang restart loop → xem mục "Postgres 18 mount error" bên dưới.

### ❌ Postgres 18 mount error (image bị upgrade)

**Triệu chứng**: `docker logs postgres-dev` báo `Error: in 18+, these Docker images are configured to store database data in a format which is compatible with "pg_ctlcluster"`.

**Nguyên nhân**: Image `postgres:latest` đã lên v18, đổi cấu trúc mount, không tương thích volume cũ.

**Fix**: file `docker-compose.yml` đã pin `postgres:16-alpine`. Nếu vẫn lỗi:
```powershell
docker compose down -v             # Xóa volume cũ
npm run db:up                      # Recreate với image 16
npm run db:migrate -- --name init
```

### ❌ `Cannot find module '@leng/shared'` ở backend hoặc frontend

**Nguyên nhân**: chưa build shared package.

**Fix**:
```powershell
npm run build -w @leng/shared
```

### ❌ TypeScript báo `Property 'PrismaClientKnownRequestError' does not exist`

**Nguyên nhân**: Prisma Client chưa generate sau `npm install`.

**Fix**:
```powershell
npm run db:generate
```

### ❌ Port 8080 hoặc 5432 đã bị chiếm

```powershell
# Tìm process chiếm port 8080
netstat -ano | findstr :8080
# Kill bằng PID
taskkill /PID <pid> /F
```

### ❌ Lệnh `npm run db:migrate -- --name X` không nhận `--name`

**Nguyên nhân**: npm workspaces strip `--name` flag (xung đột với flag nội bộ).

**Fix**: script root đã dùng `npm --workspace backend exec --` để forward đúng. Nếu vẫn lỗi, chạy trực tiếp từ folder backend:
```powershell
cd apps/backend
npx prisma migrate dev --name init
```

---

## 🔌 Reuse Postgres container cho project khác

Container `postgres-dev` được thiết kế dùng chung. Cho mỗi project mới:

### Cách A — Thêm DB mới khi container đã chạy
```powershell
# Tạo database mới (tên có hyphen thì quote)
docker exec -it postgres-dev psql -U postgres -c 'CREATE DATABASE "other-project"'

# Trong project mới, .env trỏ tới DB đó
# DATABASE_URL="postgresql://postgres:password@localhost:5432/other-project"
```

### Cách B — Thêm vào init script (chỉ chạy lần đầu)
Sửa `docker/postgres/init/01-init-db.sql`:
```sql
CREATE DATABASE "leng-me";
CREATE DATABASE "other_project";
```
→ Chỉ áp dụng khi `docker compose down -v` rồi `up` lại (init script chỉ chạy khi volume rỗng).

---

## 🧪 Test API bằng curl (PowerShell)

```powershell
# Tạo user
curl -X POST http://localhost:8080/api/users `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"a@b.com\",\"name\":\"Bình\"}'

# List
curl http://localhost:8080/api/users

# Get by id (thay <id> bằng id thật)
curl http://localhost:8080/api/users/<id>

# Update
curl -X PATCH http://localhost:8080/api/users/<id> `
  -H "Content-Type: application/json" `
  -d '{\"name\":\"Bình mới\"}'

# Delete
curl -X DELETE http://localhost:8080/api/users/<id>
```

---

## 📦 Cấu trúc 1 module (template để copy)

```
src/modules/<entity>/
├── <entity>.dto.ts          # Zod schema + types (input validation)
├── <entity>.repository.ts   # Tầng truy cập Prisma — KHÔNG có logic
├── <entity>.service.ts      # Business logic — throw HttpError nếu sai
├── <entity>.controller.ts   # Map req/res — KHÔNG chạm DB
└── <entity>.routes.ts       # Mount URL + middleware validate
```

Luồng:
```
HTTP → routes → [validate] → controller → service → repository → Prisma → Postgres
                                ↑                                              │
                                └──── return data ←───────────────────────────┘
                                                  ↓ (nếu lỗi)
                                          errorMiddleware → JSON response
```

---

## 🗺️ Sơ đồ port

| Port | Service | Note |
|---|---|---|
| 4200 | Angular dev server | Mở browser ở đây |
| 8080 | Express API | FE proxy `/api/*` về đây |
| 5432 | Postgres | Chỉ kết nối từ BE |
| 5555 | Prisma Studio | Khi chạy `npm run db:studio` |

---

## 📚 Tham khảo

- Prisma docs: <https://www.prisma.io/docs>
- Express 5 docs: <https://expressjs.com>
- Angular docs: <https://angular.dev>
- npm workspaces: <https://docs.npmjs.com/cli/v10/using-npm/workspaces>
- Zod: <https://zod.dev>
