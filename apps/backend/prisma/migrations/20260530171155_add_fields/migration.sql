-- AlterTable
ALTER TABLE "achievements" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "administrative_units" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "audit_logs" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "board_states" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "coin_transactions" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "cosmetics" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "daily_quests" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "email_verification_tokens" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "fusion_events" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "password_reset_tokens" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "recipe_chains" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "recipes" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "refresh_tokens" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "review_logs" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "roles" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "study_sessions" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "user_achievements" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "user_cosmetics" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "user_daily_quests" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "user_roles" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "user_unlocked_words" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "user_word_notes" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "user_word_progress" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "users" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "word_topics" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;

-- AlterTable
ALTER TABLE "words" ALTER COLUMN "created_by" DROP NOT NULL,
ALTER COLUMN "updated_by" DROP NOT NULL;
