-- Redesign AdminRole from a linear hierarchy (super_admin/editor/viewer) to
-- scoped roles (super_admin/main_admin/assets_admin/marketplace_admin).
--
-- Existing rows are remapped: super_admin → super_admin, everything else
-- (editor, viewer) → main_admin (full access except the audit/support areas).

-- 1. Create the new enum type.
CREATE TYPE "AdminRole_new" AS ENUM ('super_admin', 'main_admin', 'assets_admin', 'marketplace_admin');

-- 2. Drop the column default so the type change isn't blocked by it.
ALTER TABLE "AdminUser" ALTER COLUMN "role" DROP DEFAULT;

-- 3. Convert the column, mapping old values to new ones.
ALTER TABLE "AdminUser"
  ALTER COLUMN "role" TYPE "AdminRole_new"
  USING (
    CASE "role"::text
      WHEN 'super_admin' THEN 'super_admin'
      ELSE 'main_admin'
    END
  )::"AdminRole_new";

-- 4. Swap the enum types.
DROP TYPE "AdminRole";
ALTER TYPE "AdminRole_new" RENAME TO "AdminRole";

-- 5. Restore a default for new rows.
ALTER TABLE "AdminUser" ALTER COLUMN "role" SET DEFAULT 'main_admin';
