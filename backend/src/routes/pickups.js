const express = require("express");
const { z } = require("zod");
const { prisma } = require("../prisma");
const { requireAuth, requireRole } = require("../middleware/auth");

const pickupsRouter = express.Router();

pickupsRouter.post("/", requireAuth, requireRole(["ADMIN","SUPERVISOR","DRIVER"]), async (req, res) => {
  const schema = z.object({ clientId: z.string().min(5), status: z.enum(["COLLECTED","MISSED","NO_ACCESS","NOT_PAID"]), notes: z.string().optional().nullable() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
  const pickup = await prisma.pickup.create({ data: { clientId: parsed.data.clientId, status: parsed.data.status, notes: parsed.data.notes || null }});
  res.status(201).json({ pickup });
});

module.exports = { pickupsRouter };
