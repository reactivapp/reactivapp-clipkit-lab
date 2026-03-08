## Team Name: ClipBet
## Clip Name: ClipBet
## Invocation URL Pattern: 
- `clipbet.io/event/:eventId` (opens a specific prediction market for one event)
- `clipbet.io/discover` (opens a generic discovery / create-event entry point)

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
- [x] Post-purchase / re-engagement
- [x] On-site gamification / engagement
- [x] Community / social interaction
- [ ] Other: ___

What friction or missed opportunity are you solving for? (3-5 sentences)

When people are at a bar, game, or concert, there is a lot of energy and strong opinions about what will happen next (overtime, encore, final score, etc.), but there is no simple way to act on those opinions in the moment. Existing prediction markets require downloading a full app, creating an account, and going through identity checks before placing a bet, which kills the spontaneity. By the time someone finishes onboarding, the key moment has usually passed. Venues and event organizers also have almost no way to turn this in-the-moment hype into direct revenue or to capture fan identity beyond the ticket sale. ClipBet turns this gap into a simple flow: scan a code, place a small prediction in under 30 seconds, and let the venue and platform share in the pool.

---

### 2. Proposed Solution

**How is the Clip invoked?** (check all that apply)
- [x] QR Code (printed on physical surface)
- [x] NFC Tag (embedded in object — wristband, poster, etc.)
- [x] iMessage / SMS Link
- [ ] Safari Smart App Banner
- [x] Apple Maps (location-based discovery of nearby active prediction markets)
- [ ] Siri Suggestion
- [ ] Other: ___

**End-to-end user experience** (step by step):

*(Note: For the demo, we use the App Clip launcher in the Reactiv lab project. In production, this would normally be QR or NFC).*

**A. Bettor (fan) flow**
1. **Launch:** A fan at a venue (or seeing a pole on the street, next to a bar, pub, skatepark, or any social location) scans a QR code (`clipbet.io/event/:eventId`). The Clip launches and displays event info, total pool, and active bettors. 
2. **Bet:** The fan taps "Place a Bet", enters their email & an optional nickname, selects an outcome, and chooses a bet amount.
3. **Confirm:** They check their estimated return, confirm, and pay using Apple Pay.
4. **Success:** The bet is placed, a confirmation receipt is shown, and the user enables closure notifications before dismissing the Clip.

**B. Organizer (operator) flow**
1. **Launch & Setup:** An organizer launches the Clip via `clipbet.io/discover` (or a "Create your own" QR). They view the current event info, pool, and bettors.
2. **Authenticate & Agree:** The organizer signs in with Apple securely and agrees with the terms of service.
3. **Create Market:** They upload an event photo, provide a name and description, add specific outcomes, and define the event time, location, and minimum bet amount.
4. **Preview & Go Live:** The organizer previews the market and taps to create it.
5. **Share the Market:** A unique QR code is generated and displayed. The organizer can scan it from another device or access core share functionality.
6. **Manage:** They navigate to their dashboard to view the total pool, live bettors, organizer fee, and outcome breakdowns. They can close bets, cancel/refund all participants, resolve events, or generate a printable PDF.

**C. Potential / Discovery flow**
1. A user launches `clipbet.io/discover` and sees "Browse Nearby Events" or "Create Event".
2. Browsing would show nearby markets with distance, pool size, and status.
3. Tapping a market takes them directly into the Bettor flow for that specific event.

**How does the 8-hour notification window factor into your strategy?**

We treat the 8‑hour notification window as a way to close the loop on each market, not as a spam channel. When someone places a bet and opts in, they give permission for notifications related *only* to that specific market.

When notifications are turned on, the user will be notified:
- **When Bets Close:** A quick heads up that the market is officially locked, along with a tally of how many people jumped in.
- **When Event Ends (Resolution):** A single focused alert with the final payout results and a link to view the breakdown.

Potential additions to quietly manage the market's lifecycle:
- **Organizer Nudge:** A gentle reminder to the organizer around the 6-hour mark to make sure they resolve things before the window closes.
- **Auto-Resolve/Refunds:** If an organizer completely forgets to settle the bet, the pool is automatically refunded to participants.

- **Limitation:** For events lasting longer than 8 hours (like multi-day LAN tournaments), the notification window acts as a hard constraint for sending resolution alerts.

---

### 3. Platform Extensions (if applicable)

Does your solution require new Reactiv Clips capabilities that do not exist today? If so, describe them and explain why they are required.

**1. Persistent organizer session & dashboard access:**
- **Need:** An organizer should be able to close the Clip and later reopen it (from the same device) to access their dashboard without signing in again. While a full website might be better for managing many events, keeping this feature in the Clip still allows organizers to easily track multiple active markets at once.
- **Approach:** A small secure session token stored locally tied to Sign in with Apple.

**2. Role-aware Clip views (bettor vs organizer):**
- **Need:** The same URL should show the bettor view or organizer view depending on who is using it.
- **Approach:** On launch, the Clip checks user identity. If they are the owner, it shows the dashboard; otherwise, the normal betting UI.

---

### 4. Prototype Description

What does your working prototype demonstrate? Which screens/flows are implemented?

Minimum expectation:
- A working `ClipExperience`
- Invokable via your URL pattern in Invocation Console
- At least one complete user flow with a clear end state

The prototype demonstrates both bettor and operator flows running inside the Reactiv ClipKit simulator, with all data mocked locally (or managed via backend if applicable to the final demo).

**Implemented screens and flows:**
- **Discovery** (`/discover`): Entry point to view current event info or create a new market.
- **Event Landing** (`/event/:eventId`): Shows event photo, prediction question, outcome options, pool stats, and active bettors, along with "Place a Bet" and "Create Event" buttons (if applicable).
- **Betting Flow:** Email & nickname input, outcome selection, amount input, and seamless Apple Pay confirmation with 'real-time' return estimates.
- **Success/Receipt:** A confirmation screen proving the bet was placed, with an easy option to turn on notifications for when the event ends.
- **Organizer Setup (Creation):** Sign In with Apple, TOS agreement, and a form to define photo, name, description, location, time, outcomes, and minimum bet.
- **Market Preview & Launch:** A complete UI preview of the market before generating the live QR code and share sheet.
- **Organizer Dashboard:** A comprehensive view of total pool, bettors, fee earned, outcome breakdowns, plus controls to close bets, refund all, resolve the event, or generate a printable PDF.

---

### 5. Impact Hypothesis

How does this create measurable business impact? Be specific about:
- Which channel benefits (in-person, online, or both)?
- What conversion or engagement improvement do you estimate, and why?
- Why this touchpoint is the right place to intervene

**Which channel benefits (in-person, online, or both)?**
ClipBet mainly boosts in-person venues like bars, local LAN tournaments (Valorant/CS2), community events, and even hackathons by adding real-time engagement during the event. It also has an online tail through shared links, but the core value is physical spaces where people gather. It turns passive observers into active participants at the exact moment of highest energy.

**What conversion or engagement improvement do you estimate, and why?**
People bet on everything—from pro sports to local chess tournaments, "Hackathon best project," or "Will our bar trivia team take first?" We estimate a **20-30% participation rate** among attendees for small $5-15 bets. This creates $200-500 pools per event, with a platform cut generating immediate revenue.

Having even a tiny amount of money on the line makes people care more and stay longer for the final result. This is a great way to get people outdoors to watch local sports or community events they already love. By turning viewers into active participants, it brings the community closer together and provides organizers with a stable, predictable income for every event they host. Plus, it kinda symbolizes  the "wisdom of the crowd," making the results feel like a shared story everyone helped write. 

**Why this touchpoint is the right place to intervene?**
Live local events are where communities already gather, but they often lack a shared activity that gets everyone involved. Betting on hyperlocal outcomes (neighborhood soccer, LAN gaming matches, chess club tournaments, hackathon winners) turns passive watching into active participation. 

Because App Clips require **no app download**, we remove the #1 barrier to entry. This builds real relationships between venues, organizers, and fans at the exact moment when excitement is highest. It’s not just about the money—it’s about the "you had to be there" experience that makes a community feel tighter, more active, and genuinely engaged.

---

### Demo Video

Link: 
- Google Drive: https://drive.google.com/file/d/1arkTgzk7cXeK3CRYdO5rOis4Jtj7y74J/view?usp=sharing
- YouTube: https://youtu.be/yDGhNRkr158?si=1MTYBVBpnEIokRvg

*(Note: Based on the requirements, you can treat the first 30 seconds of the video, which outlines the user (bettor) flow, as the main part of the submission. The remainder of the video demonstrates the ephemeral operator flow.)*

### Screenshot(s)

*(Include screenshots here: Discovery view, Event Landing, Pace-A-Bet UI, Organizer Create Form, Organizer Dashboard, Resolved Event view)*

### Website/Live Demo
Link: https://clipbet-reactiv.vercel.app/
