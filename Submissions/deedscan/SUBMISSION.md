## Team Name: DeedScan
## Clip Name: DeedScan — View Property
## Invocation URL Pattern: deedscan.app/clip (query param `id` optional: deedscan.app/clip?id=demo_listing_001)

---

## What Great Looks Like

Your submission is strong when it is:
- **Specific**: one clear fan moment, one clear problem, one clear outcome
- **Clip-shaped**: value in under 30 seconds, no heavy onboarding
- **Business-aware**: connects to revenue (venue, online, or both)
- **Testable**: prototype actually runs in the simulator with your URL pattern

---

### 1. Problem Framing

**Problem:** Buyers walk past for-sale signs and end up on sites built around 5% commissions. With DeedScan: scan → instant listing + neighbourhood snapshot + direct seller contact. Zero friction.

---

### 2. Proposed Solution

**Invocation:** Physical QR code on a yard sign encodes `deedscan.app/clip?id=demo_listing_001`

**Core action:** View listing + neighbourhood info → tap Message Seller. Under 20 seconds.

**Why a Clip not an app:** Purely ephemeral lookup — people won't install an app to view one listing they passed on the street.

---

### 3. Platform Extensions (if applicable)

None required. The Clip uses hardcoded demo data and deep-links into the web app for messaging (localhost:3000 for local Auth0).

---

### 4. Prototype Description

**What does your working prototype demonstrate?**

- **Landing:** Hardcoded demo listing — no API calls, no loading state
- **Photo carousel:** 2 swipeable photos (AsyncImage, TabView .page)
- **Property detail:** Title, address, price, agent savings pill, specs (beds, sqft, 0% Commission), AI Fraud Score badge
- **Neighbourhood Snapshot:** Summary + "See more" sheet with Transit, Groceries, Schools
- **Message Seller CTA:** Opens `http://localhost:3000/messages?listingId=demo_listing_001&sellerId=demo_seller_001`

---

### 5. Impact Hypothesis

**Impact:** Removes the real estate agent as gatekeeper at the very first touchpoint in the transaction.

---

### Demo Video

Link: ___ (add screen recording of: tap card → property loads → Message Seller / Neighbourhood sheet)

### Screenshot(s)

(Add screenshots of: property detail view, AI badge, Neighbourhood Snapshot, Message Seller CTA)
