const express = require("express");
const { z } = require("zod");
const { prisma } = require("../prisma");
const { requireAuth, requireRole } = require("../middleware/auth");

const routesRouter = express.Router();

const dayNames = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
function todayName() {
  return dayNames[new Date().getDay()];
}

// Create route
routesRouter.post("/", requireAuth, requireRole(["ADMIN","SUPERVISOR"]), async (req, res) => {
  const schema = z.object({
    code: z.string().min(2),
    name: z.string().optional().nullable(),
    pickupDay: z.string().min(3),
    zoneSummary: z.string().optional().nullable(),
    assignedDriverId: z.string().optional().nullable(),
    notes: z.string().optional().nullable(),
    stopClientIds: z.array(z.string()).optional(), // ordered list of client IDs
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const route = await prisma.route.create({
    data: {
      code: parsed.data.code,
      name: parsed.data.name || null,
      pickupDay: parsed.data.pickupDay,
      zoneSummary: parsed.data.zoneSummary || null,
      assignedDriverId: parsed.data.assignedDriverId || null,
      notes: parsed.data.notes || null,
      createdById: req.user.sub,
    }
  });

  if (parsed.data.stopClientIds && parsed.data.stopClientIds.length > 0) {
    await prisma.routeStop.createMany({
      data: parsed.data.stopClientIds.map((cid, idx) => ({ routeId: route.id, clientId: cid, stopOrder: idx + 1 }))
    });
  }

  res.status(201).json({ route });
});

// List routes
routesRouter.get("/", requireAuth, requireRole(["ADMIN","SUPERVISOR","DRIVER"]), async (req, res) => {
  const routes = await prisma.route.findMany({
    orderBy: { createdAt: "desc" },
    include: {
      assignedDriver: { select: { id: true, name: true, phone: true } },
      stops: { orderBy: { stopOrder: "asc" }, include: { client: true } }
    }
  });
  res.json({ routes });
});

// Update route (metadata + driver assignment)
routesRouter.put("/:id", requireAuth, requireRole(["ADMIN","SUPERVISOR"]), async (req, res) => {
  const schema = z.object({
    code: z.string().min(2).optional(),
    name: z.string().optional().nullable(),
    pickupDay: z.string().optional(),
    zoneSummary: z.string().optional().nullable(),
    assignedDriverId: z.string().optional().nullable(),
    isActive: z.boolean().optional(),
    notes: z.string().optional().nullable(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const route = await prisma.route.update({ where: { id: req.params.id }, data: parsed.data });
  res.json({ route });
});

// Replace stops list (ordered)
routesRouter.put("/:id/stops", requireAuth, requireRole(["ADMIN","SUPERVISOR"]), async (req, res) => {
  const schema = z.object({ stopClientIds: z.array(z.string()).min(1) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

  const routeId = req.params.id;

  await prisma.routeStop.deleteMany({ where: { routeId } });
  await prisma.routeStop.createMany({
    data: parsed.data.stopClientIds.map((cid, idx) => ({ routeId, clientId: cid, stopOrder: idx + 1 }))
  });

  res.json({ ok: true });
});

// DRIVER: get today's assigned route + checklist
routesRouter.get("/today/assigned", requireAuth, requireRole(["DRIVER"]), async (req, res) => {
  const day = todayName();
  const route = await prisma.route.findFirst({
    where: { isActive: true, pickupDay: day, assignedDriverId: req.user.sub },
    include: { stops: { orderBy: { stopOrder: "asc" }, include: { client: true } } }
  });
  if (!route) return res.json({ route: null, day });

  // Fetch today's pickups for stops
  const start = new Date(); start.setHours(0,0,0,0);
  const end = new Date(); end.setHours(23,59,59,999);

  const pickups = await prisma.pickup.findMany({
    where: { clientId: { in: route.stops.map(s => s.clientId) }, date: { gte: start, lte: end } }
  });
  const statusByClient = new Map(pickups.map(p => [p.clientId, p.status]));

  const checklist = route.stops.map(s => ({
    stopOrder: s.stopOrder,
    clientId: s.clientId,
    clientCode: s.client.clientCode,
    name: s.client.fullName,
    phone: s.client.phone,
    zone: s.client.zone,
    mapsLink: s.client.googleMapsLink,
    statusToday: statusByClient.get(s.clientId) || "PENDING"
  }));

  res.json({ day, route: { id: route.id, code: route.code, name: route.name, pickupDay: route.pickupDay }, checklist });
});

module.exports = { routesRouter };
