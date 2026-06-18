-- Add share image + text template to Mantra
ALTER TABLE "Mantra" ADD COLUMN "shareImageUrl" TEXT;
ALTER TABLE "Mantra" ADD COLUMN "shareText"     TEXT;
