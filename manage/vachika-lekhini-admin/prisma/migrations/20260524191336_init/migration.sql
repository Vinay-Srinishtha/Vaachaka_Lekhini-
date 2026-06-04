-- CreateEnum
CREATE TYPE "ThumbPalette" AS ENUM ('saffron', 'shiva', 'gayatri', 'maha', 'hanuman', 'vishnu', 'krishna');

-- CreateEnum
CREATE TYPE "MantraTag" AS ENUM ('peace', 'righteousness', 'healing', 'protection', 'strength', 'courage', 'wealth', 'prosperity', 'liberation', 'enlightenment', 'wisdom', 'devotion');

-- CreateEnum
CREATE TYPE "FlagType" AS ENUM ('bool', 'int', 'string', 'json');

-- CreateEnum
CREATE TYPE "FamilyRelation" AS ENUM ('self', 'spouse', 'parent', 'child', 'sibling', 'friend', 'other');

-- CreateEnum
CREATE TYPE "SessionModality" AS ENUM ('voice', 'handwriting', 'manual');

-- CreateEnum
CREATE TYPE "RewardEventKind" AS ENUM ('earn', 'spend', 'milestone', 'gift', 'refund');

-- CreateEnum
CREATE TYPE "HandwritingMode" AS ENUM ('writeOnScreen', 'captureCamera', 'uploadGallery', 'useDefaultFont');

-- CreateEnum
CREATE TYPE "DevicePlatform" AS ENUM ('android', 'ios', 'web');

-- CreateEnum
CREATE TYPE "InviteStatus" AS ENUM ('pending', 'accepted', 'expired');

-- CreateEnum
CREATE TYPE "AdminRole" AS ENUM ('super_admin', 'editor', 'viewer');

-- CreateTable
CREATE TABLE "Mantra" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "nameDevanagari" TEXT NOT NULL,
    "nameRoman" TEXT NOT NULL,
    "nameTelugu" TEXT,
    "nameKannada" TEXT,
    "description" TEXT NOT NULL,
    "deity" TEXT,
    "thumbPalette" "ThumbPalette" NOT NULL,
    "tags" "MantraTag"[],
    "recommendedCount" INTEGER,
    "recommendedDays" INTEGER,
    "pronunciationUrl" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Mantra_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StoreItem" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "pointsCost" INTEGER NOT NULL,
    "imageUrl" TEXT,
    "stock" INTEGER,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StoreItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FeatureFlag" (
    "key" TEXT NOT NULL,
    "valueType" "FlagType" NOT NULL,
    "value" JSONB NOT NULL,
    "description" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FeatureFlag_pkey" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "Account" (
    "id" TEXT NOT NULL,
    "mobile" TEXT NOT NULL,
    "countryCode" TEXT NOT NULL DEFAULT '+91',
    "passwordHash" TEXT,
    "passwordSetAt" TIMESTAMP(3),
    "referralCode" TEXT,
    "invitedById" TEXT,
    "isBanned" BOOLEAN NOT NULL DEFAULT false,
    "bannedReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastSeenAt" TIMESTAMP(3),

    CONSTRAINT "Account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Member" (
    "id" TEXT NOT NULL,
    "accountId" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "relation" "FamilyRelation" NOT NULL DEFAULT 'other',
    "avatarKey" TEXT,
    "language" TEXT NOT NULL DEFAULT 'en',
    "birthYear" INTEGER,
    "preferences" JSONB NOT NULL DEFAULT '{}',
    "isPrimary" BOOLEAN NOT NULL DEFAULT false,
    "rewardPointsBalance" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "lastActiveAt" TIMESTAMP(3),

    CONSTRAINT "Member_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Program" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "mantraId" TEXT NOT NULL,
    "targetWritings" INTEGER NOT NULL,
    "targetDays" INTEGER NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completedAt" TIMESTAMP(3),
    "totalWritings" INTEGER NOT NULL DEFAULT 0,
    "currentStreak" INTEGER NOT NULL DEFAULT 0,
    "longestStreak" INTEGER NOT NULL DEFAULT 0,
    "lastActiveDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Program_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "programId" TEXT NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL,
    "endedAt" TIMESTAMP(3),
    "durationSec" INTEGER NOT NULL DEFAULT 0,
    "countAdded" INTEGER NOT NULL,
    "modality" "SessionModality" NOT NULL,
    "voiceMatchScore" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RewardEvent" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "kind" "RewardEventKind" NOT NULL,
    "amount" INTEGER NOT NULL,
    "source" TEXT NOT NULL,
    "storeItemId" TEXT,
    "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RewardEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VoiceEnrolment" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "mantraId" TEXT NOT NULL,
    "embeddingUrl" TEXT NOT NULL,
    "sampleCount" INTEGER NOT NULL DEFAULT 0,
    "qualityScore" DOUBLE PRECISION,
    "enrolledAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VoiceEnrolment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "HandwritingSample" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "mantraId" TEXT NOT NULL,
    "mode" "HandwritingMode" NOT NULL,
    "storageUrl" TEXT,
    "isPersonalized" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "HandwritingSample_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Device" (
    "id" TEXT NOT NULL,
    "accountId" TEXT NOT NULL,
    "lastMemberId" TEXT,
    "platform" "DevicePlatform" NOT NULL,
    "appVersion" TEXT,
    "pushToken" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Device_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Invite" (
    "id" TEXT NOT NULL,
    "inviterAccountId" TEXT NOT NULL,
    "inviteeMobile" TEXT,
    "inviteeAccountId" TEXT,
    "status" "InviteStatus" NOT NULL DEFAULT 'pending',
    "rewardGranted" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "acceptedAt" TIMESTAMP(3),

    CONSTRAINT "Invite_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OtpChallenge" (
    "id" TEXT NOT NULL,
    "accountId" TEXT,
    "mobile" TEXT NOT NULL,
    "codeHash" TEXT NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "consumedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OtpChallenge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdminUser" (
    "id" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "email" TEXT,
    "passwordHash" TEXT NOT NULL,
    "role" "AdminRole" NOT NULL DEFAULT 'viewer',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastLoginAt" TIMESTAMP(3),

    CONSTRAINT "AdminUser_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RevokedToken" (
    "jti" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "RevokedToken_pkey" PRIMARY KEY ("jti")
);

-- CreateIndex
CREATE UNIQUE INDEX "Mantra_slug_key" ON "Mantra"("slug");

-- CreateIndex
CREATE INDEX "Mantra_isActive_sortOrder_idx" ON "Mantra"("isActive", "sortOrder");

-- CreateIndex
CREATE UNIQUE INDEX "StoreItem_slug_key" ON "StoreItem"("slug");

-- CreateIndex
CREATE INDEX "StoreItem_isActive_sortOrder_idx" ON "StoreItem"("isActive", "sortOrder");

-- CreateIndex
CREATE UNIQUE INDEX "Account_mobile_key" ON "Account"("mobile");

-- CreateIndex
CREATE UNIQUE INDEX "Account_referralCode_key" ON "Account"("referralCode");

-- CreateIndex
CREATE INDEX "Account_isBanned_idx" ON "Account"("isBanned");

-- CreateIndex
CREATE INDEX "Member_accountId_idx" ON "Member"("accountId");

-- CreateIndex
CREATE INDEX "Member_accountId_isPrimary_idx" ON "Member"("accountId", "isPrimary");

-- CreateIndex
CREATE INDEX "Program_memberId_idx" ON "Program"("memberId");

-- CreateIndex
CREATE INDEX "Program_mantraId_idx" ON "Program"("mantraId");

-- CreateIndex
CREATE INDEX "Session_memberId_startedAt_idx" ON "Session"("memberId", "startedAt");

-- CreateIndex
CREATE INDEX "Session_programId_startedAt_idx" ON "Session"("programId", "startedAt");

-- CreateIndex
CREATE INDEX "RewardEvent_memberId_occurredAt_idx" ON "RewardEvent"("memberId", "occurredAt");

-- CreateIndex
CREATE UNIQUE INDEX "VoiceEnrolment_memberId_mantraId_key" ON "VoiceEnrolment"("memberId", "mantraId");

-- CreateIndex
CREATE INDEX "HandwritingSample_memberId_mantraId_idx" ON "HandwritingSample"("memberId", "mantraId");

-- CreateIndex
CREATE INDEX "Device_accountId_idx" ON "Device"("accountId");

-- CreateIndex
CREATE INDEX "Device_pushToken_idx" ON "Device"("pushToken");

-- CreateIndex
CREATE INDEX "Invite_inviterAccountId_idx" ON "Invite"("inviterAccountId");

-- CreateIndex
CREATE INDEX "Invite_inviteeMobile_idx" ON "Invite"("inviteeMobile");

-- CreateIndex
CREATE INDEX "OtpChallenge_mobile_expiresAt_idx" ON "OtpChallenge"("mobile", "expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "AdminUser_username_key" ON "AdminUser"("username");

-- CreateIndex
CREATE UNIQUE INDEX "AdminUser_email_key" ON "AdminUser"("email");

-- CreateIndex
CREATE INDEX "RevokedToken_expiresAt_idx" ON "RevokedToken"("expiresAt");

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_invitedById_fkey" FOREIGN KEY ("invitedById") REFERENCES "Account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Member" ADD CONSTRAINT "Member_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "Account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Program" ADD CONSTRAINT "Program_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Program" ADD CONSTRAINT "Program_mantraId_fkey" FOREIGN KEY ("mantraId") REFERENCES "Mantra"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_programId_fkey" FOREIGN KEY ("programId") REFERENCES "Program"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RewardEvent" ADD CONSTRAINT "RewardEvent_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RewardEvent" ADD CONSTRAINT "RewardEvent_storeItemId_fkey" FOREIGN KEY ("storeItemId") REFERENCES "StoreItem"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VoiceEnrolment" ADD CONSTRAINT "VoiceEnrolment_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VoiceEnrolment" ADD CONSTRAINT "VoiceEnrolment_mantraId_fkey" FOREIGN KEY ("mantraId") REFERENCES "Mantra"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "HandwritingSample" ADD CONSTRAINT "HandwritingSample_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "Member"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "HandwritingSample" ADD CONSTRAINT "HandwritingSample_mantraId_fkey" FOREIGN KEY ("mantraId") REFERENCES "Mantra"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Device" ADD CONSTRAINT "Device_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "Account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invite" ADD CONSTRAINT "Invite_inviterAccountId_fkey" FOREIGN KEY ("inviterAccountId") REFERENCES "Account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invite" ADD CONSTRAINT "Invite_inviteeAccountId_fkey" FOREIGN KEY ("inviteeAccountId") REFERENCES "Account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OtpChallenge" ADD CONSTRAINT "OtpChallenge_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "Account"("id") ON DELETE CASCADE ON UPDATE CASCADE;
