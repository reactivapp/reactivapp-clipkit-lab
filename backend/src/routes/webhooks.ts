// src/routes/webhooks.ts
// Stripe webhook handlers for payment events

import { Router, Request, Response } from "express";
import { stripe } from "../lib/stripe";
import { supabase } from "../lib/supabase";
import Stripe from "stripe";

const router = Router();

const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

// POST /webhooks/stripe
// Handles Stripe webhook events
router.post(
  "/stripe",
  async (req: Request, res: Response) => {
    let event: Stripe.Event;

    try {
      if (webhookSecret) {
        const signature = req.headers["stripe-signature"] as string;
        event = stripe.webhooks.constructEvent(
          req.body,
          signature,
          webhookSecret
        );
      } else {
        // Development: parse without verification
        event = req.body as Stripe.Event;
      }
    } catch (err) {
      console.error("Webhook signature verification failed");
      res.status(400).json({ error: "Invalid signature" });
      return;
    }

    switch (event.type) {
      // Payment confirmed - bet is live
      case "payment_intent.succeeded": {
        const pi = event.data.object as Stripe.PaymentIntent;
        const eventId = pi.metadata.event_id;
        const optionId = pi.metadata.option_id;

        if (pi.metadata.type !== "clipbet_bet") break;

        // Update bet status to confirmed
        await supabase
          .from("bets")
          .update({ status: "confirmed" })
          .eq("stripe_payment_intent_id", pi.id);

        // Update option totals
        const { data: bet } = await supabase
          .from("bets")
          .select("amount")
          .eq("stripe_payment_intent_id", pi.id)
          .single();

        if (bet && optionId) {
          const amount = parseFloat(bet.amount);

          // Increment option totals
          const { data: option } = await supabase
            .from("options")
            .select("total_bets, total_amount")
            .eq("id", optionId)
            .single();

          if (option) {
            await supabase
              .from("options")
              .update({
                total_bets: (option.total_bets || 0) + 1,
                total_amount:
                  parseFloat(option.total_amount || "0") + amount,
              })
              .eq("id", optionId);
          }
        }

        console.log(`Bet confirmed: ${pi.id} for event ${eventId}`);
        break;
      }

      // Payment failed
      case "payment_intent.payment_failed": {
        const pi = event.data.object as Stripe.PaymentIntent;

        if (pi.metadata.type !== "clipbet_bet") break;

        await supabase
          .from("bets")
          .update({ status: "pending" })
          .eq("stripe_payment_intent_id", pi.id);

        console.log(`Payment failed: ${pi.id}`);
        break;
      }

      // Transfer to winner completed
      case "transfer.created": {
        const transfer = event.data.object as Stripe.Transfer;

        if (transfer.metadata.type !== "clipbet_payout") break;

        console.log(
          `Payout transfer created: ${transfer.id} to ${transfer.metadata.email}`
        );
        break;
      }

      default: {
        // Handle transfer.failed (not in SDK type definitions)
        const eventType = event.type as string;
        if (eventType === "transfer.failed") {
          const transfer = event.data.object as Stripe.Transfer;
          if (transfer.metadata?.type === "clipbet_payout") {
            const piId = transfer.metadata.original_payment_intent;
            if (piId) {
              await supabase
                .from("bets")
                .update({ payout_status: "failed" })
                .eq("stripe_payment_intent_id", piId);
            }
            console.error(
              `Payout transfer failed: ${transfer.id} for ${transfer.metadata.email}`
            );
          }
        }
        break;
      }
    }

    res.json({ received: true });
  }
);

// POST /disputes
// Submit a dispute for an event resolution
router.post("/disputes", async (req: Request, res: Response) => {
  try {
    const { event_id, bettor_email, reason } = req.body;

    if (!event_id || !bettor_email || !reason) {
      res.status(400).json({
        error: "event_id, bettor_email, and reason are required",
      });
      return;
    }

    const { data, error } = await supabase
      .from("disputes")
      .insert({
        event_id,
        bettor_email,
        reason,
      })
      .select()
      .single();

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.status(201).json({ dispute: data });
  } catch (err) {
    res.status(500).json({ error: "Failed to submit dispute" });
  }
});

export default router;
