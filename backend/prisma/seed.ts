import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const seed = async () => {
  // Ensure there is always at least one administrative user in the system.
  await prisma.user.upsert({
    where: { email: "admin@example.com" },
    update: {},
    create: {
      email: "admin@example.com",
      name: "Admin"
    }
  });
};

seed()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    // Log the error so CI or container logs reveal why seeding failed.
    console.error("Seeding failed", error);
    await prisma.$disconnect();
    process.exit(1);
  });

