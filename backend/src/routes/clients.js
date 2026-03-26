const express = require("express");
const multer = require("multer");
const path = require("path");
const { z } = require("zod");
const { prisma } = require("../prisma");
const { requireAuth, requireRole } = require("../middleware/auth");

const clientsRouter = express.Router();

const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, path.join(__dirname, "..", "..", "uploads")),
    filename: (_req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`),
  }),
  limits: { fileSize: 5 * 1024 * 1024 },
});

function nextClientCode(n) { return `ECG-${String(n).padStart(6, "0")}`; }

clientsRouter.get("/", requireAuth, async (req, res) => {
  const { zone, pickupDay, paymentStatus, q } = req.query;
  const where = {};
  if (zone) where.zone = String(zone);
  if (pickupDay) where.pickupDay = String(pickupDay);
  if (paymentStatus) where.paymentStatus = String(paymentStatus);
  if (q) {
    where.OR = [
      { fullName: { contains: String(q), mode: "insensitive" } },
      { phone: { contains: String(q) } },
      { clientCode: { contains: String(q) } },
    ];
  }
  const clients = await prisma.client.findMany({ where, orderBy: { createdAt: "desc" }, take: 500 });
  res.json({ clients });
});

clientsRouter.get("/:id", requireAuth, async (req, res) => {
  const client = await prisma.client.findUnique({
    where: { id: req.params.id },
    include: { payments: { orderBy: { date: "desc" } }, pickups: { orderBy: { date: "desc" } } },
  });
  if (!client) return res.status(404).json({ error: "Not found" });
  res.json({ client });
});

clientsRouter.post("/", requireAuth, requireRole(["ADMIN", "SUPERVISOR", "AGENT"]), upload.single("buildingPhoto"), async (req, res) => {
  const schema = z.object({
    fullName: z.string().min(2),
    phone: z.string().min(8),
    propertyType: z.enum(["SINGLE_HOUSE","COMPOUND_HOUSE","APARTMENT","HOSTEL","SHOP"]),
    zone: z.string().min(2),
    townArea: z.string().optional().nullable(),
    lat: z.coerce.number().optional().nullable(),
    lng: z.coerce.number().optional().nullable(),
    googleMapsLink: z.string().url().optional().nullable(),
    binCount: z.coerce.number().int().min(1).max(50).default(1),
    binId: z.string().optional().nullable(),
    wasteVolume: z.string().optional().nullable(),
    landmark: z.string().optional().nullable(),
    pickupFrequency: z.string().optional().nullable(),
    pickupDay: z.string().optional().nullable(),
    prelaunchStatus: z.enum(["WAITLIST","RESERVED_DEPOSIT","CONFIRMED"]).optional(),
    paymentStatus: z.enum(["UNPAID","DEPOSIT_PAID","PAID","PART_PAID","OVERDUE"]).optional(),
    monthlyFeeGhs: z.coerce.number().int().optional().nullable(),
    notes: z.string().optional().nullable(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const count = await prisma.client.count();
  const clientCode = nextClientCode(count + 1);
  const photoUrl = req.file ? `/uploads/${req.file.filename}` : null;

  const client = await prisma.client.create({
    data: { clientCode, ...parsed.data, buildingPhotoUrl: photoUrl, createdById: req.user.sub },
  });
  res.status(201).json({ client });
});

module.exports = { clientsRouter };
