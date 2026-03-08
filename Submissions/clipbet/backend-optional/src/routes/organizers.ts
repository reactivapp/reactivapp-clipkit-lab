// src/routes/organizers.ts
// Organizer routes

import { Router, Request, Response } from "express";
import { supabase } from "../lib/supabase";
import {
  createConnectAccount,
  createConnectOnboardingLink,
  distributeWinnings,
  refundAllBets,
} from "../lib/stripe";
import { v4 as uuidv4 } from "uuid";

const PLATFORM_FEE_RATE = parseFloat(
  process.env.PLATFORM_FEE_RATE || "0.05"
);

const router = Router();

// POST /organizers/signin
// Sign in with Apple
router.post("/signin", async (req: Request, res: Response) => {
  try {
    const { apple_user_id } = req.body;

    if (!apple_user_id) {
      res.status(400).json({ error: "apple_user_id is required" });
      return;
    }

    // Get organizer
    const { data: existing } = await supabase
      .from("organizers")
      .select("*")
      .eq("apple_user_id", apple_user_id)
      .single();

    if (existing) {
      res.json({
        organizer: existing,
        is_new: false,
        needs_tos: !existing.tos_agreed_at,
        needs_stripe: !existing.stripe_connect_id,
      });
      return;
    }

    // Create organizer
    const orgId = uuidv4();
    const { data: organizer, error } = await supabase
      .from("organizers")
      .insert({
        id: orgId,
        apple_user_id,
      })
      .select()
      .single();

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.status(201).json({
      organizer,
      is_new: true,
      needs_tos: true,
      needs_stripe: true,
    });
  } catch (err) {
    res.status(500).json({ error: "Failed to sign in" });
  }
});

// POST /organizers/:id/tos
// Accept TOS
router.post("/:id/tos", async (req: Request, res: Response) => {
  try {
    const { data, error } = await supabase
      .from("organizers")
      .update({ tos_agreed_at: new Date().toISOString() })
      .eq("id", req.params.id)
      .select()
      .single();

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.json({ organizer: data });
  } catch (err) {
    res.status(500).json({ error: "Failed to accept TOS" });
  }
});

// POST /organizers/:id/stripe-connect
// Start Connect onboarding
router.post("/:id/stripe-connect", async (req: Request, res: Response) => {
  try {
    const { email, return_url } = req.body;

    // Create Connect account
    const accountId = await createConnectAccount(email || "");

    // Save id
    await supabase
      .from("organizers")
      .update({
        stripe_connect_id: accountId,
        verified_at: new Date().toISOString(),
      })
      .eq("id", req.params.id);

    // Get link
    const onboardingUrl = await createConnectOnboardingLink(
      accountId,
      return_url || `${process.env.CLIPBET_BASE_URL}/create`
    );

    res.json({
      stripe_connect_id: accountId,
      onboarding_url: onboardingUrl,
    });
  } catch (err) {
    res.status(500).json({ error: "Failed to setup Stripe Connect" });
  }
});

// POST /events/:eventId/resolve
// Resolve event
router.post(
  "/events/:eventId/resolve",
  async (req: Request, res: Response) => {
    try {
      const { winning_option_id, organizer_id } = req.body;
      const { eventId } = req.params;

      if (!winning_option_id || !organizer_id) {
        res.status(400).json({
          error: "winning_option_id and organizer_id required",
        });
        return;
      }

      // Check event
      const { data: event, error: eventError } = await supabase
        .from("events")
        .select("*")
        .eq("id", eventId)
        .eq("organizer_id", organizer_id)
        .single();

      if (eventError || !event) {
        res.status(404).json({ error: "Event not found" });
        return;
      }

      if (event.status === "resolved" || event.status === "cancelled") {
        res.status(400).json({ error: "Event already finalized" });
        return;
      }

      // Find payouts
      const totalPool = parseFloat(event.total_pool) || 0;
      const platformFee = totalPool * PLATFORM_FEE_RATE;
      const winnerPool = totalPool - platformFee;

      // Get option totals
      const { data: winningOption } = await supabase
        .from("options")
        .select("*")
        .eq("id", winning_option_id)
        .single();

      const winnerTotalBet = parseFloat(winningOption?.total_amount || "0");

      // Get all bets
      const { data: allBets } = await supabase
        .from("bets")
        .select("*")
        .eq("event_id", eventId)
        .eq("status", "confirmed");

      // Calculate individual payouts
      const winnerBets = (allBets || []).filter(
        (b) => b.option_id === winning_option_id
      );
      const loserBets = (allBets || []).filter(
        (b) => b.option_id !== winning_option_id
      );

      // Update winner bets
      for (const bet of winnerBets) {
        const share = (parseFloat(bet.amount) / winnerTotalBet) * winnerPool;
        await supabase
          .from("bets")
          .update({
            status: "won",
            payout_amount: share,
            payout_status: "processing",
          })
          .eq("id", bet.id);
      }

      // Update loser bets
      for (const bet of loserBets) {
        await supabase
          .from("bets")
          .update({ status: "lost", payout_amount: 0 })
          .eq("id", bet.id);
      }

      // Update event
      await supabase
        .from("events")
        .update({
          status: "resolved",
          winning_option_id,
          resolved_at: new Date().toISOString(),
          platform_fee: platformFee,
          winner_pool: winnerPool,
        })
        .eq("id", eventId);

      // Pay out
      const transferData = winnerBets.map((b) => ({
        email: b.email,
        amount: parseFloat(b.amount),
        payoutAmount:
          (parseFloat(b.amount) / winnerTotalBet) * winnerPool,
        stripePaymentIntentId: b.stripe_payment_intent_id,
      }));

      const result = await distributeWinnings(transferData, platformFee);

      // Update status
      if (result.success) {
        for (const bet of winnerBets) {
          await supabase
            .from("bets")
            .update({ payout_status: "completed" })
            .eq("id", bet.id);
        }
      }

      res.json({
        status: "resolved",
        total_pool: totalPool,
        platform_fee: platformFee,
        winner_pool: winnerPool,
        winners: winnerBets.length,
        losers: loserBets.length,
      });
    } catch (err) {
      res.status(500).json({ error: "Failed to resolve event" });
    }
  }
);

// POST /events/:eventId/cancel
// Cancel event
router.post(
  "/events/:eventId/cancel",
  async (req: Request, res: Response) => {
    try {
      const { organizer_id } = req.body;
      const { eventId } = req.params;

      // Check event
      const { data: event } = await supabase
        .from("events")
        .select("*")
        .eq("id", eventId)
        .eq("organizer_id", organizer_id)
        .single();

      if (!event) {
        res.status(404).json({ error: "Event not found" });
        return;
      }

      if (event.status === "resolved" || event.status === "cancelled") {
        res.status(400).json({ error: "Event already finalized" });
        return;
      }

      // Get all confirmed bets
      const { data: bets } = await supabase
        .from("bets")
        .select("*")
        .eq("event_id", eventId)
        .eq("status", "confirmed");

      // Refund on Stripe
      const paymentIds = (bets || [])
        .map((b) => b.stripe_payment_intent_id)
        .filter(Boolean);

      const result = await refundAllBets(paymentIds);

      // Update all bets to refunded
      await supabase
        .from("bets")
        .update({ status: "refunded", payout_status: "completed" })
        .eq("event_id", eventId);

      // Update event
      await supabase
        .from("events")
        .update({
          status: "cancelled",
          closed_at: new Date().toISOString(),
        })
        .eq("id", eventId);

      res.json({
        status: "cancelled",
        refunded_bets: (bets || []).length,
        refunds: result.refunds,
      });
    } catch (err) {
      res.status(500).json({ error: "Failed to cancel event" });
    }
  }
);

export default router;
