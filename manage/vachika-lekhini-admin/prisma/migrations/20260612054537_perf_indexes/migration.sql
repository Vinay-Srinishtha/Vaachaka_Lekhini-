-- CreateIndex
CREATE INDEX "AdminUser_isActive_idx" ON "AdminUser"("isActive");

-- CreateIndex
CREATE INDEX "Device_platform_idx" ON "Device"("platform");

-- CreateIndex
CREATE INDEX "Invite_status_idx" ON "Invite"("status");

-- CreateIndex
CREATE INDEX "Member_rewardPointsBalance_idx" ON "Member"("rewardPointsBalance");

-- CreateIndex
CREATE INDEX "Member_lastActiveAt_idx" ON "Member"("lastActiveAt");

-- CreateIndex
CREATE INDEX "Program_completedAt_idx" ON "Program"("completedAt");

-- CreateIndex
CREATE INDEX "Program_memberId_mantraId_idx" ON "Program"("memberId", "mantraId");

-- CreateIndex
CREATE INDEX "RewardEvent_kind_occurredAt_idx" ON "RewardEvent"("kind", "occurredAt");

-- CreateIndex
CREATE INDEX "Session_startedAt_idx" ON "Session"("startedAt");
