require("dotenv").config();
const express = require("express");
const cors = require("cors");
const path = require("path");
const fs = require("fs");

const { authRouter } = require("./routes/auth");
const { clientsRouter } = require("./routes/clients");
const { paymentsRouter } = require("./routes/payments");
const { pickupsRouter } = require("./routes/pickups");
const { routesRouter } = require("./routes/routes");
const { usersRouter } = require("./routes/users");

const app = express();

app.use(cors({ origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(",") : "*", credentials: true }));
app.use(express.json({ limit: "10mb" }));

const uploadsDir = path.join(__dirname, "..", "uploads");
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
app.use("/uploads", express.static(uploadsDir));

app.get("/health", (_req, res) => res.json({ ok: true }));

app.use("/api/auth", authRouter);
app.use("/api/clients", clientsRouter);
app.use("/api/payments", paymentsRouter);
app.use("/api/pickups", pickupsRouter);
app.use("/api/routes", routesRouter);
app.use("/api/users", usersRouter);

const port = process.env.PORT || 4000;
app.listen(port, () => console.log(`EcoClean API running on http://localhost:${port}`));
