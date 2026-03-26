const express = require("express");
const { z } = require("zod");
const { prisma } = require("../prisma");
const { requireAuth, requireRole } = require("../middleware/auth");

const paymentsRouter = express.Router();

paymentsRouter.post("/", requireAuth, requireRole(["ADMIN","SUPERVISOR"]), async (req, res) => {
  const schema = z.object({
    clientId: z.string().min(5),
    amountGhs: z.coerce.number().int().min(1),
    method: z.enum(["MTN_MOMO","TELECEL_CASH","AIRTELTIGO_MONEY","CASH","BANK_TRANSFER"]),
    txnRef: z.string().optional().nullable(),
    period: z.string().optional().nullable(),
    status: z.string().optional().nullable(),
    notes: z.string().optional().nullable(),
    setClientPaymentStatus: z.enum(["UNPAID","DEPOSIT_PAID","PAID","PART_PAID","OVERDUE"]).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const payment = await prisma.payment.create({ data: {
    clientId: parsed.data.clientId,
    amountGhs: parsed.data.amountGhs,
    method: parsed.data.method,
    txnRef: parsed.data.txnRef || null,
    period: parsed.data.period || null,
    status: parsed.data.status || "Confirmed",
    notes: parsed.data.notes || null,
  }});

  if (parsed.data.setClientPaymentStatus) {
    await prisma.client.update({ where: { id: parsed.data.clientId }, data: { paymentStatus: parsed.data.setClientPaymentStatus }});
  }

  res.status(201).json({ payment });
});

module.exports = { paymentsRouter };
