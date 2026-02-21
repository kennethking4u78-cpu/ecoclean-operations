const express = require("express");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const { z } = require("zod");
const { prisma } = require("../prisma");

const authRouter = express.Router();

authRouter.post("/login", async (req, res) => {
  const schema = z.object({ username: z.string().min(2), password: z.string().min(6) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const user = await prisma.user.findUnique({ where: { username: parsed.data.username } });
  if (!user || !user.isActive) return res.status(401).json({ error: "Invalid credentials" });

  const ok = await bcrypt.compare(parsed.data.password, user.password);
  if (!ok) return res.status(401).json({ error: "Invalid credentials" });

  const token = jwt.sign(
    { sub: user.id, role: user.role, username: user.username, name: user.name },
    process.env.JWT_SECRET,
    { expiresIn: "14d" }
  );
  res.json({ token, user: { id: user.id, username: user.username, name: user.name, role: user.role } });
});

module.exports = { authRouter };
