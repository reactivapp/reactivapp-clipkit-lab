## Team Name: Evergreen
## Clip Name: EvergreenClipExperience
## Invocation URL Pattern: evergreen.app/breathe/:venueId

---

## What You Should Deliver (Reactiv ClipKit Lab)

Per sponsor guidelines, this submission addresses:

- **Problem framing** — Which touchpoint(s) in the customer journey are you targeting, and why? What friction or missed opportunity are you solving for?
- **Proposed solution** — How does your solution use Reactiv Clips? How is the Clip invoked? What does the user experience look like end-to-end?
- **Platform extensions (if applicable)** — If your solution requires new Reactiv Clips capabilities, describe what they are and how they would work.
- **Prototype or mockup** — A visual demonstration of the key user flows (wireframes, clickable prototype, or equivalent).
- **Impact hypothesis** — How does your solution increase merchandise revenue (or equivalent business impact)? Be specific about which channel (venue, online, or both) and why.

---

### 1. Problem Framing

**Which user moment or touchpoint are you targeting?**

- [ ] Discovery / first awareness
- [ ] Intent / consideration
- [ ] Purchase / conversion
- [x] In-person / on-site interaction (venue, show day)
- [x] Post-purchase / re-engagement (the wait, afterglow)
- [ ] Other: ___

**What friction or missed opportunity are you solving for?**

Fans at live events (concerts, arenas, sports) often experience stress, long waits, and sensory overload. Venues and artists want to deepen engagement and build a direct relationship with attendees—but most touchpoints are transactional (tickets, merch). A **wellness moment** in the journey (e.g., "calm room," pre-show de-stress, or post-show wind-down) is a novel use case for an App Clip: no install, no account, instant value. It captures attention at a high-intent moment and creates a positive association with the brand. The friction we solve is **no low-friction way to offer a wellness micro-experience** at scale at the venue or in the wait period, and the missed opportunity is **converting that moment into full-app installs and ongoing engagement** (and eventually wellness-related merch or partner revenue).

---

### 2. Proposed Solution

**How is the Clip invoked?**

- [x] QR Code (e.g. at calm room, seat back, or lobby)
- [x] NFC Tag (e.g. wristband, poster at venue)
- [x] iMessage / SMS Link (sent pre-show or post-show)
- [ ] Safari Smart App Banner
- [ ] Apple Maps (location-based at venue)
- [ ] Siri Suggestion
- [ ] Other: ___

**End-to-end user experience (step by step):**

1. User opens Clip from URL trigger (e.g. `evergreen.app/breathe/rogers-arena`) — from QR, NFC, or link.
2. First screen: "How are you feeling?" — quick mood selection (Stressed, Tired, Okay, Good).
3. Second screen: 1-minute breathing task with countdown timer; user can tap "Done" early to complete in under 30 seconds.
4. Done state: a small tree grows from soil with a simple animation (reward for completing the moment).
5. Preview of a larger "treehouse" with locked rooms — teaser of what the full app offers.
6. Final CTA: "Get the full app" to download Evergreen (or the brand's app) for more exercises, full treehouse, and notifications.

**How does the 8-hour notification window factor into your strategy?**

After the Clip session, a gentle push (e.g. within 2–8 hours) can re-engage: "Your treehouse is growing. Open the app to unlock the next room." This drives return and full-app install without being intrusive, aligning with Reactiv Clips' time-sensitive engagement model.

---

### 3. Platform Extensions (if applicable)

None required. The prototype uses standard ClipExperience, URL invocation, and local state. Optional future extensions: venue-specific content via `venueId` path parameter, or notification templates for post-Clip re-engagement.

---

### 4. Prototype Description

**What does your working prototype demonstrate? Which screens/flows are implemented?**

- **Working ClipExperience:** `EvergreenClipExperience` conforms to the challenge protocol with a realistic URL pattern (`evergreen.app/breathe/:venueId`).
- **Invokable via Invocation Console:** Enter e.g. `evergreen.app/breathe/venue-1` to launch the clip.
- **Complete user flow:** Mood → Breathing (with timer and "Done") → Tree growth animation → Treehouse preview (locked rooms) → "Get the full app" CTA.
- **Value in under 30 seconds:** User can complete mood + tap Done after a short breathe and see the tree + treehouse + CTA within the 30-second moment.
- **ScrollView:** Content is wrapped so it does not fight host overlays (per sponsor guidelines).

---

### 5. Impact Hypothesis

**How does this create measurable business impact? Be specific about which channel and why.**

- **Channel:** Primarily **venue / in-person**, secondarily **online** (links sent pre- or post-show).
- **Mechanism:** The Clip delivers immediate wellness value (mood check + breathing + visual reward) with zero install. That builds trust and brand affinity. The locked treehouse preview and "Get the full app" CTA convert a portion of users to full-app installs. Full app can then drive:
  - **Merchandise / commerce:** Wellness products, partner offers, or event-specific merch tied to "your treehouse."
  - **Engagement:** Notifications and in-app content keep users in the brand's ecosystem.
- **Why this touchpoint:** Show day and the wait are high-attention moments; a useful, non-salesy Clip stands out and can be promoted by the venue or artist as a "calm moment" feature, differentiating the event and supporting both engagement and downstream revenue.

---

### Demo Video

Link: ___

### Screenshot(s)

(Add screenshots of: mood screen, breathing timer, tree growth, treehouse preview, CTA.)
