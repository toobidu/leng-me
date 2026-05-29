-- ============================================================
-- ENGLISH FUSION GAME — PostgreSQL 16 Schema
-- Version: 2.2.0
-- Changelog:
--   v2.0 · Idiom chain support (is_intermediate, display_in_book)
--         · recipe_chains table cho multi-step fusion path
--         · [IDIOM] modifier card
--         · 10 idiom chain seeds mẫu
--         · Fix trigger fn_normalize_recipe_ingredients (LEAST/GREATEST)
--         · Thêm result_words seed đầy đủ cho compound recipes
--   v2.1 · RBAC: bảng roles + role_id FK trên users
--         · is_active flag trên users (ban/unban)
--         · audit_logs table (admin action trail)
--         · refresh_tokens table (JWT rotation)
--         · Seed 2 roles: ADMIN, USER
--   v2.2 · LEARNING CORE (app học chuẩn):
--         · user_word_progress  — SRS spaced-repetition (SM-2)
--         · study_sessions       — phiên học (thời gian, số thẻ)
--         · review_logs          — lịch sử từng lần ôn
--         · user_word_notes      — ghi chú cá nhân + đánh dấu yêu thích
--         · fusion_events        — log mỗi lần hợp thể (cho quest/achievement)
--         · email_verification_tokens + password_reset_tokens
--         · email_verified flag trên users
--         · View v_due_cards (hàng đợi ôn flashcard)
--         · FIX bug trigger fn_normalize_recipe_ingredients (OLD NULL khi INSERT)
-- ============================================================

-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- gen_random_uuid(), crypt()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";   -- trigram search trên words.text

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE cefr_level AS ENUM (
    'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'NATIVE'
);

CREATE TYPE word_tier AS ENUM (
    'COMMON',       -- Tier 1 · White/Gray  · A1-A2
    'RARE',         -- Tier 2 · Blue        · B1-B2
    'EPIC',         -- Tier 3 · Purple      · C1
    'LEGENDARY',    -- Tier 4 · Gold        · C2
    'MYTHIC'        -- Tier 5 · Rainbow/Red · Native / Idiom / Slang
);

CREATE TYPE token_type AS ENUM (
    'BASIC_WORD',
    'COMPOUND_WORD',
    'PHRASAL_VERB',
    'GRAMMAR_STRUCTURE',
    'IDIOM',
    'PREFIX',
    'SUFFIX',
    'MODIFIER_CARD',        -- Thẻ Topic / Academic-level / [IDIOM]
    'INTERMEDIATE_TOKEN'    -- Kết quả trung gian, không hiển thị trong collection
);

CREATE TYPE recipe_source AS ENUM ('CURATED', 'AI_GENERATED');

CREATE TYPE recipe_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

CREATE TYPE cosmetic_type AS ENUM (
    'BOARD_THEME', 'CARD_SKIN', 'EFFECT_PACK', 'AVATAR_FRAME'
);

CREATE TYPE coin_tx_type AS ENUM ('EARN', 'SPEND');

CREATE TYPE quest_reset_type AS ENUM ('DAILY', 'WEEKLY');

-- ============================================================
-- 1. ROLES  (RBAC Phase 1 — không có permissions table yet)
-- Phase 2: thêm permissions + role_permissions many-many
-- ============================================================

CREATE TABLE roles (
    id          SERIAL       PRIMARY KEY,
    name        VARCHAR(50)  NOT NULL UNIQUE,  -- 'ADMIN','USER','CONTENT_EDITOR','MODERATOR'
    description TEXT,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. USERS
-- ============================================================

CREATE TABLE users (
    id                  SERIAL          PRIMARY KEY,
    username            VARCHAR(50)     NOT NULL UNIQUE,
    password_hash       VARCHAR(255)    NOT NULL,
    email               VARCHAR(100)    UNIQUE,
    email_verified      BOOLEAN         NOT NULL DEFAULT FALSE,  -- xác thực email
    exp_points          INT             NOT NULL DEFAULT 0,
    coin_balance        INT             NOT NULL DEFAULT 0 CHECK (coin_balance >= 0),
    streak_days         INT             NOT NULL DEFAULT 0,
    last_login_at       TIMESTAMP,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,   -- FALSE = banned
    current_title_id    INT,    -- FK → achievements  (deferred below)
    active_cosmetic_id  INT,    -- FK → cosmetics      (deferred below)
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email     ON users (email);
CREATE INDEX idx_users_exp       ON users (exp_points DESC);
CREATE INDEX idx_users_is_active ON users (is_active) WHERE is_active = FALSE;

-- ============================================================
-- 3. USER_ROLES  (many-many: users ↔ roles)
-- Một user có thể mang nhiều role nếu cần
-- ============================================================

CREATE TABLE user_roles (
    user_id     INT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role_id     INT       NOT NULL REFERENCES roles (id) ON DELETE CASCADE,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by INT       REFERENCES users (id) ON DELETE SET NULL,  -- Admin nào gán

    PRIMARY KEY (user_id, role_id)
);

CREATE INDEX idx_user_roles_user ON user_roles (user_id);
CREATE INDEX idx_user_roles_role ON user_roles (role_id);

-- ============================================================
-- 2. WORDS
-- Bao gồm: từ thực, modifier card, grammar placeholder,
--           intermediate token (chỉ dùng để fusion tiếp)
-- ============================================================

CREATE TABLE words (
    id              SERIAL          PRIMARY KEY,
    text            VARCHAR(255)    NOT NULL,
    meaning         TEXT            NOT NULL,       -- Nghĩa tiếng Việt
    example_en      TEXT,                           -- Câu ví dụ tiếng Anh
    example_vi      TEXT,                           -- Dịch câu ví dụ
    level_code      cefr_level      NOT NULL,
    tier            word_tier       NOT NULL,
    token_type      token_type      NOT NULL DEFAULT 'BASIC_WORD',

    -- Game flags
    is_starter      BOOLEAN NOT NULL DEFAULT FALSE, -- Có sẵn khi mới bắt đầu
    is_intermediate BOOLEAN NOT NULL DEFAULT FALSE, -- Token trung gian (chỉ fusion, không học)
    display_in_book BOOLEAN NOT NULL DEFAULT TRUE,  -- Hiện trong Word Book collection

    -- Assets
    image_url       VARCHAR(512),
    audio_url       VARCHAR(512),
    effect_tag      VARCHAR(50),    -- VD: 'EFFECT_WATER_SPLASH', 'EFFECT_MYTHIC_RAINBOW'

    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- intermediate token không bao giờ hiển thị trong collection
    CONSTRAINT chk_intermediate_display
        CHECK (NOT (is_intermediate = TRUE AND display_in_book = TRUE))
);

CREATE UNIQUE INDEX idx_words_text      ON words (text);
CREATE INDEX idx_words_tier             ON words (tier);
CREATE INDEX idx_words_level            ON words (level_code);
CREATE INDEX idx_words_is_starter       ON words (is_starter)      WHERE is_starter = TRUE;
CREATE INDEX idx_words_is_intermediate  ON words (is_intermediate) WHERE is_intermediate = TRUE;
CREATE INDEX idx_words_text_trgm        ON words USING GIN (text gin_trgm_ops);

-- ============================================================
-- 3. WORD TOPICS
-- Nhiều topic trên một từ → trigger achievement theo chủ đề
-- ============================================================

CREATE TABLE word_topics (
    id      SERIAL      PRIMARY KEY,
    word_id INT         NOT NULL REFERENCES words (id) ON DELETE CASCADE,
    topic   VARCHAR(50) NOT NULL   -- 'weather','business','courage','time','money'...
);

CREATE UNIQUE INDEX idx_word_topics_unique ON word_topics (word_id, topic);
CREATE INDEX idx_word_topics_topic         ON word_topics (topic);

-- ============================================================
-- 4. RECIPES (Công thức hợp thể — 2 nguyên liệu)
-- Quy ước: ingredient_1_id < ingredient_2_id (trigger normalize bên dưới)
-- ============================================================

CREATE TABLE recipes (
    id                SERIAL        PRIMARY KEY,
    ingredient_1_id   INT           NOT NULL REFERENCES words (id) ON DELETE CASCADE,
    ingredient_2_id   INT           NOT NULL REFERENCES words (id) ON DELETE CASCADE,
    result_id         INT           NOT NULL REFERENCES words (id) ON DELETE CASCADE,
    source            recipe_source NOT NULL DEFAULT 'CURATED',
    status            recipe_status NOT NULL DEFAULT 'APPROVED',
    use_count         INT           NOT NULL DEFAULT 0,
    reviewed_by       INT           REFERENCES users (id) ON DELETE SET NULL,
    reviewed_at       TIMESTAMP,
    created_at        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_ingredient_order CHECK (ingredient_1_id < ingredient_2_id),
    CONSTRAINT uq_ingredient_pair   UNIQUE  (ingredient_1_id, ingredient_2_id)
);

CREATE INDEX idx_recipes_result      ON recipes (result_id);
CREATE INDEX idx_recipes_status      ON recipes (status);
CREATE INDEX idx_recipes_ingredient1 ON recipes (ingredient_1_id);
CREATE INDEX idx_recipes_ingredient2 ON recipes (ingredient_2_id);

-- ============================================================
-- 5. RECIPE CHAINS (Multi-step fusion path — dành cho Idiom)
-- Định nghĩa chuỗi bước tạo ra một idiom cuối cùng.
--
-- Ví dụ "Bite the bullet" (chain_group = 'CHAIN_BITE_THE_BULLET'):
--   step 1: Bite + Bullet  → [Bite·Bullet]   (intermediate)
--   step 2: [Bite·Bullet] + [IDIOM]  → "Bite the bullet"  (MYTHIC)
--
-- Mỗi step trỏ tới một recipe_id đã có trong bảng recipes.
-- ============================================================

CREATE TABLE recipe_chains (
    id              SERIAL      PRIMARY KEY,
    chain_group     VARCHAR(100) NOT NULL,  -- Mã nhóm: 'CHAIN_BITE_THE_BULLET'
    step_order      SMALLINT    NOT NULL,   -- 1, 2, 3...
    recipe_id       INT         NOT NULL REFERENCES recipes (id) ON DELETE CASCADE,
    hint_text       TEXT,                  -- Gợi ý hiển thị cho user ở bước này

    CONSTRAINT uq_chain_step UNIQUE (chain_group, step_order)
);

CREATE INDEX idx_recipe_chains_group ON recipe_chains (chain_group);

-- ============================================================
-- 6. USER UNLOCKED WORDS (Tiến trình học)
-- ============================================================

CREATE TABLE user_unlocked_words (
    user_id     INT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    word_id     INT       NOT NULL REFERENCES words (id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, word_id)
);

CREATE INDEX idx_unlocked_user ON user_unlocked_words (user_id);
CREATE INDEX idx_unlocked_word ON user_unlocked_words (word_id);
CREATE INDEX idx_unlocked_at   ON user_unlocked_words (unlocked_at DESC);

-- ============================================================
-- 7. BOARD STATES (Persistent game board)
-- Mỗi row = một card đang nằm trên board của user
-- ============================================================

CREATE TABLE board_states (
    id         SERIAL   PRIMARY KEY,
    user_id    INT      NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    word_id    INT      NOT NULL REFERENCES words (id) ON DELETE CASCADE,
    slot_index SMALLINT NOT NULL,
    pos_x      SMALLINT NOT NULL DEFAULT 0,
    pos_y      SMALLINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_board_slot UNIQUE (user_id, slot_index)
);

CREATE INDEX idx_board_user ON board_states (user_id);

-- ============================================================
-- 8. ACHIEVEMENTS
-- ============================================================

CREATE TABLE achievements (
    id                 SERIAL       PRIMARY KEY,
    title              VARCHAR(100) NOT NULL,
    description        TEXT         NOT NULL,
    icon_url           VARCHAR(512),
    req_condition_json JSONB        NOT NULL,
    -- Các type condition hỗ trợ:
    -- {"type":"total_unlocked","count":N}
    -- {"type":"count_by_tier","tier":"EPIC","count":N}
    -- {"type":"count_by_topic","topic":"weather","count":N}
    -- {"type":"fusion_count","count":N}
    -- {"type":"unlock_idiom_count","count":N}
    is_title_reward    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 9. USER ACHIEVEMENTS (Progress tracking)
-- ============================================================

CREATE TABLE user_achievements (
    user_id          INT     NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    achievement_id   INT     NOT NULL REFERENCES achievements (id) ON DELETE CASCADE,
    progress_current INT     NOT NULL DEFAULT 0,
    progress_target  INT     NOT NULL DEFAULT 1,
    unlocked_at      TIMESTAMP,   -- NULL = chưa hoàn thành

    PRIMARY KEY (user_id, achievement_id)
);

CREATE INDEX idx_user_ach_user     ON user_achievements (user_id);
CREATE INDEX idx_user_ach_unlocked ON user_achievements (unlocked_at)
    WHERE unlocked_at IS NOT NULL;

-- ============================================================
-- 10. DAILY QUESTS
-- ============================================================

CREATE TABLE daily_quests (
    id             SERIAL           PRIMARY KEY,
    title          VARCHAR(100)     NOT NULL,
    description    TEXT             NOT NULL,
    reset_type     quest_reset_type NOT NULL DEFAULT 'DAILY',
    condition_json JSONB            NOT NULL,
    coin_reward    INT              NOT NULL DEFAULT 0,
    exp_reward     INT              NOT NULL DEFAULT 0,
    is_active      BOOLEAN          NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 11. USER DAILY QUESTS
-- ============================================================

CREATE TABLE user_daily_quests (
    id            SERIAL    PRIMARY KEY,
    user_id       INT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    quest_id      INT       NOT NULL REFERENCES daily_quests (id) ON DELETE CASCADE,
    assigned_date DATE      NOT NULL DEFAULT CURRENT_DATE,
    progress      INT       NOT NULL DEFAULT 0,
    is_completed  BOOLEAN   NOT NULL DEFAULT FALSE,
    completed_at  TIMESTAMP,

    CONSTRAINT uq_user_quest_date UNIQUE (user_id, quest_id, assigned_date)
);

CREATE INDEX idx_udq_user_date ON user_daily_quests (user_id, assigned_date DESC);

-- ============================================================
-- 12. COIN TRANSACTIONS
-- ============================================================

CREATE TABLE coin_transactions (
    id         SERIAL       PRIMARY KEY,
    user_id    INT          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    amount     INT          NOT NULL,       -- Dương = nhận, Âm = tiêu
    type       coin_tx_type NOT NULL,
    reason     VARCHAR(100) NOT NULL,
    -- 'QUEST_REWARD','ACHIEVEMENT_REWARD','DAILY_LOGIN','HINT_USED','COSMETIC_PURCHASE'
    ref_id     INT,                         -- FK tuỳ context
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_coin_tx_user ON coin_transactions (user_id, created_at DESC);

-- ============================================================
-- 13. COSMETICS
-- ============================================================

CREATE TABLE cosmetics (
    id           SERIAL        PRIMARY KEY,
    name         VARCHAR(100)  NOT NULL,
    type         cosmetic_type NOT NULL,
    description  TEXT,
    preview_url  VARCHAR(512),
    price_coins  INT     NOT NULL DEFAULT 0 CHECK (price_coins >= 0),
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 14. USER COSMETICS
-- ============================================================

CREATE TABLE user_cosmetics (
    user_id     INT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    cosmetic_id INT       NOT NULL REFERENCES cosmetics (id) ON DELETE CASCADE,
    acquired_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, cosmetic_id)
);

CREATE INDEX idx_user_cosmetics_user ON user_cosmetics (user_id);

-- ============================================================
-- 15. REFRESH TOKENS  (JWT rotation & revocation)
-- Mỗi login tạo 1 refresh token. Logout / ban → xóa hoặc revoke.
-- ============================================================

CREATE TABLE refresh_tokens (
    id          SERIAL       PRIMARY KEY,
    user_id     INT          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL UNIQUE,  -- SHA-256 của token thực (không lưu plain)
    expires_at  TIMESTAMP    NOT NULL,
    revoked     BOOLEAN      NOT NULL DEFAULT FALSE,
    revoked_at  TIMESTAMP,
    user_agent  VARCHAR(512),                  -- Browser/device info
    ip_address  VARCHAR(45),                   -- IPv4 hoặc IPv6
    created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rt_user       ON refresh_tokens (user_id);
CREATE INDEX idx_rt_token_hash ON refresh_tokens (token_hash);
CREATE INDEX idx_rt_expires    ON refresh_tokens (expires_at)
    WHERE revoked = FALSE;  -- Partial index — chỉ index token còn hiệu lực

-- ============================================================
-- 16. AUDIT LOGS  (Admin action trail)
-- Ghi lại mọi hành động quan trọng của ADMIN để truy vết
-- ============================================================

CREATE TABLE audit_logs (
    id          BIGSERIAL    PRIMARY KEY,       -- BIGSERIAL vì volume lớn theo thời gian
    actor_id    INT          REFERENCES users (id) ON DELETE SET NULL,
    action      VARCHAR(100) NOT NULL,
    -- VD: 'USER_BAN', 'USER_UNBAN', 'RECIPE_APPROVE', 'RECIPE_REJECT',
    --     'WORD_CREATE', 'WORD_DELETE', 'ROLE_ASSIGN', 'ROLE_REVOKE'
    target_type VARCHAR(50),                    -- 'USER', 'RECIPE', 'WORD', 'ROLE'
    target_id   INT,                            -- ID của entity bị tác động
    old_value   JSONB,                          -- Snapshot trước khi thay đổi
    new_value   JSONB,                          -- Snapshot sau khi thay đổi
    ip_address  VARCHAR(45),
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_actor      ON audit_logs (actor_id);
CREATE INDEX idx_audit_action     ON audit_logs (action);
CREATE INDEX idx_audit_target     ON audit_logs (target_type, target_id);
CREATE INDEX idx_audit_created_at ON audit_logs (created_at DESC);

-- ============================================================
-- 17. USER WORD PROGRESS  (SRS — Spaced Repetition, thuật toán SM-2)
-- ĐÂY là phần lõi "học thuộc" của flashcard.
-- Khác user_unlocked_words: bảng kia chỉ ghi "đã mở khoá từ này",
-- bảng này ghi "học tới đâu, đúng/sai bao nhiêu, khi nào ôn lại".
-- ============================================================

CREATE TABLE user_word_progress (
    user_id          INT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    word_id          INT       NOT NULL REFERENCES words (id) ON DELETE CASCADE,
    ease_factor      REAL      NOT NULL DEFAULT 2.5,   -- SM-2 ease (>= 1.3)
    interval_days    INT       NOT NULL DEFAULT 0,     -- khoảng cách tới lần ôn kế
    repetitions      INT       NOT NULL DEFAULT 0,     -- số lần ôn ĐÚNG liên tiếp
    due_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- hạn ôn kế tiếp
    last_reviewed_at TIMESTAMP,
    correct_count    INT       NOT NULL DEFAULT 0,
    wrong_count      INT       NOT NULL DEFAULT 0,
    is_mastered      BOOLEAN   NOT NULL DEFAULT FALSE, -- đã thuộc lòng
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, word_id),
    CONSTRAINT chk_ease_factor CHECK (ease_factor >= 1.3)
);

-- Query nóng nhất: "những thẻ đến hạn ôn của user X"
CREATE INDEX idx_uwp_due      ON user_word_progress (user_id, due_at);
CREATE INDEX idx_uwp_mastered ON user_word_progress (user_id) WHERE is_mastered = TRUE;

-- ============================================================
-- 18. STUDY SESSIONS  (Phiên học — thống kê thời gian & số thẻ ôn)
-- ============================================================

CREATE TABLE study_sessions (
    id             SERIAL    PRIMARY KEY,
    user_id        INT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    started_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at       TIMESTAMP,
    cards_reviewed INT       NOT NULL DEFAULT 0,
    cards_correct  INT       NOT NULL DEFAULT 0,
    exp_earned     INT       NOT NULL DEFAULT 0
);

CREATE INDEX idx_study_sessions_user ON study_sessions (user_id, started_at DESC);

-- ============================================================
-- 19. REVIEW LOGS  (Lịch sử từng lần lật thẻ — biểu đồ tiến độ, phân tích SRS)
-- ============================================================

CREATE TABLE review_logs (
    id              BIGSERIAL PRIMARY KEY,
    user_id         INT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    word_id         INT       NOT NULL REFERENCES words (id) ON DELETE CASCADE,
    session_id      INT       REFERENCES study_sessions (id) ON DELETE SET NULL,
    rating          SMALLINT  NOT NULL,  -- 0=Again, 1=Hard, 2=Good, 3=Easy
    interval_before INT,                 -- snapshot trước/sau để tinh chỉnh thuật toán
    interval_after  INT,
    reviewed_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_rating CHECK (rating BETWEEN 0 AND 3)
);

CREATE INDEX idx_review_logs_user_time ON review_logs (user_id, reviewed_at DESC);
CREATE INDEX idx_review_logs_word      ON review_logs (word_id);

-- ============================================================
-- 20. USER WORD NOTES  (Ghi chú cá nhân + đánh dấu yêu thích cho từng từ)
-- ============================================================

CREATE TABLE user_word_notes (
    user_id     INT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    word_id     INT       NOT NULL REFERENCES words (id) ON DELETE CASCADE,
    note        TEXT,
    is_favorite BOOLEAN   NOT NULL DEFAULT FALSE,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, word_id)
);

CREATE INDEX idx_uwn_favorite ON user_word_notes (user_id) WHERE is_favorite = TRUE;

-- ============================================================
-- 21. FUSION EVENTS  (Log mỗi lần user hợp thể)
-- Phục vụ quest/achievement kiểu {"type":"fusion_count","count":N}
-- — use_count trên recipes là đếm TOÀN CỤC, không theo user.
-- ============================================================

CREATE TABLE fusion_events (
    id            BIGSERIAL PRIMARY KEY,
    user_id       INT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    recipe_id     INT       REFERENCES recipes (id) ON DELETE SET NULL,
    result_id     INT       NOT NULL REFERENCES words (id) ON DELETE CASCADE,
    is_first_time BOOLEAN   NOT NULL DEFAULT FALSE,  -- lần đầu user tạo ra từ này?
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fusion_events_user   ON fusion_events (user_id, created_at DESC);
CREATE INDEX idx_fusion_events_result ON fusion_events (result_id);

-- ============================================================
-- 22. EMAIL VERIFICATION & PASSWORD RESET TOKENS
-- Cùng pattern với refresh_tokens: chỉ lưu SHA-256, không lưu plain.
-- ============================================================

CREATE TABLE email_verification_tokens (
    id         SERIAL       PRIMARY KEY,
    user_id    INT          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP    NOT NULL,
    used_at    TIMESTAMP,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_evt_user ON email_verification_tokens (user_id);

CREATE TABLE password_reset_tokens (
    id         SERIAL       PRIMARY KEY,
    user_id    INT          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP    NOT NULL,
    used_at    TIMESTAMP,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_prt_user ON password_reset_tokens (user_id);

-- ============================================================
-- DEFERRED FOREIGN KEYS (circular refs)
-- ============================================================

ALTER TABLE users
    ADD CONSTRAINT fk_users_title
        FOREIGN KEY (current_title_id)   REFERENCES achievements (id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_users_cosmetic
        FOREIGN KEY (active_cosmetic_id) REFERENCES cosmetics (id)    ON DELETE SET NULL;

-- ============================================================
-- VIEWS
-- ============================================================

-- Leaderboard (Redis ZSET là nguồn chính — view này dùng cho admin/backup)
CREATE VIEW v_leaderboard AS
SELECT
    u.id,
    u.username,
    u.exp_points,
    COUNT(uuw.word_id)  AS total_words_unlocked,
    a.title             AS equipped_title
FROM users u
LEFT JOIN user_unlocked_words uuw ON uuw.user_id = u.id
LEFT JOIN achievements        a   ON a.id = u.current_title_id
GROUP BY u.id, u.username, u.exp_points, a.title
ORDER BY u.exp_points DESC;

-- User roles view — Spring Security dùng để load GrantedAuthority
CREATE VIEW v_user_roles AS
SELECT
    u.id            AS user_id,
    u.username,
    u.email,
    u.is_active,
    r.name          AS role_name,
    ur.assigned_at
FROM users u
JOIN user_roles ur ON ur.user_id = u.id
JOIN roles     r  ON r.id = ur.role_id
WHERE r.is_active = TRUE;

-- Recipes đã approved (backend dùng để lookup)
CREATE VIEW v_approved_recipes AS
SELECT
    r.id,
    r.ingredient_1_id,  w1.text  AS ingredient_1_text,
    r.ingredient_2_id,  w2.text  AS ingredient_2_text,
    r.result_id,        wr.text  AS result_text,
    wr.tier             AS result_tier,
    wr.is_intermediate  AS result_is_intermediate,
    r.source,
    r.use_count
FROM recipes r
JOIN words w1 ON w1.id = r.ingredient_1_id
JOIN words w2 ON w2.id = r.ingredient_2_id
JOIN words wr ON wr.id = r.result_id
WHERE r.status = 'APPROVED';

-- Idiom chains view — backend dùng để render hướng dẫn chain
CREATE VIEW v_idiom_chains AS
SELECT
    rc.chain_group,
    rc.step_order,
    w1.text     AS ingredient_1,
    w2.text     AS ingredient_2,
    wr.text     AS result,
    wr.tier     AS result_tier,
    wr.is_intermediate,
    rc.hint_text
FROM recipe_chains rc
JOIN recipes r  ON r.id  = rc.recipe_id
JOIN words   w1 ON w1.id = r.ingredient_1_id
JOIN words   w2 ON w2.id = r.ingredient_2_id
JOIN words   wr ON wr.id = r.result_id
ORDER BY rc.chain_group, rc.step_order;

-- Due cards view — hàng đợi ôn flashcard (chỉ từ học được, không lấy token trung gian)
-- App query thêm: WHERE user_id = $1 AND due_at <= CURRENT_TIMESTAMP
CREATE VIEW v_due_cards AS
SELECT
    uwp.user_id,
    w.id            AS word_id,
    w.text,
    w.meaning,
    w.example_en,
    w.example_vi,
    w.tier,
    uwp.due_at,
    uwp.repetitions,
    uwp.ease_factor,
    uwp.is_mastered
FROM user_word_progress uwp
JOIN words w ON w.id = uwp.word_id
WHERE w.is_intermediate = FALSE
  AND w.display_in_book  = TRUE
ORDER BY uwp.user_id, uwp.due_at;

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Tự động normalize ingredient order (ingredient_1_id luôn < ingredient_2_id)
CREATE OR REPLACE FUNCTION fn_normalize_recipe_ingredients()
RETURNS TRIGGER AS $$
DECLARE
    tmp INT;
BEGIN
    -- Đảm bảo ingredient_1_id < ingredient_2_id bằng cách hoán đổi qua biến tạm.
    -- KHÔNG dùng OLD ở đây: OLD = NULL khi INSERT → sẽ gây lỗi NOT NULL.
    IF NEW.ingredient_1_id > NEW.ingredient_2_id THEN
        tmp                 := NEW.ingredient_1_id;
        NEW.ingredient_1_id := NEW.ingredient_2_id;
        NEW.ingredient_2_id := tmp;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_normalize_recipe
    BEFORE INSERT OR UPDATE ON recipes
    FOR EACH ROW EXECUTE FUNCTION fn_normalize_recipe_ingredients();

-- Tự động cập nhật coin_balance sau mỗi INSERT vào coin_transactions
CREATE OR REPLACE FUNCTION fn_update_coin_balance()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users
    SET coin_balance = coin_balance + NEW.amount
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_coin_balance_sync
    AFTER INSERT ON coin_transactions
    FOR EACH ROW EXECUTE FUNCTION fn_update_coin_balance();

-- ============================================================
-- SEED DATA — SECTION 0: ROLES
-- ============================================================

INSERT INTO roles (name, description, is_active) VALUES
    ('ADMIN',          'Toàn quyền: dashboard, sysadmin, quản lý nội dung và user.',    TRUE),
    ('USER',           'Người chơi: học tiếng Anh, fusion từ vựng, leaderboard.',        TRUE),
    ('CONTENT_EDITOR', '[Phase 2] Duyệt recipe AI, thêm/sửa từ vựng. Chưa kích hoạt.', FALSE),
    ('MODERATOR',      '[Phase 2] Quản lý user, xử lý report. Chưa kích hoạt.',         FALSE);

-- Tạo tài khoản admin mặc định (password: Admin@123 — ĐỔI NGAY sau khi deploy)
-- password_hash = bcrypt(Admin@123, cost=12)
INSERT INTO users (username, password_hash, email, is_active) VALUES
    ('admin', '$2a$12$placeholderHashChangeBeforeDeploy000000000000000000000000', 'admin@englishfusion.com', TRUE);

-- Gán role ADMIN cho tài khoản admin vừa tạo
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u, roles r
WHERE u.username = 'admin' AND r.name = 'ADMIN';

-- ============================================================
-- SEED DATA — SECTION 1: STARTER WORDS (A1 · Tier COMMON)
-- ============================================================

INSERT INTO words (text, meaning, level_code, tier, token_type, is_starter, effect_tag) VALUES
    -- Danh từ cơ bản
    ('Sun',     'Mặt trời',     'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_LIGHT_BURST'),
    ('Moon',    'Mặt trăng',    'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_LIGHT_BURST'),
    ('Rain',    'Mưa',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_WATER_SPLASH'),
    ('Water',   'Nước',         'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_WATER_SPLASH'),
    ('Fire',    'Lửa',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_FIRE_BURST'),
    ('Wind',    'Gió',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_AIR_SWIRL'),
    ('Earth',   'Đất',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_EARTH_SHAKE'),
    ('Flower',  'Hoa',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Cat',     'Mèo',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Dog',     'Chó',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Coat',    'Áo khoác',     'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Light',   'Ánh sáng',     'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_LIGHT_BURST'),
    ('Fall',    'Rơi / Ngã',    'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_WATER_SPLASH'),
    ('Bullet',  'Viên đạn',     'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_FIRE_BURST'),
    ('Bucket',  'Cái xô',       'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_WATER_SPLASH'),
    ('Ice',     'Băng / Đá',    'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_WATER_SPLASH'),
    ('Break',   'Vỡ / Nghỉ',    'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_EARTH_SHAKE'),
    ('Bread',   'Bánh mì',      'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Butter',  'Bơ',           'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Bone',    'Xương',        'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Pick',    'Chọn / Nhặt',  'A1', 'COMMON', 'BASIC_WORD', TRUE, NULL),
    ('Hit',     'Đánh / Đập',   'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_EARTH_SHAKE'),
    ('Nail',    'Cái đinh',     'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_EARTH_SHAKE'),
    ('Head',    'Đầu',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Bed',     'Giường',       'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Bar',     'Thanh / Quầy', 'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Cloud',   'Đám mây',      'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_AIR_SWIRL'),
    ('Storm',   'Bão',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_AIR_SWIRL'),
    -- Động từ cơ bản
    ('Go',      'Đi',           'A1', 'COMMON', 'BASIC_WORD', TRUE, NULL),
    ('Make',    'Làm / Tạo ra', 'A1', 'COMMON', 'BASIC_WORD', TRUE, NULL),
    ('Bite',    'Cắn',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_FIRE_BURST'),
    ('Kick',    'Đá',           'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_EARTH_SHAKE'),
    ('Spill',   'Làm đổ',       'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_WATER_SPLASH'),
    ('Cry',     'Khóc',         'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_WATER_SPLASH'),
    ('Kill',    'Giết',         'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_FIRE_BURST'),
    ('Hang',    'Treo / Lơ lửng','A1','COMMON', 'BASIC_WORD', TRUE, NULL),
    ('Scratch', 'Cào / Gãi',    'A1', 'COMMON', 'BASIC_WORD', TRUE, NULL),
    ('Sit',     'Ngồi',         'A1', 'COMMON', 'BASIC_WORD', TRUE, NULL),
    ('Fence',   'Hàng rào',     'A1', 'COMMON', 'BASIC_WORD', TRUE, NULL),
    ('Burn',    'Đốt / Cháy',   'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_FIRE_BURST'),
    ('Bridge',  'Cây cầu',      'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_EARTH_SHAKE'),
    ('Milk',    'Sữa',          'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_WATER_SPLASH'),
    ('Spilt',   'Đã đổ (quá khứ của Spill)', 'A1', 'COMMON', 'BASIC_WORD', FALSE, NULL),
    -- Tính từ & khác
    ('Two',     'Số hai',       'A1', 'COMMON', 'BASIC_WORD', TRUE, NULL),
    ('Stone',   'Đá / Sỏi',     'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_EARTH_SHAKE'),
    ('Bird',    'Chim',         'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_AIR_SWIRL');

-- ============================================================
-- SEED DATA — SECTION 2: RESULT WORDS (Compound & Idiom targets)
-- ============================================================

INSERT INTO words (text, meaning, example_en, example_vi,
                   level_code, tier, token_type, is_starter,
                   is_intermediate, display_in_book, effect_tag) VALUES

    -- Compound Words (Tier 2 · RARE · B1-B2)
    ('Sunflower',   'Hoa hướng dương',
     'Sunflowers always face the sun.',
     'Hoa hướng dương luôn hướng về phía mặt trời.',
     'B1', 'RARE', 'COMPOUND_WORD', FALSE, FALSE, TRUE, 'EFFECT_SPARKLE'),

    ('Raincoat',    'Áo mưa',
     'Don''t forget your raincoat — it looks like rain.',
     'Đừng quên áo mưa — trời có vẻ sắp mưa.',
     'A2', 'COMMON', 'COMPOUND_WORD', FALSE, FALSE, TRUE, 'EFFECT_WATER_SPLASH'),

    ('Waterfall',   'Thác nước',
     'The waterfall was breathtaking.',
     'Thác nước thật ngoạn mục.',
     'B1', 'RARE', 'COMPOUND_WORD', FALSE, FALSE, TRUE, 'EFFECT_WATER_SPLASH'),

    ('Sunlight',    'Ánh nắng mặt trời',
     'Plants need sunlight to grow.',
     'Cây cần ánh nắng để phát triển.',
     'A2', 'COMMON', 'COMPOUND_WORD', FALSE, FALSE, TRUE, 'EFFECT_LIGHT_BURST'),

    ('Moonlight',   'Ánh trăng',
     'They walked under the moonlight.',
     'Họ đi dạo dưới ánh trăng.',
     'A2', 'COMMON', 'COMPOUND_WORD', FALSE, FALSE, TRUE, 'EFFECT_LIGHT_BURST'),

    ('Firelight',   'Ánh lửa',
     'The room was lit by firelight.',
     'Căn phòng được thắp sáng bằng ánh lửa.',
     'B1', 'RARE', 'COMPOUND_WORD', FALSE, FALSE, TRUE, 'EFFECT_FIRE_BURST'),

    ('Brainstorm',  'Động não / Suy nghĩ sáng tạo',
     'Let''s brainstorm some ideas for the campaign.',
     'Hãy cùng động não để nghĩ ra ý tưởng cho chiến dịch.',
     'B2', 'RARE', 'COMPOUND_WORD', FALSE, FALSE, TRUE, 'EFFECT_AIR_SWIRL'),

    ('Breakthrough','Bước đột phá',
     'The team made a major breakthrough.',
     'Nhóm đã đạt được một bước đột phá lớn.',
     'B2', 'RARE', 'COMPOUND_WORD', FALSE, FALSE, TRUE, 'EFFECT_UPGRADE_GLOW'),

    ('Headstone',   'Bia mộ',
     'The headstone was engraved with her name.',
     'Tấm bia mộ được khắc tên của bà.',
     'B2', 'RARE', 'COMPOUND_WORD', FALSE, FALSE, TRUE, 'EFFECT_EARTH_SHAKE'),

    ('Firebreak',   'Đường băng lửa (chống cháy rừng)',
     'The firebreak helped stop the wildfire.',
     'Đường băng lửa giúp ngăn chặn đám cháy rừng.',
     'C1', 'EPIC', 'COMPOUND_WORD', FALSE, FALSE, TRUE, 'EFFECT_FIRE_BURST'),

    -- INTERMEDIATE TOKENS (không học được, chỉ dùng để fusion tiếp)
    ('[Bite·Bullet]',       'Token trung gian: Cắn + Đạn',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    ('[Kick·Bucket]',       'Token trung gian: Đá + Xô',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    ('[Hit·Nail]',          'Token trung gian: Đánh + Đinh',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    ('[Spill·Beans]',       'Token trung gian: Đổ + Đậu',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    ('[Break·Ice]',         'Token trung gian: Phá + Băng',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    ('[Burn·Bridge]',       'Token trung gian: Đốt + Cầu',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    ('[Cry·Milk]',          'Token trung gian: Khóc + Sữa',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    ('[Kill·Bird]',         'Token trung gian: Giết + Chim',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    ('[Sit·Fence]',         'Token trung gian: Ngồi + Hàng rào',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    ('[Scratch·Surface]',   'Token trung gian: Cào + Bề mặt',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    ('[Hang·Fire]',         'Token trung gian: Treo + Lửa',
     NULL, NULL,
     'A1', 'COMMON', 'INTERMEDIATE_TOKEN', FALSE, TRUE, FALSE, NULL),

    -- IDIOM TARGETS (Tier 5 · MYTHIC · Native)
    ('Bite the bullet',
     'Cắn răng chịu đựng / Chấp nhận điều khó khăn một cách dũng cảm',
     'I didn''t want to have the surgery, but I bit the bullet and did it.',
     'Tôi không muốn phẫu thuật, nhưng đã cắn răng chịu đựng và làm.',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW'),

    ('Kick the bucket',
     'Từ trần / Qua đời (cách nói thông tục, hài hước)',
     'He finally kicked the bucket at the age of 95.',
     'Cuối cùng ông ấy cũng ra đi ở tuổi 95.',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW'),

    ('Hit the nail on the head',
     'Nói đúng trọng tâm / Nhận xét chính xác',
     'You hit the nail on the head with that analysis.',
     'Anh đã phân tích đúng trọng tâm vấn đề.',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW'),

    ('Spill the beans',
     'Tiết lộ bí mật / Lỡ miệng',
     'Who spilled the beans about the surprise party?',
     'Ai đã tiết lộ về bữa tiệc bí mật vậy?',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW'),

    ('Break the ice',
     'Phá vỡ sự ngại ngùng / Mở đầu câu chuyện',
     'He told a joke to break the ice at the meeting.',
     'Anh ấy kể một câu chuyện cười để phá vỡ bầu không khí trong cuộc họp.',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW'),

    ('Burn one''s bridges',
     'Đốt cầu đã qua / Phá vỡ quan hệ không thể cứu vãn',
     'Don''t burn your bridges — you might need their help later.',
     'Đừng đốt cầu — bạn có thể cần sự giúp đỡ của họ sau này.',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW'),

    ('Don''t cry over spilt milk',
     'Đừng than vãn về chuyện đã rồi',
     'The deal fell through, but don''t cry over spilt milk.',
     'Thương vụ thất bại, nhưng đừng than vãn về chuyện đã rồi.',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW'),

    ('Kill two birds with one stone',
     'Một mũi tên trúng hai đích',
     'By working out during lunch, I killed two birds with one stone.',
     'Bằng cách tập thể dục vào giờ trưa, tôi đã một mũi tên trúng hai đích.',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW'),

    ('Sit on the fence',
     'Đứng giữa hai phe / Không chọn lập trường',
     'Stop sitting on the fence and make a decision.',
     'Đừng đứng giữa hai phe nữa, hãy đưa ra quyết định đi.',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW'),

    ('Scratch the surface',
     'Chỉ mới chạm đến bề nổi / Chưa đi sâu vào vấn đề',
     'This report barely scratches the surface of the issue.',
     'Báo cáo này mới chỉ chạm đến bề nổi của vấn đề.',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW'),

    ('Hang fire',
     'Tạm hoãn / Chờ đợi trước khi hành động',
     'Let''s hang fire on that decision until we have more data.',
     'Hãy tạm hoãn quyết định đó cho đến khi có thêm dữ liệu.',
     'NATIVE', 'MYTHIC', 'IDIOM', FALSE, FALSE, TRUE, 'EFFECT_MYTHIC_RAINBOW');

-- Thêm từ 'Beans' và 'Surface' vào starter words (cần cho idiom chains)
INSERT INTO words (text, meaning, level_code, tier, token_type, is_starter, effect_tag) VALUES
    ('Beans',   'Hạt đậu',      'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_SPARKLE'),
    ('Surface', 'Bề mặt',       'A1', 'COMMON', 'BASIC_WORD', TRUE, 'EFFECT_EARTH_SHAKE');

-- ============================================================
-- SEED DATA — SECTION 3: MODIFIER CARDS
-- ============================================================

INSERT INTO words (text, meaning, level_code, tier, token_type, is_starter, effect_tag) VALUES
    -- Suffix / Prefix
    ('-ment',   'Hậu tố danh từ hoá (VD: manage → management)', 'A1', 'COMMON', 'SUFFIX',        TRUE, NULL),
    ('-tion',   'Hậu tố danh từ hoá (VD: inform → information)', 'A1', 'COMMON', 'SUFFIX',        TRUE, NULL),
    ('-ful',    'Hậu tố: đầy/nhiều (VD: care → careful)',        'A1', 'COMMON', 'SUFFIX',        TRUE, NULL),
    ('un-',     'Tiền tố phủ định (VD: happy → unhappy)',        'A1', 'COMMON', 'PREFIX',        TRUE, NULL),
    -- Academic / Topic modifier
    ('[IELTS]', 'Thẻ nâng cấp từ vựng lên cấp IELTS',           'B1', 'RARE',   'MODIFIER_CARD', TRUE, 'EFFECT_UPGRADE_GLOW'),
    ('[Business]','Thẻ chủ đề Kinh doanh',                       'B1', 'RARE',   'MODIFIER_CARD', TRUE, 'EFFECT_UPGRADE_GLOW'),
    -- IDIOM catalyst card — quan trọng nhất cho idiom chain
    ('[IDIOM]', 'Thẻ catalyst chuyển hoá token trung gian thành thành ngữ MYTHIC',
                                                                  'B2', 'RARE',   'MODIFIER_CARD', TRUE, 'EFFECT_MYTHIC_RAINBOW');

-- ============================================================
-- SEED DATA — SECTION 4: GRAMMAR PLACEHOLDERS
-- ============================================================

INSERT INTO words (text, meaning, level_code, tier, token_type, is_starter) VALUES
    ('[Someone]',   'Placeholder: chủ thể người',          'A1', 'COMMON', 'GRAMMAR_STRUCTURE', TRUE),
    ('[Something]', 'Placeholder: chủ thể vật',            'A1', 'COMMON', 'GRAMMAR_STRUCTURE', TRUE),
    ('[V-ing]',     'Placeholder: động từ thêm -ing',      'A1', 'COMMON', 'GRAMMAR_STRUCTURE', TRUE),
    ('[To-V]',      'Placeholder: động từ nguyên mẫu',     'A1', 'COMMON', 'GRAMMAR_STRUCTURE', TRUE);

-- ============================================================
-- SEED DATA — SECTION 5: RECIPES (Compound Words)
-- ============================================================

WITH w AS (SELECT id, text FROM words)
INSERT INTO recipes (ingredient_1_id, ingredient_2_id, result_id, source, status)
SELECT
    LEAST(a.id, b.id),
    GREATEST(a.id, b.id),
    r.id,
    'CURATED',
    'APPROVED'
FROM (VALUES
    ('Sun',     'Flower',   'Sunflower'),
    ('Rain',    'Coat',     'Raincoat'),
    ('Water',   'Fall',     'Waterfall'),
    ('Sun',     'Light',    'Sunlight'),
    ('Moon',    'Light',    'Moonlight'),
    ('Fire',    'Light',    'Firelight'),
    ('Brain',   'Storm',    'Brainstorm'),
    ('Break',   'Through',  'Breakthrough'),
    ('Head',    'Stone',    'Headstone'),
    ('Fire',    'Break',    'Firebreak')
) AS combos(ing1, ing2, res)
JOIN w a ON a.text = combos.ing1
JOIN w b ON b.text = combos.ing2
JOIN w r ON r.text = combos.res
ON CONFLICT DO NOTHING;

-- ============================================================
-- SEED DATA — SECTION 6: IDIOM RECIPES
-- Mỗi idiom = 2 recipes: Step1 (raw → intermediate) + Step2 (intermediate + [IDIOM] → MYTHIC)
-- Trigger normalize tự xử lý thứ tự ingredient_1_id < ingredient_2_id
-- ============================================================

WITH w AS (SELECT id, text FROM words)
INSERT INTO recipes (ingredient_1_id, ingredient_2_id, result_id, source, status)
SELECT
    LEAST(a.id, b.id),
    GREATEST(a.id, b.id),
    r.id,
    'CURATED',
    'APPROVED'
FROM (VALUES
    -- === IDIOM 1: Bite the bullet ===
    -- Step 1
    ('Bite',            'Bullet',       '[Bite·Bullet]'),
    -- Step 2
    ('[Bite·Bullet]',   '[IDIOM]',      'Bite the bullet'),

    -- === IDIOM 2: Kick the bucket ===
    ('Bucket',          'Kick',         '[Kick·Bucket]'),
    ('[Kick·Bucket]',   '[IDIOM]',      'Kick the bucket'),

    -- === IDIOM 3: Hit the nail on the head ===
    ('Hit',             'Nail',         '[Hit·Nail]'),
    ('[Hit·Nail]',      '[IDIOM]',      'Hit the nail on the head'),

    -- === IDIOM 4: Spill the beans ===
    ('Beans',           'Spill',        '[Spill·Beans]'),
    ('[Spill·Beans]',   '[IDIOM]',      'Spill the beans'),

    -- === IDIOM 5: Break the ice ===
    ('Break',           'Ice',          '[Break·Ice]'),
    ('[Break·Ice]',     '[IDIOM]',      'Break the ice'),

    -- === IDIOM 6: Burn one's bridges ===
    ('Bridge',          'Burn',         '[Burn·Bridge]'),
    ('[Burn·Bridge]',   '[IDIOM]',      'Burn one''s bridges'),

    -- === IDIOM 7: Don't cry over spilt milk ===
    ('Cry',             'Milk',         '[Cry·Milk]'),
    ('[Cry·Milk]',      '[IDIOM]',      'Don''t cry over spilt milk'),

    -- === IDIOM 8: Kill two birds with one stone ===
    ('Bird',            'Kill',         '[Kill·Bird]'),
    ('[Kill·Bird]',     '[IDIOM]',      'Kill two birds with one stone'),

    -- === IDIOM 9: Sit on the fence ===
    ('Fence',           'Sit',          '[Sit·Fence]'),
    ('[Sit·Fence]',     '[IDIOM]',      'Sit on the fence'),

    -- === IDIOM 10: Scratch the surface ===
    ('Scratch',         'Surface',      '[Scratch·Surface]'),
    ('[Scratch·Surface]','[IDIOM]',     'Scratch the surface')

) AS combos(ing1, ing2, res)
JOIN w a ON a.text = combos.ing1
JOIN w b ON b.text = combos.ing2
JOIN w r ON r.text = combos.res
ON CONFLICT DO NOTHING;

-- ============================================================
-- SEED DATA — SECTION 7: RECIPE CHAINS
-- Liên kết các recipe thành chuỗi có thứ tự cho từng idiom
-- ============================================================

INSERT INTO recipe_chains (chain_group, step_order, recipe_id, hint_text)
SELECT
    c.chain_group,
    c.step_order,
    r.id,
    c.hint_text
FROM (VALUES
    ('CHAIN_BITE_THE_BULLET',        1, 'Bite',             'Bullet',           '[Bite·Bullet]',          'Thử ghép hành động với vật thể liên quan...'),
    ('CHAIN_BITE_THE_BULLET',        2, '[Bite·Bullet]',    '[IDIOM]',          'Bite the bullet',        'Dùng thẻ [IDIOM] để chuyển hoá!'),
    ('CHAIN_KICK_THE_BUCKET',        1, 'Kick',             'Bucket',           '[Kick·Bucket]',          'Vật dụng gia đình + hành động chân...'),
    ('CHAIN_KICK_THE_BUCKET',        2, '[Kick·Bucket]',    '[IDIOM]',          'Kick the bucket',        'Dùng thẻ [IDIOM] để chuyển hoá!'),
    ('CHAIN_HIT_THE_NAIL',           1, 'Hit',              'Nail',             '[Hit·Nail]',             'Công cụ xây dựng + hành động...'),
    ('CHAIN_HIT_THE_NAIL',           2, '[Hit·Nail]',       '[IDIOM]',          'Hit the nail on the head','Dùng thẻ [IDIOM] để chuyển hoá!'),
    ('CHAIN_SPILL_THE_BEANS',        1, 'Spill',            'Beans',            '[Spill·Beans]',          'Thực phẩm + hành động vô ý...'),
    ('CHAIN_SPILL_THE_BEANS',        2, '[Spill·Beans]',    '[IDIOM]',          'Spill the beans',        'Dùng thẻ [IDIOM] để chuyển hoá!'),
    ('CHAIN_BREAK_THE_ICE',          1, 'Break',            'Ice',              '[Break·Ice]',            'Phá vỡ điều gì đó lạnh lẽo...'),
    ('CHAIN_BREAK_THE_ICE',          2, '[Break·Ice]',      '[IDIOM]',          'Break the ice',          'Dùng thẻ [IDIOM] để chuyển hoá!'),
    ('CHAIN_BURN_BRIDGES',           1, 'Burn',             'Bridge',           '[Burn·Bridge]',          'Lửa + công trình...'),
    ('CHAIN_BURN_BRIDGES',           2, '[Burn·Bridge]',    '[IDIOM]',          'Burn one''s bridges',    'Dùng thẻ [IDIOM] để chuyển hoá!'),
    ('CHAIN_CRY_MILK',               1, 'Cry',              'Milk',             '[Cry·Milk]',             'Cảm xúc + thức uống...'),
    ('CHAIN_CRY_MILK',               2, '[Cry·Milk]',       '[IDIOM]',          'Don''t cry over spilt milk','Dùng thẻ [IDIOM] để chuyển hoá!'),
    ('CHAIN_KILL_TWO_BIRDS',         1, 'Kill',             'Bird',             '[Kill·Bird]',            'Hành động + sinh vật...'),
    ('CHAIN_KILL_TWO_BIRDS',         2, '[Kill·Bird]',      '[IDIOM]',          'Kill two birds with one stone','Dùng thẻ [IDIOM] để chuyển hoá!'),
    ('CHAIN_SIT_ON_FENCE',           1, 'Sit',              'Fence',            '[Sit·Fence]',            'Hành động + vật cản...'),
    ('CHAIN_SIT_ON_FENCE',           2, '[Sit·Fence]',      '[IDIOM]',          'Sit on the fence',       'Dùng thẻ [IDIOM] để chuyển hoá!'),
    ('CHAIN_SCRATCH_SURFACE',        1, 'Scratch',          'Surface',          '[Scratch·Surface]',      'Hành động + bề mặt...'),
    ('CHAIN_SCRATCH_SURFACE',        2, '[Scratch·Surface]','[IDIOM]',          'Scratch the surface',    'Dùng thẻ [IDIOM] để chuyển hoá!')
) AS c(chain_group, step_order, ing1_text, ing2_text, res_text, hint_text)
JOIN recipes r ON r.id = (
    SELECT rec.id FROM recipes rec
    JOIN words w1 ON w1.id = rec.ingredient_1_id AND w1.text = c.ing1_text
    JOIN words w2 ON w2.id = rec.ingredient_2_id AND w2.text = c.ing2_text
    JOIN words wr ON wr.id = rec.result_id        AND wr.text = c.res_text
    LIMIT 1
)
ON CONFLICT DO NOTHING;

-- ============================================================
-- SEED DATA — SECTION 8: WORD TOPICS
-- ============================================================

INSERT INTO word_topics (word_id, topic)
SELECT w.id, t.topic
FROM (VALUES
    ('Rain',                        'weather'),
    ('Storm',                       'weather'),
    ('Cloud',                       'weather'),
    ('Wind',                        'weather'),
    ('Sun',                         'weather'),
    ('Sunlight',                    'weather'),
    ('Raincoat',                    'weather'),
    ('Waterfall',                   'nature'),
    ('Sunflower',                   'nature'),
    ('Firelight',                   'nature'),
    ('Moonlight',                   'nature'),
    ('Bite the bullet',             'courage'),
    ('Hang fire',                   'courage'),
    ('Sit on the fence',            'courage'),
    ('Burn one''s bridges',         'courage'),
    ('Spill the beans',             'communication'),
    ('Break the ice',               'communication'),
    ('Hit the nail on the head',    'communication'),
    ('Scratch the surface',         'communication'),
    ('Kill two birds with one stone','productivity'),
    ('Brainstorm',                  'productivity'),
    ('Breakthrough',                'productivity'),
    ('Kick the bucket',             'life'),
    ('Don''t cry over spilt milk',  'life')
) AS t(word_text, topic)
JOIN words w ON w.text = t.word_text
ON CONFLICT DO NOTHING;

-- ============================================================
-- SEED DATA — SECTION 9: ACHIEVEMENTS
-- ============================================================

INSERT INTO achievements (title, description, req_condition_json, is_title_reward) VALUES
    ('First Discovery',
     'Mở khoá từ vựng đầu tiên bằng cách hợp thể.',
     '{"type":"total_unlocked","count":1}',
     FALSE),

    ('Mythic Hunter',
     'Tổng hợp thành công thành ngữ MYTHIC đầu tiên.',
     '{"type":"unlock_idiom_count","count":1}',
     TRUE),

    ('Idiom Master',
     'Mở khoá 5 thành ngữ MYTHIC.',
     '{"type":"unlock_idiom_count","count":5}',
     TRUE),

    ('Weather Man',
     'Mở khoá đủ 5 từ chủ đề thời tiết.',
     '{"type":"count_by_topic","topic":"weather","count":5}',
     TRUE),

    ('Brave Heart',
     'Mở khoá 4 thành ngữ chủ đề lòng dũng cảm.',
     '{"type":"count_by_topic","topic":"courage","count":4}',
     TRUE),

    ('Chiến thần IELTS',
     'Mở khoá 50 từ cấp độ Epic (C1) trở lên.',
     '{"type":"count_by_tier","tier":"EPIC","count":50}',
     TRUE),

    ('Legendary Scholar',
     'Sở hữu ít nhất 10 từ Legendary (C2).',
     '{"type":"count_by_tier","tier":"LEGENDARY","count":10}',
     TRUE),

    ('Combo Master',
     'Thực hiện 100 lần hợp thể thành công.',
     '{"type":"fusion_count","count":100}',
     FALSE),

    ('Word Collector',
     'Mở khoá tổng cộng 50 từ vựng.',
     '{"type":"total_unlocked","count":50}',
     FALSE),

    ('Encyclopedia',
     'Mở khoá tổng cộng 200 từ vựng.',
     '{"type":"total_unlocked","count":200}',
     TRUE);

-- ============================================================
-- SEED DATA — SECTION 10: DAILY QUESTS
-- ============================================================

INSERT INTO daily_quests (title, description, reset_type, condition_json, coin_reward, exp_reward) VALUES
    ('Warm Up',
     'Thực hiện 3 lần hợp thể trong ngày.',
     'DAILY', '{"type":"fusion_count","count":3}',
     10, 50),

    ('Explorer',
     'Mở khoá 1 từ mới cấp Rare trở lên.',
     'DAILY', '{"type":"unlock_tier","tier":"RARE","count":1}',
     20, 100),

    ('Idiom Hunter',
     'Tổng hợp thành công 1 thành ngữ MYTHIC.',
     'DAILY', '{"type":"unlock_idiom_count","count":1}',
     50, 200),

    ('Weekly Grinder',
     'Mở khoá tổng cộng 20 từ mới trong tuần.',
     'WEEKLY', '{"type":"total_unlocked_this_week","count":20}',
     100, 500),

    ('Chain Master',
     'Hoàn thành 2 idiom chain trong tuần.',
     'WEEKLY', '{"type":"unlock_idiom_count","count":2}',
     150, 600);

-- ============================================================
-- SEED DATA — SECTION 11: COSMETICS
-- ============================================================

INSERT INTO cosmetics (name, type, description, price_coins, is_available) VALUES
    ('Default',         'BOARD_THEME',  'Giao diện mặc định.',                   0,   TRUE),
    ('Dark Forest',     'BOARD_THEME',  'Nền tối bí ẩn, ánh sáng xanh lá.',     200,  TRUE),
    ('Ocean Breeze',    'BOARD_THEME',  'Nền biển dịu mát.',                     200,  TRUE),
    ('Mythic Void',     'BOARD_THEME',  'Nền cầu vồng huyền bí dành cho Idiom Master.', 500, TRUE),
    ('Gold Frame',      'AVATAR_FRAME', 'Khung avatar vàng cho Legendary.',      500,  TRUE),
    ('Rainbow Skin',    'CARD_SKIN',    'Thẻ bài đổi màu cầu vồng.',            300,  TRUE),
    ('Fire Skin',       'CARD_SKIN',    'Thẻ bài bốc lửa.',                     250,  TRUE),
    ('Mythic Effects',  'EFFECT_PACK',  'Gói hiệu ứng nâng cấp cho MYTHIC cards.',400, TRUE);

-- ============================================================
-- END OF SCHEMA v2.2.0
-- ============================================================
