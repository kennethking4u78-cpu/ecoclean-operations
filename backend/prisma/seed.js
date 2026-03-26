const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");
const prisma = new PrismaClient();

async function main() {
  const username = "admin";
  const exists = await prisma.user.findUnique({ where: { username } });
  if (exists) return console.log("Admin already exists.");
  const passwordHash = await bcrypt.hash("Admin@1234", 12);
  await prisma.user.create({
    data: { username, name: "EcoClean Admin", role: "ADMIN", password: passwordHash, phone: "0534177839" }
  });
  console.log("Seeded admin: admin / Admin@1234");

  const dUser = await prisma.user.findUnique({ where: { username: 'driver1' } });
  if (!dUser) {
    const driverHash = await bcrypt.hash('Driver@1234', 12);
    await prisma.user.create({ data: { username: 'driver1', name: 'EcoClean Driver', role: 'DRIVER', password: driverHash, phone: '0534177839' }});
    console.log('Seeded driver: driver1 / Driver@1234');
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
