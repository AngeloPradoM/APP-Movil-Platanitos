-- AlterTable
ALTER TABLE "Address" ADD COLUMN     "phone" VARCHAR(20),
ADD COLUMN     "reference" VARCHAR(180);

-- AlterTable
ALTER TABLE "OrderAddressSnapshot" ADD COLUMN     "phone" VARCHAR(20),
ADD COLUMN     "reference" VARCHAR(180);
