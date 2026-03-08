// src/routes/bets.ts
// Bet routes

import { Router, Request, Response } from "express";
import { supabase } from "../lib/supabase";
import { createBetPaymentIntent } from "../lib/stripe";
import { v4 as uuidv4 } from "uuid";

const router = Router();

// POST /events/:eventId/bets
// Place bet
router.post("/:eventId/bets", async (req: Request, res: Response) => {
  try {
    const eventId = req.params.eventId as string;
    const { option_id, amount, nickname, email } = req.body;

    if (!option_id || !amount || !email) {
      res.status(400).json({
        error: "option_id, amount, and email are required",
      });
      return;
    }

    // Check event
    const { data: event, error: eventError } = await supabase
      .from("events")
      .select("*")
      .eq("id", eventId)
      .single();

    if (eventError || !event) {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    if (event.status !== "live") {
      res.status(400).json({ error: "This event is not accepting bets" });
      return;
    }

    if (amount < event.minimum_bet) {
      res.status(400).json({
        error: `Minimum bet is $${event.minimum_bet}`,
      });
      return;
    }

    // Check option
    const { data: option, error: optError } = await supabase
      .from("options")
      .select("*")
      .eq("id", option_id)
      .eq("event_id", eventId)
      .single();

    if (optError || !option) {
      res.status(400).json({ error: "Invalid option for this event" });
      return;
    }

    // Setup payment
    const paymentIntent = await createBetPaymentIntent(
      amount,
      eventId,
      option_id,
      email
    );

    // Save bet
    const betId = uuidv4();
    const { error: betError } = await supabase.from("bets").insert({
      id: betId,
      event_id: eventId,
      option_id,
      amount,
      nickname: nickname || "Anonymous",
      email,
      stripe_payment_intent_id: paymentIntent.id,
      status: "pending",
    });

    if (betError) {
      res.status(500).json({ error: betError.message });
      return;
    }

    res.status(201).json({
      bet_id: betId,
      client_secret: paymentIntent.client_secret,
      payment_intent_id: paymentIntent.id,
    });
  } catch (err) {
    res.status(500).json({ error: "Failed to place bet" });
  }
});

// GET /events/:eventId/bets
// Get bets
router.get("/:eventId/bets", async (req: Request, res: Response) => {
  try {
    const { data: bets, error } = await supabase
      .from("bets")
      .select("*, options(name)")
      .eq("event_id", req.params.eventId)
      .order("created_at", { ascending: false });

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.json({ bets: bets || [] });
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch bets" });
  }
});

export default router;
