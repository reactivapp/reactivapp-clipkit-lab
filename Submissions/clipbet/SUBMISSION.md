# ClipBet Submission

## Team Name: ClipBet
## Clip Name: ClipBetExperience
## Invocation URL Pattern: clipbet.io/event/:eventId

---

## Problem Statement

**Touchpoint:** On-Site. The moment when people are physically
gathered at an event (sports game, concert, bar trivia, campus
hangout) with high social energy.

**Friction being solved:** Prediction markets exist online (Kalshi,
Polymarket) but none are hyperlocal or instant. When you are at
a bar watching a game, there is no way to place a friendly bet
against the stranger next to you without downloading an app,
creating an account, or going through verification.

ClipBet removes all friction: scan QR, see the bet, tap
Apple Pay, done. No app, no account, no signup.

---

## Solution

**ClipBet** is a hyperlocal prediction market delivered via
App Clip.

### How it works:
1. **Organizer** creates a prediction market for their event
2. **QR code** is generated and posted at the venue
3. **Anyone** scans, sees live odds, places a bet via Apple Pay
4. **Parimutuel pool model**: all bets go in a shared pot,
   winners split proportionally
5. **Organizer resolves** within 24h, winners get paid
6. **5% platform fee** deducted before payout

### Why App Clip, not an app:
- 30 second interaction: scan, bet, done
- No account required: Apple Pay is the only identity
- Physical trigger: QR code at the venue
- Ephemeral: bet, leave, get notified of result
- Geolocked: only accessible at the venue

---

## File Structure

```
Submissions/clipbet/
  ClipBetExperience.swift    Main entry point, screen flow
  ClipBetModels.swift        Data models (Event, Bet, Organizer)
  ClipBetMockData.swift      Mock data for demo
  ClipBetPayment.swift       Payment manager (Apple Pay + Stripe)
  ClipBetComponents.swift    Reusable UI components
  SUBMISSION.md              This file
```

---

## Screens Implemented

1. **Landing** Event name, live status (pulsing dot), pool stats
   in newspaper-style columns, outcome probabilities with 3px
   progress bars, primary CTA

2. **Place Bet** Email input, optional nickname, outcome selection
   with color-coded Yes/No states, amount picker ($5/$10/$25 or
   custom), live estimated return calculation

3. **Confirm** Dark modal overlay (#1A1814), full bet receipt,
   Apple Pay button with card fallback, real-time payment status

4. **Success** Receipt with transaction ID, updated pool standings
   with YOUR PICK tag, push notification opt-in, escrow info

---

## Payment Architecture

- **User facing:** Apple Pay only (PKPaymentRequest in production)
- **Backend:** Stripe processes payment invisibly
- **Escrow:** Funds held on platform Stripe account until resolution
- **Card fallback:** Small "or pay with card" link below Apple Pay
  (opens Stripe Payment Sheet, no Stripe branding)
- **Payouts:** Stripe Connect transfers to winners
- **Refunds:** Automatic if organizer fails to resolve in 24h
- **Fee:** 5% platform fee deducted before winner distribution

For hackathon demo: fully mocked with realistic state machine
(idle, processing, success, failed, refunded)

---

## Data Model

Full backend schema implemented in ClipBetModels.swift:

- **PredictionEvent:** id, name, status, outcomes, location
  (lat/lng), organizer, betting window, lifecycle timestamps
- **BetOutcome:** id, name, totalAmount, betCount, percentage
- **UserBet:** id, amount, status (pending/confirmed/won/lost/
  refunded), payout tracking, Stripe PaymentIntent reference
- **EventOrganizer:** id, Apple user ID, Stripe Connect ID,
  verification status, rating
- **BetDispute:** id, reason, status (open/resolved/rejected)

---

## Design System

**Editorial-minimal.** Print magazine meets quiet SaaS.

- **Typography:** Cormorant Garamond (light, headlines) +
  DM Mono (functional UI, all caps, letter-spaced)
- **Palette:** Warm cream (#FAF8F5), sage green for Yes (#7BB89A),
  dusty rose for No (#C97B7B), accent pink (#E8A0A0)
- **Layout:** 1px hairline dividers, newspaper-style stat columns,
  max 2px border-radius
- **Motion:** Fade-up on load, gentle pulse on live status dot
- **Dark mode:** Confirm screen uses dark overlay (#1A1814)

---

## Notification Strategy

Using the 8-hour App Clip notification window:

| Timing | Notification |
|--------|-------------|
| During event | Pool update: "$2,140 total" |
| At resolution | "Results are in! You won $47.50" |
| Post-event | "Your refund has been processed" |

---

## Test URL

clipbet.io/event/42

---

## Technical Notes

- Pure SwiftUI, no external dependencies
- Mock Apple Pay (Stripe in production)
- Parimutuel pool: winners split proportionally, 5% fee
  deducted
- 24h resolution window, auto-refund if unresolved
- All components extracted and reusable
