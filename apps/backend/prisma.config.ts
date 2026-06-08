import path from 'node:path'
import { config as loadEnv } from 'dotenv'
import { defineConfig } from 'prisma/config'

// Khi dùng prisma.config.ts, Prisma KHÔNG còn tự load .env nữa
// (trước đây CLI tự làm). Phải tự nạp để env("DATABASE_URL") trong
// schema đọc được biến môi trường.
loadEnv()

export default defineConfig({
  // Trỏ tới THƯ MỤC chứa các file *.prisma (multi-file schema)
  schema: path.join('prisma', 'schema'),

  migrations: {
    // Nơi lưu & tìm các file migration
    path: path.join('prisma', 'migrations'),
  },
})
