// src/index.ts
// ClipBet Backend - Express Server
// Handles events, bets, organizers, Stripe payments, and webhooks

import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import eventsRouter from "./routes/events";
import betsRouter from "./routes/bets";
import organizersRouter from "./routes/organizers";
import webhooksRouter from "./routes/webhooks";

dotenv.config();

const app = express();
const PORT = parseInt(process.env.PORT || "3001");

// Stripe webhooks need raw body
app.use(
  "/webhooks/stripe",
  express.raw({ type: "application/json" })
);

// Regular JSON parsing for all other routes
app.use(express.json());
app.use(cors());

// ---- Routes ----

app.use("/events", eventsRouter);
app.use("/events", betsRouter);       // /events/:eventId/bets
app.use("/organizers", organizersRouter);
app.use("/organizers", organizersRouter); // /organizers/events/:eventId/resolve|cancel
app.use("/webhooks", webhooksRouter);
app.use("/", webhooksRouter);           // /disputes

// Health check
app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    service: "clipbet-backend",
    version: "1.0.0",
    timestamp: new Date().toISOString(),
  });
});

// API docs
app.get("/", (_req, res) => {
  res.json({
    name: "ClipBet API",
    version: "1.0.0",
    endpoints: {
      events: {
        "GET /events/nearby?lat=&lng=&radius=": "Find nearby events",
        "GET /events/:eventId": "Get event details",
        "POST /events": "Create event",
        "PATCH /events/:eventId/status": "Update event status",
      },
      bets: {
        "POST /events/:eventId/bets": "Place a bet",
        "GET /events/:eventId/bets": "Get bets for event",
      },
      organizers: {
        "POST /organizers/signin": "Sign in with Apple",
        "POST /organizers/:id/tos": "Accept TOS",
        "POST /organizers/:id/stripe-connect": "Start Stripe Connect",
        "POST /organizers/events/:eventId/resolve": "Resolve event",
        "POST /organizers/events/:eventId/cancel": "Cancel event",
      },
      webhooks: {
        "POST /webhooks/stripe": "Stripe webhook handler",
        "POST /disputes": "Submit dispute",
      },
    },
  });
});

app.listen(PORT, () => {
  console.log(`ClipBet backend running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`API docs: http://localhost:${PORT}/`);
});

export default app;
