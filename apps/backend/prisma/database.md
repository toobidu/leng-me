# 📚 Tài liệu Database — Leng-Me

> Cơ sở dữ liệu: **PostgreSQL** · ORM: **Prisma**
> Schema được tách thành nhiều file `.prisma` trong thư mục [`prisma/schema/`](./schema/).
> Tài liệu này mô tả chi tiết **từng bảng** và **từng trường** trong database.

---

## 🗂 Mục lục

| Nhóm | Bảng |
|------|------|
| **Người dùng & Phân quyền (RBAC)** | [users](#1-users--người-dùng) · [roles](#2-roles--vai-trò) · [user_roles](#3-user_roles--gán-vai-trò) |
| **Xác thực & Bảo mật** | [refresh_tokens](#4-refresh_tokens) · [email_verification_tokens](#5-email_verification_tokens) · [password_reset_tokens](#6-password_reset_tokens) |
| **Từ vựng & Nội dung** | [words](#7-words--từ-vựng--thẻ) · [word_topics](#8-word_topics--chủ-đề-của-từ) |
| **Hợp thể (Fusion)** | [recipes](#9-recipes--công-thức-hợp-thể) · [recipe_chains](#10-recipe_chains--chuỗi-công-thức) · [fusion_events](#11-fusion_events--log-hợp-thể) |
| **Tiến trình người chơi** | [user_unlocked_words](#12-user_unlocked_words--từ-đã-mở-khoá) · [board_states](#13-board_states--bàn-chơi) |
| **Học tập (SRS Flashcard)** | [user_word_progress](#14-user_word_progress--tiến-trình-srs) · [study_sessions](#15-study_sessions--phiên-học) · [review_logs](#16-review_logs--lịch-sử-ôn-thẻ) · [user_word_notes](#17-user_word_notes--ghi-chú-cá-nhân) |
| **Gamification** | [achievements](#18-achievements--thành-tựu) · [user_achievements](#19-user_achievements--tiến-trình-thành-tựu) · [daily_quests](#20-daily_quests--nhiệm-vụ) · [user_daily_quests](#21-user_daily_quests--nhiệm-vụ-của-user) |
| **Kinh tế & Cửa hàng** | [coin_transactions](#22-coin_transactions--giao-dịch-coin) · [cosmetics](#23-cosmetics--vật-phẩm-trang-trí) · [user_cosmetics](#24-user_cosmetics--vật-phẩm-đã-sở-hữu) |
| **Quản trị** | [audit_logs](#25-audit_logs--nhật-ký-admin) · [administrative_units](#26-administrative_units--đơn-vị-hành-chính) |
| **Enums** | [Danh sách Enum](#-enums-kiểu-liệt-kê) |

---

## Quy ước audit fields

Tất cả model bảng trong `prisma/schema/` đều có 4 field audit chuẩn:

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

---

## Nhóm 1 — Người dùng & Phân quyền (RBAC)

### 1. `users` — Người dùng
> Model **trung tâm**, được rất nhiều bảng khác tham chiếu tới.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `username` | VarChar(50) | UNIQUE, NOT NULL | — | Tên đăng nhập |
| `password_hash` | VarChar(255) | NOT NULL | — | Mật khẩu đã băm (không lưu plain) |
| `full_name` | VarChar(100) | NULL | — | Họ tên đầy đủ |
| `first_name` | VarChar(50) | NULL | — | Tên |
| `last_name` | VarChar(50) | NULL | — | Họ |
| `date_of_birth` | Date | NULL | — | Ngày sinh |
| `gender` | Enum `Gender` | NOT NULL | — | Giới tính (MALE/FEMALE) |
| `avatar_url` | Text | NULL | — | Link ảnh đại diện |
| `bio` | Text | NULL | — | Giới thiệu bản thân |
| `address` | Text | NULL | — | Địa chỉ |
| `email` | VarChar(100) | UNIQUE, NULL | — | Email |
| `email_verified` | Boolean | NOT NULL | `false` | Email đã xác thực chưa |
| `phone_number` | VarChar(20) | UNIQUE, NULL | — | Số điện thoại |
| `level` | Int | NOT NULL | `1` | Cấp độ hiện tại |
| `exp_to_next_level` | Int | NOT NULL | `100` | EXP cần để lên cấp kế |
| `total_exp` | Int | NOT NULL | `0` | Tổng EXP tích luỹ |
| `exp_points` | Int | NOT NULL | `0` | Điểm EXP (dùng cho leaderboard) |
| `coin_balance` | Int | NOT NULL, CHECK ≥ 0 | `0` | Số coin hiện có |
| `streak_days` | Int | NOT NULL | `0` | Số ngày học liên tục |
| `last_login_at` | Timestamptz | NULL | — | Lần đăng nhập gần nhất |
| `is_active` | Boolean | NOT NULL | `true` | `false` = bị ban |
| `current_title_id` | Int | FK → achievements, NULL | — | Danh hiệu đang gắn |
| `active_cosmetic_id` | Int | FK → cosmetics, NULL | — | Vật phẩm trang trí đang dùng |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |
| `deleted_at` | Timestamptz | NULL | — | Soft-delete (NULL = chưa xoá) |

**Quan hệ chính:** `current_title` → Achievement (SET NULL), `active_cosmetic` → Cosmetic (SET NULL) · **Index:** `exp_points` (leaderboard)

---

### 2. `roles` — Vai trò
> Danh mục vai trò cho hệ thống RBAC.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `name` | VarChar(50) | UNIQUE | — | `ADMIN` / `USER` / `CONTENT_EDITOR` / `MODERATOR` |
| `description` | Text | NULL | — | Mô tả vai trò |
| `is_active` | Boolean | NOT NULL | `true` | Còn dùng hay không |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

---

### 3. `user_roles` — Gán vai trò
> Bảng nối M-N giữa `users` ↔ `roles`. Tham chiếu `users` **2 lần** (thành viên + người gán).

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `user_id` | Int | PK (1/2), FK → users (CASCADE) | — | User được gán vai trò |
| `role_id` | Int | PK (2/2), FK → roles (CASCADE) | — | Vai trò |
| `assigned_at` | DateTime | NOT NULL | `now()` | Thời điểm gán |
| `assigned_by` | Int | FK → users (SET NULL), NULL | — | Admin nào thực hiện gán |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Khoá chính tổ hợp:** `(user_id, role_id)` · **Index:** `user_id`, `role_id`

---

## Nhóm 2 — Xác thực & Bảo mật

### 4. `refresh_tokens`
> JWT rotation & revocation. Chỉ lưu **SHA-256** của token, không lưu plain.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `user_id` | Int | FK → users (CASCADE) | — | Chủ sở hữu token |
| `token_hash` | VarChar(255) | UNIQUE | — | SHA-256 của refresh token |
| `expires_at` | DateTime | NOT NULL | — | Thời điểm hết hạn |
| `revoked` | Boolean | NOT NULL | `false` | Đã thu hồi chưa |
| `revoked_at` | DateTime | NULL | — | Thời điểm thu hồi |
| `user_agent` | VarChar(512) | NULL | — | Trình duyệt/thiết bị |
| `ip_address` | VarChar(45) | NULL | — | IPv4 hoặc IPv6 |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Index:** `user_id`

---

### 5. `email_verification_tokens`
> Token xác thực email. Chỉ lưu SHA-256.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `user_id` | Int | FK → users (CASCADE) | — | Chủ sở hữu |
| `token_hash` | VarChar(255) | UNIQUE | — | SHA-256 của token |
| `expires_at` | DateTime | NOT NULL | — | Thời điểm hết hạn |
| `used_at` | DateTime | NULL | — | Thời điểm đã dùng (NULL = chưa dùng) |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Index:** `user_id`

---

### 6. `password_reset_tokens`
> Token đặt lại mật khẩu. Chỉ lưu SHA-256.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `user_id` | Int | FK → users (CASCADE) | — | Chủ sở hữu |
| `token_hash` | VarChar(255) | UNIQUE | — | SHA-256 của token |
| `expires_at` | DateTime | NOT NULL | — | Thời điểm hết hạn |
| `used_at` | DateTime | NULL | — | Thời điểm đã dùng |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Index:** `user_id`

---

## Nhóm 3 — Từ vựng & Nội dung

### 7. `words` — Từ vựng / Thẻ
> Bao gồm: từ thực, modifier card, grammar placeholder, intermediate token (chỉ dùng để fusion tiếp).

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `text` | VarChar(255) | UNIQUE | — | Nội dung từ |
| `meaning` | Text | NOT NULL | — | Nghĩa |
| `example_en` | Text | NULL | — | Ví dụ tiếng Anh |
| `example_vi` | Text | NULL | — | Ví dụ tiếng Việt |
| `level_code` | Enum `CefrLevel` | NOT NULL | — | Cấp độ CEFR (A1…C2/NATIVE) |
| `tier` | Enum `WordTier` | NOT NULL | — | Độ hiếm (COMMON…MYTHIC) |
| `token_type` | Enum `TokenType` | NOT NULL | `BASIC_WORD` | Loại token |
| `is_starter` | Boolean | NOT NULL | `false` | Từ khởi đầu cho user mới |
| `is_intermediate` | Boolean | NOT NULL | `false` | Token trung gian (chỉ để fusion) |
| `display_in_book` | Boolean | NOT NULL | `true` | Hiển thị trong sổ từ |
| `image_url` | VarChar(512) | NULL | — | Link ảnh minh hoạ |
| `audio_url` | VarChar(512) | NULL | — | Link phát âm |
| `effect_tag` | VarChar(50) | NULL | — | Tag hiệu ứng |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**CHECK (migration tay):** `NOT (is_intermediate AND display_in_book)` · **Index:** `tier`, `level_code`

---

### 8. `word_topics` — Chủ đề của từ
> Một từ có thể gắn nhiều chủ đề (`weather`, `business`, `courage`…).

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `word_id` | Int | FK → words (CASCADE) | — | Từ liên quan |
| `topic` | VarChar(50) | — | — | Tên chủ đề |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**UNIQUE:** `(word_id, topic)` · **Index:** `topic`

---

## Nhóm 4 — Hợp thể (Fusion)

### 9. `recipes` — Công thức hợp thể
> Công thức ghép **2 nguyên liệu** → 1 kết quả. Tham chiếu `words` **3 lần**.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `ingredient_1_id` | Int | FK → words (CASCADE) | — | Nguyên liệu 1 |
| `ingredient_2_id` | Int | FK → words (CASCADE) | — | Nguyên liệu 2 |
| `result_id` | Int | FK → words (CASCADE) | — | Từ kết quả |
| `source` | Enum `RecipeSource` | NOT NULL | `CURATED` | Nguồn (thủ công / AI) |
| `status` | Enum `RecipeStatus` | NOT NULL | `APPROVED` | Trạng thái duyệt |
| `use_count` | Int | NOT NULL | `0` | Số lần được dùng |
| `reviewed_by` | Int | FK → users (SET NULL), NULL | — | Người duyệt |
| `reviewed_at` | DateTime | NULL | — | Thời điểm duyệt |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**CHECK (migration tay):** `ingredient_1_id < ingredient_2_id` · **UNIQUE:** `(ingredient_1_id, ingredient_2_id)` · **Index:** `result_id`, `status`

---

### 10. `recipe_chains` — Chuỗi công thức
> Chuỗi nhiều bước để tạo ra 1 idiom (mỗi step trỏ tới 1 recipe).

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `chain_group` | VarChar(100) | — | — | Tên nhóm chuỗi (vd `CHAIN_BITE_THE_BULLET`) |
| `step_order` | SmallInt | — | — | Thứ tự bước trong chuỗi |
| `recipe_id` | Int | FK → recipes (CASCADE) | — | Recipe của bước này |
| `hint_text` | Text | NULL | — | Gợi ý cho bước |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**UNIQUE:** `(chain_group, step_order)` · **Index:** `chain_group`

---

### 11. `fusion_events` — Log hợp thể
> Ghi log mỗi lần user hợp thể (phục vụ quest/achievement đếm số lần fusion).

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | BigInt | PK, auto-increment | — | Khoá chính (volume lớn) |
| `user_id` | Int | FK → users (CASCADE) | — | User thực hiện |
| `recipe_id` | Int | FK → recipes (SET NULL), NULL | — | Recipe đã dùng |
| `result_id` | Int | FK → words (CASCADE) | — | Từ kết quả |
| `is_first_time` | Boolean | NOT NULL | `false` | Lần đầu tạo ra từ này? |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Index:** `(user_id, created_at)`, `result_id`

---

## Nhóm 5 — Tiến trình người chơi

### 12. `user_unlocked_words` — Từ đã mở khoá
> Ghi nhận user đã **mở khoá** từ nào (khác với học thuộc → xem `user_word_progress`).

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `user_id` | Int | PK (1/2), FK → users (CASCADE) | — | User |
| `word_id` | Int | PK (2/2), FK → words (CASCADE) | — | Từ |
| `unlocked_at` | DateTime | NOT NULL | `now()` | Thời điểm mở khoá |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Khoá chính tổ hợp:** `(user_id, word_id)` · **Index:** `user_id`, `word_id`

---

### 13. `board_states` — Bàn chơi
> Mỗi row = 1 card đang nằm trên board kéo-thả của user.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `user_id` | Int | FK → users (CASCADE) | — | Chủ board |
| `word_id` | Int | FK → words (CASCADE) | — | Từ trên card |
| `slot_index` | SmallInt | — | — | Vị trí slot |
| `pos_x` | SmallInt | — | `0` | Toạ độ X |
| `pos_y` | SmallInt | — | `0` | Toạ độ Y |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**UNIQUE:** `(user_id, slot_index)` · **Index:** `user_id`

---

## Nhóm 6 — Học tập (SRS Flashcard)

### 14. `user_word_progress` — Tiến trình SRS
> Lõi của chức năng flashcard, thuật toán spaced-repetition **SM-2**.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `user_id` | Int | PK (1/2), FK → users (CASCADE) | — | User |
| `word_id` | Int | PK (2/2), FK → words (CASCADE) | — | Từ |
| `ease_factor` | Real | CHECK ≥ 1.3 | `2.5` | Hệ số dễ (SM-2) |
| `interval_days` | Int | — | `0` | Khoảng cách ngày ôn |
| `repetitions` | Int | — | `0` | Số lần ôn liên tiếp đúng |
| `due_at` | DateTime | — | `now()` | Hạn ôn kế tiếp |
| `last_reviewed_at` | DateTime | NULL | — | Lần ôn gần nhất |
| `correct_count` | Int | — | `0` | Số lần trả lời đúng |
| `wrong_count` | Int | — | `0` | Số lần trả lời sai |
| `is_mastered` | Boolean | — | `false` | Đã thành thạo chưa |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Khoá chính tổ hợp:** `(user_id, word_id)` · **Index:** `(user_id, due_at)` — query "thẻ đến hạn ôn hôm nay"

---

### 15. `study_sessions` — Phiên học
> Một phiên học flashcard của user.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `user_id` | Int | FK → users (CASCADE) | — | User |
| `started_at` | DateTime | NOT NULL | `now()` | Bắt đầu phiên |
| `ended_at` | DateTime | NULL | — | Kết thúc phiên |
| `cards_reviewed` | Int | — | `0` | Số thẻ đã ôn |
| `cards_correct` | Int | — | `0` | Số thẻ trả lời đúng |
| `exp_earned` | Int | — | `0` | EXP nhận được |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Index:** `(user_id, started_at)`

---

### 16. `review_logs` — Lịch sử ôn thẻ
> Lịch sử từng lần lật thẻ.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | BigInt | PK, auto-increment | — | Khoá chính (volume lớn) |
| `user_id` | Int | FK → users (CASCADE) | — | User |
| `word_id` | Int | FK → words (CASCADE) | — | Từ |
| `session_id` | Int | FK → study_sessions (SET NULL), NULL | — | Phiên học liên quan |
| `rating` | SmallInt | CHECK 0..3 | — | `0`=Again `1`=Hard `2`=Good `3`=Easy |
| `interval_before` | Int | NULL | — | Interval trước khi ôn |
| `interval_after` | Int | NULL | — | Interval sau khi ôn |
| `reviewed_at` | DateTime | NOT NULL | `now()` | Thời điểm ôn |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Index:** `(user_id, reviewed_at)`, `word_id`

---

### 17. `user_word_notes` — Ghi chú cá nhân
> Ghi chú cá nhân + đánh dấu yêu thích cho từng từ.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `user_id` | Int | PK (1/2), FK → users (CASCADE) | — | User |
| `word_id` | Int | PK (2/2), FK → words (CASCADE) | — | Từ |
| `note` | Text | NULL | — | Nội dung ghi chú |
| `is_favorite` | Boolean | — | `false` | Đánh dấu yêu thích |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Khoá chính tổ hợp:** `(user_id, word_id)`

---

## Nhóm 7 — Gamification

### 18. `achievements` — Thành tựu

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `title` | VarChar(100) | NOT NULL | — | Tên thành tựu |
| `description` | Text | NOT NULL | — | Mô tả |
| `icon_url` | VarChar(512) | NULL | — | Link icon |
| `req_condition_json` | Json | NOT NULL | — | Điều kiện đạt, vd `{"type":"total_unlocked","count":N}` |
| `is_title_reward` | Boolean | NOT NULL | `false` | Có thưởng danh hiệu không |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Liên quan:** `users.current_title_id` trỏ về bảng này.

---

### 19. `user_achievements` — Tiến trình thành tựu
> Theo dõi tiến trình đạt thành tựu của user.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `user_id` | Int | PK (1/2), FK → users (CASCADE) | — | User |
| `achievement_id` | Int | PK (2/2), FK → achievements (CASCADE) | — | Thành tựu |
| `progress_current` | Int | — | `0` | Tiến trình hiện tại |
| `progress_target` | Int | — | `1` | Mốc cần đạt |
| `unlocked_at` | DateTime | NULL | — | NULL = chưa hoàn thành |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Khoá chính tổ hợp:** `(user_id, achievement_id)` · **Index:** `user_id`

---

### 20. `daily_quests` — Nhiệm vụ

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `title` | VarChar(100) | NOT NULL | — | Tên nhiệm vụ |
| `description` | Text | NOT NULL | — | Mô tả |
| `reset_type` | Enum `QuestResetType` | NOT NULL | `DAILY` | Chu kỳ reset (DAILY/WEEKLY) |
| `condition_json` | Json | NOT NULL | — | Điều kiện hoàn thành |
| `coin_reward` | Int | — | `0` | Thưởng coin |
| `exp_reward` | Int | — | `0` | Thưởng EXP |
| `is_active` | Boolean | NOT NULL | `true` | Đang bật không |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

---

### 21. `user_daily_quests` — Nhiệm vụ của user
> Nhiệm vụ được giao cho user theo ngày.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `user_id` | Int | FK → users (CASCADE) | — | User |
| `quest_id` | Int | FK → daily_quests (CASCADE) | — | Nhiệm vụ |
| `assigned_date` | Date | NOT NULL | `now()` | Ngày được giao |
| `progress` | Int | — | `0` | Tiến trình |
| `is_completed` | Boolean | — | `false` | Đã hoàn thành chưa |
| `completed_at` | DateTime | NULL | — | Thời điểm hoàn thành |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**UNIQUE:** `(user_id, quest_id, assigned_date)` · **Index:** `(user_id, assigned_date)`

---

## Nhóm 8 — Kinh tế & Cửa hàng

### 22. `coin_transactions` — Giao dịch coin
> `amount` dương = nhận, âm = tiêu. Trigger DB tự cộng vào `users.coin_balance`.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `user_id` | Int | FK → users (CASCADE) | — | User |
| `amount` | Int | NOT NULL | — | Số coin (+ nhận / − tiêu) |
| `type` | Enum `CoinTxType` | NOT NULL | — | EARN / SPEND |
| `reason` | VarChar(100) | NOT NULL | — | `QUEST_REWARD`, `HINT_USED`, `COSMETIC_PURCHASE`… |
| `ref_id` | Int | NULL | — | FK tuỳ context (không ràng buộc cứng) |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Index:** `(user_id, created_at)`

---

### 23. `cosmetics` — Vật phẩm trang trí

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `name` | VarChar(100) | NOT NULL | — | Tên vật phẩm |
| `type` | Enum `CosmeticType` | NOT NULL | — | Loại (theme/skin/effect/frame) |
| `description` | Text | NULL | — | Mô tả |
| `preview_url` | VarChar(512) | NULL | — | Link xem trước |
| `price_coins` | Int | CHECK ≥ 0 | `0` | Giá (coin) |
| `is_available` | Boolean | NOT NULL | `true` | Đang bán không |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Liên quan:** `users.active_cosmetic_id` trỏ về bảng này.

---

### 24. `user_cosmetics` — Vật phẩm đã sở hữu
> Bảng nối M-N giữa `users` ↔ `cosmetics`.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `user_id` | Int | PK (1/2), FK → users (CASCADE) | — | User |
| `cosmetic_id` | Int | PK (2/2), FK → cosmetics (CASCADE) | — | Vật phẩm |
| `acquired_at` | DateTime | NOT NULL | `now()` | Thời điểm sở hữu |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Khoá chính tổ hợp:** `(user_id, cosmetic_id)` · **Index:** `user_id`

---

## Nhóm 9 — Quản trị

### 25. `audit_logs` — Nhật ký admin
> Lưu vết hành động của admin. `id` dùng BigInt vì volume lớn theo thời gian.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | BigInt | PK, auto-increment | — | Khoá chính |
| `actor_id` | Int | FK → users (SET NULL), NULL | — | Người thực hiện |
| `action` | VarChar(100) | NOT NULL | — | `USER_BAN`, `RECIPE_APPROVE`, `ROLE_ASSIGN`… |
| `target_type` | VarChar(50) | NULL | — | `USER` / `RECIPE` / `WORD` / `ROLE` |
| `target_id` | Int | NULL | — | ID đối tượng bị tác động |
| `old_value` | Json | NULL | — | Giá trị trước |
| `new_value` | Json | NULL | — | Giá trị sau |
| `ip_address` | VarChar(45) | NULL | — | IP của admin |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Index:** `actor_id`, `action`, `(target_type, target_id)`

---

### 26. `administrative_units` — Đơn vị hành chính
> Danh mục đơn vị hành chính dạng cây, tự tham chiếu qua `parent_code`.

| Trường | Kiểu | Ràng buộc | Mặc định | Mô tả |
|--------|------|-----------|----------|-------|
| `id` | Int | PK, auto-increment | — | Khoá chính |
| `name` | VarChar(100) | NOT NULL | — | Tên đơn vị hành chính |
| `code` | VarChar(20) | UNIQUE, NOT NULL | — | Mã đơn vị hành chính |
| `parent_code` | VarChar(20) | FK → administrative_units.code (SET NULL), NULL | — | Mã đơn vị cha |
| `level` | Int | NOT NULL | — | Cấp hành chính |
| `created_at` | Timestamptz | NOT NULL | `now()` | Thời điểm tạo |
| `updated_at` | Timestamptz | NOT NULL | `now()` / auto | Thời điểm cập nhật cuối |
| `created_by` | VarChar(50) | NOT NULL | — | Người tạo |
| `updated_by` | VarChar(50) | NOT NULL | — | Người cập nhật cuối |

**Quan hệ chính:** `parent` / `children` tự tham chiếu trong cùng bảng · **Index:** `parent_code`

---

## 🔠 Enums (kiểu liệt kê)

| Enum | Map DB | Giá trị |
|------|--------|---------|
| `Gender` | `gender` | `MALE`, `FEMALE` |
| `CefrLevel` | `cefr_level` | `A1`, `A2`, `B1`, `B2`, `C1`, `C2`, `NATIVE` |
| `WordTier` | `word_tier` | `COMMON`, `RARE`, `EPIC`, `LEGENDARY`, `MYTHIC` |
| `TokenType` | `token_type` | `BASIC_WORD`, `COMPOUND_WORD`, `PHRASAL_VERB`, `GRAMMAR_STRUCTURE`, `IDIOM`, `PREFIX`, `SUFFIX`, `MODIFIER_CARD`, `INTERMEDIATE_TOKEN` |
| `RecipeSource` | `recipe_source` | `CURATED`, `AI_GENERATED` |
| `RecipeStatus` | `recipe_status` | `PENDING`, `APPROVED`, `REJECTED` |
| `CosmeticType` | `cosmetic_type` | `BOARD_THEME`, `CARD_SKIN`, `EFFECT_PACK`, `AVATAR_FRAME` |
| `CoinTxType` | `coin_tx_type` | `EARN`, `SPEND` |
| `QuestResetType` | `quest_reset_type` | `DAILY`, `WEEKLY` |

---

## 🔗 Sơ đồ quan hệ tổng quan

```
                          ┌──────────────┐
              ┌──────────►│    users     │◄────────────┐
              │           └──────┬───────┘             │
              │                  │ (FK current_title,  │
   roles ─────┤ user_roles       │  active_cosmetic)   │
              │                  ▼                     │
              │      ┌───────────────────────┐         │
   refresh/email/    │ user_word_progress    │         │
   password tokens   │ study_sessions        │   achievements ──┐
              │      │ review_logs           │   cosmetics ─────┤
              │      │ user_word_notes       │   daily_quests   │
              │      │ user_unlocked_words   │   coin_trans.    │
              │      │ board_states          │   audit_logs     │
              │      │ fusion_events         │                  │
              │      └───────────┬───────────┘                  │
              │                  │ (word_id)        user_achievements
              │                  ▼                  user_cosmetics
              │           ┌──────────────┐          user_daily_quests
              └──────────►│    words     │◄───── recipes (3 FK) ─── recipe_chains
                          └──────────────┘         word_topics
```

---

> 📝 **Ghi chú:** Một số ràng buộc `CHECK` (vd `coin_balance ≥ 0`, `ease_factor ≥ 1.3`, `rating 0..3`,
> `ingredient_1_id < ingredient_2_id`) được thêm thủ công qua **migration tay**, không khai báo trực tiếp trong Prisma schema.
