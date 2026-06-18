-- CreateTable
CREATE TABLE "AdminRoleConfig" (
    "role" "AdminRole" NOT NULL,
    "permissions" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AdminRoleConfig_pkey" PRIMARY KEY ("role")
);
