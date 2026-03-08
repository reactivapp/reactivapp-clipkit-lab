// src/lib/stripe.ts
// Stripe helpers for ClipBet backend
// Users never see Stripe. Apple Pay is the only surface.

import Stripe from "stripe";
import dotenv from "dotenv";

dotenv.config();

const stripeKey = process.env.STRIPE_SECRET_KEY;
if (!stripeKey) {
  console.warn("STRIPE_SECRET_KEY not set — Stripe disabled");
}

export const stripe = stripeKey
  ? new Stripe(stripeKey, { apiVersion: "2025-02-24.acacia" })
  : (null as unknown as Stripe);

const PLATFORM_FEE_RATE = parseFloat(
  process.env.PLATFORM_FEE_RATE || "0.05"
);

// Create a PaymentIntent for a bet
// Called when user taps Apple Pay in the App Clip
export async function createBetPaymentIntent(
  amount: number,
  eventId: string,
  optionId: string,
  email: string
): Promise<Stripe.PaymentIntent> {
  const amountCents = Math.round(amount * 100);

  const paymentIntent = await stripe.paymentIntents.create({
    amount: amountCents,
    currency: "cad",
    payment_method_types: ["card"],
    metadata: {
      event_id: eventId,
      option_id: optionId,
      email: email,
      type: "clipbet_bet",
    },
    description: `ClipBet: Bet on event ${eventId}`,
  });

  return paymentIntent;
}

// Distribute winnings to all winners via Stripe Connect
export async function distributeWinnings(
  winnerBets: {
    email: string;
    amount: number;
    payoutAmount: number;
    stripePaymentIntentId: string;
  }[],
  platformFee: number
): Promise<{ success: boolean; transfers: string[] }> {
  const transfers: string[] = [];

  for (const bet of winnerBets) {
    try {
      // In production with Stripe Connect, you would transfer to
      // connected accounts. For now we record the payout.
      const payoutCents = Math.round(bet.payoutAmount * 100);

      const transfer = await stripe.transfers.create({
        amount: payoutCents,
        currency: "cad",
        destination: "acct_placeholder",
        metadata: {
          type: "clipbet_payout",
          original_payment_intent: bet.stripePaymentIntentId,
          email: bet.email,
        },
      });

      transfers.push(transfer.id);
    } catch (error) {
      console.error(`Failed to transfer to ${bet.email}:`, error);
    }
  }

  return { success: transfers.length > 0, transfers };
}

// Refund all bets for a cancelled event
export async function refundAllBets(
  paymentIntentIds: string[]
): Promise<{ success: boolean; refunds: string[] }> {
  const refunds: string[] = [];

  for (const piId of paymentIntentIds) {
    try {
      const refund = await stripe.refunds.create({
        payment_intent: piId,
      });
      refunds.push(refund.id);
    } catch (error) {
      console.error(`Failed to refund ${piId}:`, error);
    }
  }

  return { success: refunds.length === paymentIntentIds.length, refunds };
}

// Create a Stripe Connect onboarding link for organizers
export async function createConnectOnboardingLink(
  accountId: string,
  returnUrl: string
): Promise<string> {
  const link = await stripe.accountLinks.create({
    account: accountId,
    refresh_url: returnUrl,
    return_url: returnUrl,
    type: "account_onboarding",
  });

  return link.url;
}

// Create a new Stripe Connect account for an organizer
export async function createConnectAccount(
  email: string
): Promise<string> {
  const account = await stripe.accounts.create({
    type: "express",
    email: email,
    capabilities: {
      transfers: { requested: true },
    },
    metadata: {
      type: "clipbet_organizer",
    },
  });

  return account.id;
}
