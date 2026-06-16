-- AlterTable: add per-member preferred mantra display language/script.
-- Defaults to 'hi' (Devanagari, the canonical chant script). Independent of
-- the existing `language` column, which drives the app UI language.
ALTER TABLE "Member" ADD COLUMN "mantraLanguage" TEXT NOT NULL DEFAULT 'hi';
