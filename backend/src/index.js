require("dotenv").config();
const express = require("express");
const cors = require("cors");
const path = require("path");
const fs = require("fs");
const axios = require("axios");
const { authRouter } = require("./routes/auth");
const { clientsRouter } = require("./routes/clients");
const { paymentsRouter } = require("./routes/payments");
const { pickupsRouter } = require("./routes/pickups");
const { routesRouter } = require("./routes/routes");
const { usersRouter } = require("./routes/users");

const app = express();

const allowedOrigins = (process.env.CORS_ORIGIN || "")
  .split(",")
  .map(o => o.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow server-to-server calls / Postman (no origin)
      if (!origin) return callback(null, true);

      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      return callback(new Error(`CORS blocked: ${origin}`));
    },
    credentials: true,
  })
);
app.options("*", cors({
  origin: allowedOrigins,
  credentials: true
}));
app.use(express.json({ limit: "10mb" }));

const uploadsDir = path.join(__dirname, "..", "uploads");
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
app.use("/uploads", express.static(uploadsDir));

app.get("/health", (_req, res) => res.json({ ok: true }));
app.get("/api/locations", (_req, res) => {
  res.json([
    { id: 1, location: "Town Center", bin_status: "half-full" },
    { id: 2, location: "Market Street", bin_status: "full" }
  ]);
});
app.get("/", (_req, res) => res.send("EcoClean API is running ✅"));
app.get("/api", (_req, res) => res.json({ ok: true, message: "EcoClean API base ✅" }));
/**
 * Hubtel Direct Receive Money (MoMo prompt) test route
 * - Uses Axios with HTTP Basic Auth
 * - Reads raw text response and safely parses JSON (prevents "Unexpected end of JSON input")
 * - Accepts query params so you can test from browser/curl:
 *     /hubtel-test?msisdn=23324XXXXXXX&channel=mtn-gh&amount=1&callbackUrl=https%3A%2F%2Fexample.com%2Fcb
 */
app.get("/hubtel-test", async (req, res) => {


  const baseUrl = process.env.HUBTEL_BASE_URL || "https://rmp.hubtel.com";
  const accountNumber = process.env.HUBTEL_MERCHANT_ACCOUNT_NUMBER;
  const clientId = process.env.HUBTEL_CLIENT_ID;
  const clientSecret = process.env.HUBTEL_CLIENT_SECRET;

  // Basic validation before we even call Hubtel
  if (!accountNumber || !clientId || !clientSecret) {
    return res.status(500).json({
      ok: false,
      error: "Missing HUBTEL env vars",
      required: [
        "HUBTEL_BASE_URL (recommend https://rmp.hubtel.com for receive-money tests)",
        "HUBTEL_MERCHANT_ACCOUNT_NUMBER",
        "HUBTEL_CLIENT_ID",
        "HUBTEL_CLIENT_SECRET",
      ],
    });
  }

  // Query params (so you can test in browser)
  const msisdn = String(req.query.msisdn || "233XXXXXXXXX"); // replace for real test
  const channel = String(req.query.channel || "mtn-gh"); // mtn-gh | vodafone-gh | tigo-gh
  const amount = Number(req.query.amount || 1); // small amount for testing
  const callbackUrl = String(req.query.callbackUrl || "https://example.com/hubtel-callback");
  const clientReference = String(req.query.clientReference || `ecoclean-test-${Date.now()}`);

const url = `${baseUrl}/v1/merchantaccount/merchants/${accountNumber}/receive/mobilemoney`;
  // Safe test payload (matches Hubtel "Receive Money Request" structure)
  const payload = {
    CustomerName: "EcoClean Test",
    CustomerMsisdn: msisdn,
    Channel: channel,
    Amount: amount,
    PrimaryCallbackUrl: callbackUrl,
    Description: "EcoClean Hubtel receive-money test",
    ClientReference: clientReference,
    // Optional fields if you want:
    // CustomerEmail: "test@example.com",
  };

  try {
    const hubtelResp = await axios.post(url, payload, {
      auth: { username: clientId, password: clientSecret }, // HTTP Basic Auth
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      timeout: 20000,
      responseType: "text", // IMPORTANT: keep raw text so we control JSON parsing
      transformResponse: [(data) => data], // disable axios' automatic JSON parse
      validateStatus: () => true, // we handle non-2xx explicitly
    });

    const status = hubtelResp.status;
    const headers = hubtelResp.headers || {};
    const contentType = headers["content-type"] || "";
    const rawBody = hubtelResp.data; // string

    // Log minimal diagnostics to terminal (no secrets)
    console.log("[hubtel-test] HTTP", status, "Content-Type:", contentType);

    // Safe parse: only parse JSON if body is non-empty and looks like JSON
    let parsed = rawBody;
    if (typeof rawBody === "string") {
      const trimmed = rawBody.trim();
      if (trimmed.length === 0) parsed = null;
      else if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
        try {
          parsed = JSON.parse(trimmed);
        } catch (e) {
          parsed = { parseError: e.message, raw: trimmed };
        }
      }
    }

    // Respond to browser/curl with BOTH debug + Hubtel payload
    return res.status(200).json({
      ok: status >= 200 && status < 300,
      request: {
        url,
        payload: {
          ...payload,
          // never echo real phone numbers in logs if you don’t want to:
          // CustomerMsisdn: "***redacted***",
        },
      },
      hubtel: {
        httpStatus: status,
        contentType,
        headers: {
          // keep a few useful headers only (avoid dumping everything)
          date: headers["date"],
          server: headers["server"],
          "content-type": headers["content-type"],
          "content-length": headers["content-length"],
        },
        data: parsed, // parsed JSON object OR null OR raw string OR parseError object
        raw: typeof rawBody === "string" ? rawBody : undefined,
      },
    });
  } catch (err) {
    // Axios network/timeout errors land here
    const httpStatus = err.response?.status;
    const contentType = err.response?.headers?.["content-type"];
    const raw = err.response?.data;

    console.error("[hubtel-test] ERROR:", err.message, {
      httpStatus,
      contentType,
    });

    return res.status(500).json({
      ok: false,
      error: err.message,
      hubtel: { httpStatus, contentType, raw },
    });
  }
});

app.use("/api/auth", authRouter);
app.use("/api/clients", clientsRouter);
app.use("/api/payments", paymentsRouter);
app.use("/api/pickups", pickupsRouter);
app.use("/api/routes", routesRouter);
app.use("/api/users", usersRouter);

const port = process.env.PORT || 4000;
app.listen(port, () => console.log(`EcoClean API running on http://localhost:${port}`));

