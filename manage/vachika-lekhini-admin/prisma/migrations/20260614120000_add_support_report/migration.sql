-- CreateTable
CREATE TABLE "SupportReport" (
    "id" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "memberId" TEXT,
    "mobile" TEXT,
    "status" TEXT NOT NULL DEFAULT 'open',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SupportReport_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "SupportReport_status_createdAt_idx" ON "SupportReport"("status", "createdAt");
