# ClipBet Deployment Guide

Deploy ClipBet backend for free using Railway (backend) +
Supabase (database) + Stripe (payments).

---

## 1. Supabase Setup (Free Tier)

1. Go to [supabase.com](https://supabase.com) and create account
2. Create a new project (choose a region close to your users)
3. Once the project is ready, go to **SQL Editor**
4. Paste the contents of `supabase/schema.sql` and run it
5. Go to **Settings > API** and copy:
   - Project URL -> `SUPABASE_URL`
   - `anon` public key -> `SUPABASE_ANON_KEY`
   - `service_role` secret key -> `SUPABASE_SERVICE_ROLE_KEY`

Supabase free tier includes:
- 500 MB database
- 50,000 monthly active users
- 2 GB bandwidth
- Unlimited API requests

---

## 2. Stripe Setup

1. Go to [dashboard.stripe.com](https://dashboard.stripe.com)
   and create account
2. Stay in **Test Mode** for development
3. Go to **Developers > API Keys** and copy:
   - Publishable key -> `STRIPE_PUBLISHABLE_KEY`
   - Secret key -> `STRIPE_SECRET_KEY`

### Stripe Connect (for organizer payouts)

4. Go to **Settings > Connect Settings**
5. Enable **Express** account type
6. Set your platform name to "ClipBet"

### Stripe Webhooks

7. Go to **Developers > Webhooks**
8. Add endpoint: `https://your-backend.railway.app/webhooks/stripe`
9. Select events:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `transfer.created`
   - `transfer.failed`
10. Copy the signing secret -> `STRIPE_WEBHOOK_SECRET`

### Apple Pay Setup (Production)

11. In Stripe Dashboard > **Settings > Payment Methods**
12. Enable Apple Pay
13. Add your domain and verify with the Apple Pay domain file
14. For the App Clip, Apple Pay works via `PKPaymentRequest`
    with the Stripe iOS SDK confirming the PaymentIntent

---

## 3. Deploy Backend to Railway (Free)

Railway gives you $5/month free credit, enough for this project.

1. Go to [railway.app](https://railway.app) and sign in with GitHub
2. Click **New Project > Deploy from GitHub Repo**
3. Select your repository
4. Set the **Root Directory** to `backend`
5. Railway auto-detects Node.js

### Environment Variables

In the Railway dashboard, go to **Variables** and add:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
PORT=3001
NODE_ENV=production
PLATFORM_FEE_RATE=0.05
RESOLUTION_TIMEOUT_HOURS=24
CLIPBET_BASE_URL=https://clipbet.io
```

### Custom Domain (Optional)

6. In Railway, go to **Settings > Domains**
7. Add a custom domain: `api.clipbet.io`
8. Update DNS to point to Railway

---

## 4. Alternative: Deploy to Vercel (Free)

If you prefer Vercel (Serverless):

1. Create `vercel.json` in the `backend/` directory:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "src/index.ts",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    { "src": "/(.*)", "dest": "src/index.ts" }
  ]
}
```

2. Run `npx vercel --cwd backend`
3. Add environment variables in Vercel dashboard

---

## 5. Local Development

```bash
cd backend
cp .env.example .env
# Fill in your keys in .env

npm install
npm run dev
```

The server starts at `http://localhost:3001`

Test the health endpoint:
```bash
curl http://localhost:3001/health
```

---

## 6. Connecting the App Clip

In the iOS App Clip, update the API base URL:

```swift
// In production, point to your deployed backend
let apiBaseURL = "https://your-backend.railway.app"

// For local dev with simulator
let apiBaseURL = "http://localhost:3001"
```

For the hackathon demo, the App Clip uses mock data.
To connect to the real backend:

1. Replace mock payment calls with real API calls
2. Use `URLSession` to call `POST /events/:id/bets`
3. Use the returned `client_secret` with Stripe iOS SDK
4. The SDK presents the Apple Pay sheet natively

---

## 7. Stripe Test Cards

Use these in test mode:
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`
- 3D Secure: `4000 0025 0000 3155`

Apple Pay in Simulator: Add a test card in
Settings > Wallet and Apple Pay.

---

## Architecture Overview

```
User's Phone (App Clip)
  |
  | Apple Pay Sheet
  |
  v
Your Backend (Railway)
  |
  |-- Supabase (Database)
  |     Events, Bets, Organizers, Options
  |
  |-- Stripe (Payments)
        PaymentIntents (bets)
        Connect Transfers (payouts)
        Refunds (cancellations)
        Webhooks (status updates)
```

Money Flow:
1. Bettor taps Apple Pay -> Stripe creates PaymentIntent
2. Funds held on platform Stripe account (escrow)
3. Organizer resolves -> 5% fee deducted
4. Remaining pool split proportionally among winners
5. Stripe Connect transfers to winner accounts
6. If cancelled -> full Stripe refunds
7. If 24h passes unresolved -> automatic refunds

---

## Cost Summary (Free Tier)

| Service | Free Tier |
|---------|-----------|
| Supabase | 500MB DB, unlimited API |
| Railway | $5/month credit |
| Stripe | No monthly fee, 2.9% + 30c per transaction |
| Total | $0 until you process real payments |
