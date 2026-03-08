## Team Name: CanadaClips
## Clip Name: CanadaclipsClipExperience
## Invocation URL Pattern: example.com/canadaclips/:param (production-style flow: localclip.ai/p?url=<product-link>)

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

- [x] Discovery / first awareness
- [x] Intent / consideration
- [x] Purchase / conversion
- [ ] In-person / on-site interaction
- [x] Post-purchase / re-engagement
- [ ] Other: ___

Large marketplaces capture a lot of product demand immediately after users get recommendations from AI assistants or search. Smaller/local merchants lose that demand because users default to the first big-brand link. CanadaClips targets that exact moment: a user taps a product URL and is instantly shown comparable local alternatives in the same category and roughly the same price range. The missed opportunity is not lack of product supply, but lack of visibility and speed at decision time. This clip removes that friction by turning one tap into a local-first commerce decision in under 30 seconds.

---

### 2. Proposed Solution

**How is the Clip invoked?** (check all that apply)
- [ ] QR Code (printed on physical surface)
- [ ] NFC Tag (embedded in object — wristband, poster, etc.)
- [x] iMessage / SMS Link
- [x] Safari Smart App Banner
- [ ] Apple Maps (location-based)
- [ ] Siri Suggestion
- [x] Other: AI assistant answer links (ChatGPT / Gemini / Perplexity style product URLs)

**End-to-end user experience** (step by step):
1. User taps a product link (example: laptop/backpack/shawarma listing) from an AI response or shared message.
2. App Clip opens as a bottom-sheet experience and reads the source URL.
3. Backend (Gemini-first pipeline) analyzes the source product, price band, and category/use-case, then returns comparable non-big-retailer alternatives with policy filtering.
4. User sees Canadian/local-leaning alternatives with images, store names, and prices; hardcoded strategic trigger cases are pinned first when matched.
5. User can either tap **Visit Store** (opens merchant site directly) or continue to in-clip checkout mock flow.
6. Checkout confirms payment with success animation and returns user to discovery state.

**How does the 8-hour notification window factor into your strategy?**

The 8-hour window is used as a soft conversion recovery layer: if a user viewed alternatives but did not complete purchase, the merchant can send a single high-intent reminder (for example, “Local alternative still available at $X”). This keeps reminders contextual and time-bound, instead of generic retargeting. In this prototype the notification strategy is defined at product level and can be wired to merchant analytics events for controlled follow-up.

---

### 3. Platform Extensions (if applicable)

Core prototype works on current ClipKit capabilities.  
Optional platform extensions that would improve production readiness:

1. **First-class AI discovery adapter** in Reactiv Clips for grounded product matching (with policy guardrails and retries).
2. **Merchant policy config panel** (blocklist/allowlist, locality preference, category constraints) editable per merchant.
3. **Clip event analytics hooks** for `view`, `visit_store`, `checkout_start`, and `checkout_complete` tied to 8-hour notification automations.

These are not required to run the prototype but would reduce integration effort for real merchant deployment.

---

### 4. Prototype Description

The working prototype demonstrates a complete two-screen App Clip flow:

- **Discovery screen (collapsed + expanded states)**  
  Clean intro shell, URL input, loading state, alternatives list, and polished card UI.
- **Gemini-first discovery backend path**  
  For non-trigger URLs: same-query cache -> Gemini primary -> Gemini rescue -> synthetic fallback only as terminal fallback.
- **Hardcoded trigger pinning**  
  Four strategic URLs always pin a known merchant card at index 0.
- **Checkout screen**  
  Product summary, context-aware option selectors, subtotal/shipping/HST/total, mock Apple Pay/card buttons.
- **Payment success animation**  
  Checkmark/ripple/confetti overlay, then auto-return to discovery.
- **Resilient image behavior**  
  Remote images when available; deterministic category fallback art when missing.

Minimum expectation satisfied:
- [x] Working `ClipExperience`
- [x] Invokable via URL pattern in Invocation Console
- [x] At least one complete user flow with clear end state

---

### 5. Impact Hypothesis

CanadaClips primarily benefits the **online conversion channel**, with secondary benefit to local merchant acquisition and re-engagement.

- **Conversion lift hypothesis:** +8% to +15% click-through from recommendation surface to purchase-intent merchant pages, because alternatives are presented instantly in native UI without full app install.
- **Merchant mix impact:** measurable shift in outbound traffic share from large marketplaces to regional/specialty/local merchants at the exact point of intent.
- **Funnel efficiency:** reduced drop-off between discovery and action due to one-tap invocation, concise product cards, and clear CTA hierarchy.
- **Why this touchpoint:** the moment right after a user receives an AI recommendation is the highest-intent decision point; intercepting here is more valuable than post-abandonment retargeting.

---

### Demo Video

Link: ___

### Screenshot(s)

- Discovery screen (collapsed)
- Discovery results with pinned + Gemini alternatives
- Checkout screen
- Payment success animation
- Visit Store deep-link behavior
