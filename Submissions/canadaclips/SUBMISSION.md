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

Link: https://drive.google.com/file/d/1y2qr6llciL2pgqPU5PtuVDP4nNlAj5ih/view?usp=sharing

### Screenshot(s)

- Discovery screen (collapsed)
- Discovery results with pinned + Gemini alternatives
- Checkout screen
- Payment success animation
- Visit Store deep-link behavior

<!-- Link to video or paste screenshots -->

screenshots:
https://github.com/user-attachments/assets/7379dd79-5a63-40b1-9e99-c26f58e11df3
https://github.com/user-attachments/assets/829a02b4-50c1-4b76-afd4-df3642142193
https://github.com/user-attachments/assets/5327cf5b-ca47-4742-812b-5c31b0202f83
https://github.com/user-attachments/assets/76f40145-5903-4ccc-9e2a-3307e74c1f53
https://github.com/user-attachments/assets/7122e4fa-05dd-4216-adbe-92ca39c0afac
https://github.com/user-attachments/assets/0c0769b4-4251-4be2-bc2b-7334315b025f
https://github.com/user-attachments/assets/a1c3b36f-5180-4053-98bf-d037026eeef3
https://github.com/user-attachments/assets/04296ee5-0047-4c0a-ae17-94b68a765df0
https://github.com/user-attachments/assets/709dafac-f176-40d8-8ff6-6b6580d23332

**GitHub to merchant's side: https://github.com/ammar-adam/canada-clip-dashboard**
