## Team Name: Reparo
## Clip Name: Reparo
## Invocation URL Pattern: example.com/reparo/repair

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
- [x] Purchase / conversion
- [x] In-person / on-site interaction
- [ ] Post-purchase / re-engagement
- [x] Other: Utility — repair guidance at the moment something breaks

What friction or missed opportunity are you solving for? (3-5 sentences)

When something breaks, people usually don’t know where to start. Is it worth fixing? How hard is it? What parts do they need, and where do they buy them? The usual path is a mix of search results, forums, and shopping sites. Reparo gives a single path: take a photo, get a repair assessment and step-by-step instructions, and add the right parts and tools to a cart. No app install, no account. The goal is to get from “it’s broken” to “I know what to do and I can buy it” in one short session.

---

### 2. Proposed Solution

**How is the Clip invoked?** (check all that apply)
- [x] QR Code (printed on physical surface)
- [x] NFC Tag (embedded in object — wristband, poster, etc.)
- [ ] iMessage / SMS Link
- [ ] Safari Smart App Banner
- [ ] Apple Maps (location-based)
- [ ] Siri Suggestion
- [ ] Other: ___

**End-to-end user experience** (step by step):
1. User opens the Clip by scanning a QR code (e.g. on product packaging or a tag) or tapping an NFC tag on the product.
2. Inside the Clip, they take a photo of the broken item or choose one from their library. A backend analyzes the image and returns a repair report: repairability, difficulty, estimated cost and time, step-by-step instructions, and a list of parts and tools.
3. The user taps “Checkout” to see a cart of recommended parts and tools (with the option to remove items) and can complete a mock purchase via Credit/Debit, Solana, or Shop Pay, all within the Clip.

**How does the 8-hour notification window factor into your strategy?**

We’d use it to re-engage users who didn’t finish: send a link back to their repair guide, or a reminder if they left items in the cart. We could also use it as a progress check — e.g. “How’s the repair going?” — especially if the step-by-step instructions were a checkable to-do list in the Clip; users could mark steps complete, and the notification could reflect that (e.g. “You’ve got 2 steps left”) or simply prompt them to open the guide again. That keeps people moving without needing a full app.

---

### 3. Platform Extensions (if applicable)

Adding AR technology for better visualization of repairs would be extremely helpful to the client, albeit might slow down the overall time on the app clip. This could be a optional feature for the user to choose to use and could be optimized to generate AR visuals as quickly as possible to make our App Clip stil fast but even more powerful.

---

### 4. Prototype Description

What does your working prototype demonstrate? Which screens/flows are implemented?

The prototype runs the full Reparo flow end to end:

- **Welcome** — Short explanation of the flow (upload photo → get report → buy parts). One primary action to start.
- **Upload** — User selects an image from the photo library or, on device, uses the camera. Preview is shown before submit.
- **Analyzing** — Loading state while the backend processes the image (FastAPI + Gemini).
- **Results** — Repair report with repairability and difficulty badges, cost and time estimates, expandable step-by-step instructions, parts and tools lists, and links to product pages.
- **Checkout** — Cart built from the recommended parts and tools, with per-item prices that sum to the estimated cost. Items can be removed. Three mock payment options: Credit/Debit, Solana, and Shop Pay.
- **Order Confirmed** — Success state with the option to start a new repair.

Invocation: `example.com/reparo/repair` in the Invocation Console. Backend is a live FastAPI service; product links use the Shopify Storefront API where available.

---

### 5. Impact Hypothesis

How does this create measurable business impact? Be specific about:

**Channels:** In-person and online both benefit. In-person: QR on packaging or at retail puts repair help and parts purchase at the point of need; NFC on products (e.g. furniture, appliances) can drive repair and parts sales long after purchase. Online: support can send a Reparo link instead of long troubleshooting; the Clip turns a support touch into a potential parts sale.

**Conversion:** The current path from “broken” to “bought the part” has many steps and high drop-off. Reparo shortens it to one session with a clear recommendation and checkout. We expect a meaningful lift in repair-parts conversion (on the order of several times) for users who complete the flow, since research and purchase happen in the same place. Retailers or brands that own the Clip keep the sale instead of losing it to third-party search.

**Touchpoint:** The moment something breaks is when intent is highest. A Clip that returns a repair plan and a way to buy in under 30 seconds, with no install or sign-up, is timed for that moment.

---

### Demo Video

[https://www.youtube.com/watch?v=JoFuqZbOmnA](https://www.youtube.com/watch?v=JoFuqZbOmnA)

### Screenshot(s)
<img width="493" height="998" alt="Screenshot 2026-03-07 at 10 24 10 PM" src="https://github.com/user-attachments/assets/3977570b-029d-45b9-b646-2dc23c7d2e2b" />
<img width="528" height="985" alt="Screenshot 2026-03-07 at 10 24 22 PM" src="https://github.com/user-attachments/assets/d8ad0bd2-68e4-4989-b2c6-a5e465f80887" />
<img width="495" height="1060" alt="Screenshot 2026-03-07 at 10 24 55 PM" src="https://github.com/user-attachments/assets/d20a546c-58a3-480f-a769-789db37c29fd" />
<img width="559" height="1038" alt="Screenshot 2026-03-07 at 10 25 11 PM" src="https://github.com/user-attachments/assets/cb578cb7-2cf4-4fa8-8a82-f9172f9fbc26" />
<img width="567" height="1010" alt="Screenshot 2026-03-07 at 10 25 23 PM" src="https://github.com/user-attachments/assets/75409462-7143-4436-be06-52bafef20732" />
<img width="516" height="999" alt="Screenshot 2026-03-07 at 10 25 29 PM" src="https://github.com/user-attachments/assets/c606c766-6dab-4725-8c2e-1575290c5cfe" />
<img width="489" height="994" alt="Screenshot 2026-03-07 at 10 25 34 PM" src="https://github.com/user-attachments/assets/1b48e87e-0e0b-4cc4-8796-c05a6fb18adc" />
<img width="501" height="1006" alt="Screenshot 2026-03-07 at 10 25 48 PM" src="https://github.com/user-attachments/assets/332ceef0-2d9d-43b8-a155-d8894061acee" />
<img width="494" height="1057" alt="Screenshot 2026-03-07 at 11 18 00 PM" src="https://github.com/user-attachments/assets/80a19ec1-e724-43f4-ac31-db94ebe88a76" />
<img width="508" height="1068" alt="Screenshot 2026-03-07 at 11 52 33 PM" src="https://github.com/user-attachments/assets/2868362a-4591-4d36-a198-703fe07b2de3" />

