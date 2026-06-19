-- Global Sadhana feature: community-wide spiritual initiative tables.
-- Sessions posted by enrolled members automatically credit the global count
-- (server-side in /api/v1/sessions) — no client changes needed.

CREATE TYPE "GlobalSadhanaStatus" AS ENUM ('draft', 'published', 'active', 'paused', 'completed', 'archived');
CREATE TYPE "ParticipationMode"   AS ENUM ('voice', 'handwriting', 'both');

CREATE TABLE "GlobalSadhana" (
    "id"                TEXT NOT NULL,
    "title"             TEXT NOT NULL,
    "description"       TEXT NOT NULL DEFAULT '',
    "mantraId"          TEXT NOT NULL,
    "mantraText"        TEXT,
    "mantraLanguage"    TEXT NOT NULL DEFAULT 'hi',
    "targetCount"       INTEGER NOT NULL,
    "currentCount"      INTEGER NOT NULL DEFAULT 0,
    "startAt"           TIMESTAMP(3) NOT NULL,
    "endAt"             TIMESTAMP(3),
    "imageUrl"          TEXT,
    "isSponsored"       BOOLEAN NOT NULL DEFAULT false,
    "status"            "GlobalSadhanaStatus" NOT NULL DEFAULT 'draft',
    "participationMode" "ParticipationMode"   NOT NULL DEFAULT 'both',
    "instructions"      TEXT,
    "createdByAdminId"  TEXT,
    "createdAt"         TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"         TIMESTAMP(3) NOT NULL,
    "completedAt"       TIMESTAMP(3),

    CONSTRAINT "GlobalSadhana_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "GlobalSadhanaEnrollment" (
    "id"                          TEXT NOT NULL,
    "globalSadhanaId"             TEXT NOT NULL,
    "memberId"                    TEXT NOT NULL,
    "enrolledAt"                  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "voiceTrainingComplete"       BOOLEAN NOT NULL DEFAULT false,
    "handwritingTrainingComplete" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "GlobalSadhanaEnrollment_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "GlobalSadhanaContribution" (
    "id"              TEXT NOT NULL,
    "globalSadhanaId" TEXT NOT NULL,
    "memberId"        TEXT NOT NULL,
    "countAdded"      INTEGER NOT NULL,
    "modality"        "SessionModality" NOT NULL,
    "sessionId"       TEXT,
    "createdAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GlobalSadhanaContribution_pkey" PRIMARY KEY ("id")
);

-- Indexes
CREATE INDEX "GlobalSadhana_status_startAt_idx"                ON "GlobalSadhana"("status", "startAt");
CREATE INDEX "GlobalSadhana_mantraId_idx"                      ON "GlobalSadhana"("mantraId");
CREATE UNIQUE INDEX "GlobalSadhanaEnrollment_globalSadhanaId_memberId_key"
    ON "GlobalSadhanaEnrollment"("globalSadhanaId", "memberId");
CREATE INDEX "GlobalSadhanaEnrollment_globalSadhanaId_idx"     ON "GlobalSadhanaEnrollment"("globalSadhanaId");
CREATE INDEX "GlobalSadhanaEnrollment_memberId_idx"            ON "GlobalSadhanaEnrollment"("memberId");
CREATE INDEX "GlobalSadhanaContribution_globalSadhanaId_memberId_idx"
    ON "GlobalSadhanaContribution"("globalSadhanaId", "memberId");
CREATE INDEX "GlobalSadhanaContribution_globalSadhanaId_createdAt_idx"
    ON "GlobalSadhanaContribution"("globalSadhanaId", "createdAt");
CREATE INDEX "GlobalSadhanaContribution_memberId_idx"          ON "GlobalSadhanaContribution"("memberId");

-- Foreign keys
ALTER TABLE "GlobalSadhana"
    ADD CONSTRAINT "GlobalSadhana_mantraId_fkey"
    FOREIGN KEY ("mantraId") REFERENCES "Mantra"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "GlobalSadhanaEnrollment"
    ADD CONSTRAINT "GlobalSadhanaEnrollment_globalSadhanaId_fkey"
    FOREIGN KEY ("globalSadhanaId") REFERENCES "GlobalSadhana"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT "GlobalSadhanaEnrollment_memberId_fkey"
    FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "GlobalSadhanaContribution"
    ADD CONSTRAINT "GlobalSadhanaContribution_globalSadhanaId_fkey"
    FOREIGN KEY ("globalSadhanaId") REFERENCES "GlobalSadhana"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT "GlobalSadhanaContribution_memberId_fkey"
    FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;
