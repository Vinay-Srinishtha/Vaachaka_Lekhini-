-- =============================================================================
-- USER DATA RESET
-- Clears all user progress, sessions, programs, rewards, and contributions.
-- KEEPS: Account, Member (rows), Device, Invite, TncAcceptance,
--        and ALL admin/catalog data: Mantra, StoreItem, GlobalSadhana
--        (definitions), AdminUser, Quote, AppSetting, RewardRule, Faq, etc.
-- =============================================================================

BEGIN;

-- 1. Contributions to global sadhanas (no FK children)
DELETE FROM "GlobalSadhanaContribution";

-- 2. Enrollments in global sadhanas
DELETE FROM "GlobalSadhanaEnrollment";

-- 3. Reward ledger
DELETE FROM "RewardEvent";

-- 4. Handwriting samples
DELETE FROM "HandwritingSample";

-- 5. Voice enrolments
DELETE FROM "VoiceEnrolment";

-- 6. Practice sessions (also cascade-deleted when Programs are deleted, but explicit is safer)
DELETE FROM "Session";

-- 7. Programs (cascade deletes remaining Sessions)
DELETE FROM "Program";

-- 8. Reset member balance and profile completion bonus flag
UPDATE "Member"
SET
  "rewardPointsBalance" = 0,
  "profileCompletedAt"  = NULL;

-- 9. Reset global sadhana running counts (keep the sadhana definitions and status)
UPDATE "GlobalSadhana"
SET
  "currentCount" = 0,
  "completedAt"  = NULL,
  "status"       = CASE
                     WHEN "status" IN ('completed', 'archived') THEN 'active'::"GlobalSadhanaStatus"
                     ELSE "status"
                   END;

-- 10. Clear expired / consumed OTP challenges (housekeeping)
DELETE FROM "OtpChallenge" WHERE "expiresAt" < NOW();

COMMIT;

-- Sanity check — should all return 0
SELECT COUNT(*) AS remaining_programs     FROM "Program";
SELECT COUNT(*) AS remaining_sessions     FROM "Session";
SELECT COUNT(*) AS remaining_reward_events FROM "RewardEvent";
SELECT COUNT(*) AS remaining_contributions FROM "GlobalSadhanaContribution";
SELECT COUNT(*) AS member_balances_not_zero FROM "Member" WHERE "rewardPointsBalance" <> 0;
