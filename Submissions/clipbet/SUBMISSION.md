# ClipBet — Submission

## Team Name: ClipBet
## Clip Name: ClipBetExperience
## Invocation URL Pattern: clipbet.io/event/:eventId

---

## Problem Statement

**Which touchpoint are you targeting?**

On-Site — the moment when people are physically gathered at an event (sports game, concert, bar trivia, campus hangout) with high social energy and group engagement.

**What friction or missed opportunity are you solving for?**

Prediction markets exist online (Kalshi, Polymarket) but none are hyperlocal or instant. When you're at a bar watching a game, there's no frictionless way to put a friendly bet against the stranger next to you. The friction today:

1. Betting apps require downloads, accounts, and verification
2. Casual event predictions have no infrastructure at all
3. Organizers of local events have no way to drive engagement through friendly stakes

ClipBet removes all friction: scan QR → see the bet → tap Apple Pay → done. No app, no account, no signup.

---

## Proposed Solution

**ClipBet** is a hyperlocal prediction market delivered through an App Clip.

### How it works:

1. **Organizer** creates a prediction market for their event ("Will the Raptors win tonight?")
2. **QR code** is generated and posted at the venue
3. **Anyone** can scan it, see the live odds, and place a bet via Apple Pay
4. **Parimutuel pool model** — all bets go into a shared pot, winners split proportionally
5. **Organizer resolves** the outcome within 24 hours → winners get paid automatically
6. **5% platform fee** is deducted before payout

### What makes this an App Clip, not an app:

- **30-second interaction** — scan, bet, done
- **No account required** — Apple Pay is the only identity
- **Physical trigger** — QR code at the venue
- **Ephemeral** — you bet, you leave, you get notified of the result
- **Geolocked** — only accessible at the venue during the event

### App Clip invocation:

- **QR Code** at venue → opens `clipbet.io/event/:eventId`
- Event details, live pool stats, and outcome odds load instantly
- Full betting flow completes in under 30 seconds

---

## Notification Strategy

Using the **8-hour App Clip notification window**:

| Timing | Notification | Purpose |
|--------|-------------|---------|
| During event | "New bet added: Will the score hit 100?" | Drive engagement |
| At resolution | "Results are in! You won $47.50 🎉" | Deliver outcome |
| Post-event | "New events near you — check them out" | Re-engagement |

---

## Impact Hypothesis

**Revenue model:** 5% platform fee on all bets.

**Market opportunity:**
- Every bar, arena, concert venue, campus event, trivia night becomes a potential ClipBet venue
- Organizers share in the fee (incentivized to promote)
- Zero customer acquisition cost — the QR code IS the distribution

**Why App Clip is the right form factor:**
- Betting is impulse-driven — any friction kills conversion
- Physical presence creates trust and social proof
- 30-second completion means the experience fits between pitches, rounds, or songs
- No app install means anyone in the crowd can participate

---

## Screens Implemented

1. **Landing Screen** — Event name, live status, pool stats (newspaper-style columns), outcome probabilities with 3px progress bars, CTA buttons
2. **Place Bet Screen** — Email input, optional nickname, outcome selection with color-coded Yes/No states, amount picker ($5/$10/$25/Custom), estimated return calculation
3. **Confirm Screen** — Dark modal overlay (#1A1814), full bet receipt, Apple Pay button
4. **Success Screen** — Receipt, updated pool standings with "YOUR PICK" tag, push notification opt-in

---

## Design System

**Editorial-minimal** — print magazine meets quiet SaaS, not fintech or casino.

- **Typography:** Cormorant Garamond (light, headlines) + DM Mono (functional UI)
- **Palette:** Warm cream (#FAF8F5), sage green = Yes (#7BB89A), dusty rose = No (#C97B7B)
- **Layout:** 1px hairline dividers, newspaper-style stat columns, max 2px border-radius
- **Motion:** Fade-up on load, gentle pulse on live status dot only
- **Colour rule:** Every colour carries semantic meaning — green means Yes/winning, rose means No/losing, pink accent for live dots and tags

---

## Test URLs

- `clipbet.io/event/raptors-celtics` → Raptors vs Celtics prediction market
- `clipbet.io/event/42` → Generic event

---

## Technical Notes

- **Payment:** Mocked Apple Pay (Stripe would handle escrow in production)
- **Pool model:** Parimutuel — winners split proportionally, 5% fee deducted
- **Resolution:** Organizer resolves within 24h or everyone gets refunded
- **No external dependencies** — pure SwiftUI, custom design system, mock data
