const express = require("express");
const { prisma } = require("../prisma");
const { requireAuth, requireRole } = require("../middleware/auth");

const usersRouter = express.Router();

// List users (optionally filter by role), for admin dashboard dropdowns
usersRouter.get("/", requireAuth, requireRole(["ADMIN", "SUPERVISOR"]), async (req, res) => {
  const { role } = req.query;
  const where = { isActive: true };
  if (role) where.role = String(role);

  const users = await prisma.user.findMany({
    where,
    orderBy: { name: "asc" },
    select: { id: true, username: true, name: true, phone: true, role: true, isActive: true }
  });

  res.json({ users });
});

module.exports = { usersRouter };
