-- Quote table for inspirational cards shown on the Flutter home screen.
-- mantraId = NULL means universal (shown to all users).
-- Images are uploaded to the S3 quarantine prefix quotes/quarantine/.

CREATE TABLE "Quote" (
    "id"        TEXT NOT NULL,
    "text"      TEXT NOT NULL,
    "source"    TEXT,
    "imageUrl"  TEXT,
    "mantraId"  TEXT,
    "isActive"  BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Quote_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Quote_isActive_sortOrder_idx" ON "Quote"("isActive", "sortOrder");
CREATE INDEX "Quote_mantraId_idx" ON "Quote"("mantraId");

ALTER TABLE "Quote" ADD CONSTRAINT "Quote_mantraId_fkey"
    FOREIGN KEY ("mantraId") REFERENCES "Mantra"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
