## Team Name: Pointicart
## Clip Name: Pointicart: Point & Shop
## Invocation URL Pattern: pointicart.shop/store/:storeId

---

## What Great Looks Like

Your submission is strong when it is:
- **Specific**: one clear fan moment, one clear problem, one clear outcome
- **Clip-shaped**: value in under 30 seconds, no heavy onboarding
- **Business-aware**: connects to revenue (venue, online, or both)
- **Testable**: prototype actually runs in the simulator with your URL pattern

---

### 1. Problem Framing

Which user moment or touchpoint are you targeting?

- [ ] Discovery / first awareness
- [ ] Intent / consideration
- [ ] Purchase / conversion
- [x] In-person / on-site interaction
- [ ] Post-purchase / re-engagement
- [ ] Other: ___

What friction or missed opportunity are you solving for? (3-5 sentences)

In-store shoppers frequently browse products physically but face friction when they want pricing, sizing, or checkout information — they must find a sales associate, wait in line, or abandon the purchase entirely. Retail stores lose significant revenue to "silent abandonments" where interested shoppers leave without buying because the checkout process requires too many steps: find a register, wait in queue, complete a full POS transaction. Pointicart eliminates this friction by embedding NFC tags directly on store shelves. A single phone tap opens an ephemeral shopping clip that instantly identifies nearby products, lets shoppers browse sizes, add to cart, and pay with Apple Pay — all in under 30 seconds, with zero login or app install. The 8-hour notification window then recovers abandoned carts from shoppers who left without completing checkout.

---

### 2. Proposed Solution

**How is the Clip invoked?** (check all that apply)
- [ ] QR Code (printed on physical surface)
- [x] NFC Tag (embedded in object — shelf label, price tag, display rack)
- [ ] iMessage / SMS Link
- [ ] Safari Smart App Banner
- [ ] Apple Maps (location-based)
- [ ] Siri Suggestion
- [ ] Other: ___

**End-to-end user experience** (step by step):
1. Shopper taps their iPhone on an NFC tag embedded in a shelf label or display rack. The tag encodes `pointicart.shop/store/{storeId}` which identifies the specific store and section.
2. The App Clip opens instantly with a brief scanning animation that identifies products on the nearby shelf (simulating Pointicart's AR product identification). Within 2 seconds, the product grid appears showing items with prices and sizes.
3. Shopper taps to add items to their in-clip cart, reviews the order summary, and pays with Apple Pay. A pickup confirmation directs them to the front register. Total time: under 30 seconds.

**How does the 8-hour notification window factor into your strategy?**

The 8-hour ephemeral push window is critical for abandoned-cart recovery in a retail context:

- **15 minutes**: "Still shopping?" — catches shoppers still in-store who got distracted. Reminds them checkout takes 10 seconds.
- **1 hour**: "Your items are still available" — targets shoppers who may have left the store but are still nearby (mall, parking lot). Lists specific items left in cart.
- **3 hours**: "Exclusive: 10% off your cart" — incentivizes post-visit conversion with a time-limited discount, capturing revenue from shoppers who left without buying. Discount expires within the 8h window.

This mirrors proven e-commerce abandoned-cart email sequences but compressed into the 8-hour App Clip notification window, recovering revenue without requiring any account, email, or push permission.

---

### 3. Platform Extensions (if applicable)

No new Reactiv Clips capabilities are required. The experience uses:
- **NFC invocation** (existing App Clip trigger)
- **Ephemeral push notifications** (existing 8h window)
- **Apple Pay** (existing StoreKit integration, mocked in prototype)

In a production build, Pointicart would additionally leverage:
- **ARKit + Vision** for real-time hand-tracking product identification (the full Pointicart app uses Gemini 2.5 Flash for AI product recognition)
- **CoreML** for on-device product matching via CLIP embeddings
- These are available frameworks within App Clip constraints, requiring no new platform capabilities.

---

### 4. Prototype Description

The working prototype demonstrates a complete in-store shopping flow through four phases:

1. **Scanning Phase**: An animated scanning visualization simulates Pointicart's AR product identification. A progress ring fills as products are "discovered" on the shelf, with a counter showing items found. Auto-transitions to browse after ~2 seconds.

2. **Browse Phase**: Displays a grid of identified clothing products (Cropped Jacket $129.99, Graphic Tee $34.99, Oversized Hoodie $64.99, Knit Sweater $79.99) using the MerchGrid component. A store identity bar shows the NFC-derived store context. Adding items reveals an expandable CartSummary with item counts and running total.

3. **Checkout Phase**: A GlassEffect order review card shows items, subtotal, pickup location (Front Register), and payment method (Apple Pay). Back and Pay Now CTAs use ClipActionButton with spring transitions.

4. **Success Phase**: Animated ClipSuccessOverlay confirms the order with a pickup message. Below, a NotificationTimeline displays the three-stage abandoned-cart notification strategy with timing descriptions.

**Invokable via**: `pointicart.shop/store/42` in the Invocation Console.

---

### 5. Impact Hypothesis

**Which channel benefits?** Primarily in-person retail, with a bridge to online via the 8h notification window.

**Conversion improvement estimate:**
- **15-25% reduction in silent abandonments**: Shoppers who would have left without buying can now checkout from their pocket in seconds, bypassing register queues entirely.
- **8-12% cart recovery rate** from the 8h notification sequence: Based on e-commerce abandoned-cart benchmarks (10-15% recovery), adapted for the higher-intent in-store context where shoppers physically interacted with products.
- **20%+ increase in average order value**: The browse grid exposes shoppers to more products than they'd notice on the shelf, and the frictionless add-to-cart reduces the psychological cost of adding items.

**Why this touchpoint is the right place to intervene:** The moment a shopper is physically standing at a shelf is the highest-intent, lowest-patience moment in the retail journey. They've already self-selected interest by walking to that section. The only barrier to conversion is checkout friction — which this clip eliminates entirely. Every retail store already has shelf labels and price tags where NFC tags can be embedded at minimal cost ($0.10-0.30 per tag), making this infinitely scalable across any retail environment.

---

### Demo Video

Link: ___

### Screenshot(s)

