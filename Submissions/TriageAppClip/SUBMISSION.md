## Team Name: Triage Team
## Clip Name: Medical Triage
## Invocation URL Pattern: example.com/triage

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
When patients arrive at a busy clinic or ER, they often have to wait in line just to report their initial symptoms to a triage nurse. This App Clip allows them to scan a QR code at their seat or in the waiting room and immediately submit their symptoms and seat number to the nurse's dashboard. This reduces physical lines, captures patient data faster, and helps staff prioritize critical patients sooner without manual data entry.

---

### 2. Proposed Solution

**How is the Clip invoked?** (check all that apply)
- [x] QR Code (printed on physical surface)
- [ ] NFC Tag (embedded in object — wristband, poster, etc.)
- [ ] iMessage / SMS Link
- [ ] Safari Smart App Banner
- [ ] Apple Maps (location-based)
- [ ] Siri Suggestion
- [ ] Other: ___

**End-to-end user experience** (step by step):
1. Patient scans QR code in the waiting room.
2. The Medical Triage App Clip opens instantly with a simple text field.
3. Patient types their symptoms and taps Submit, which sends the data to the clinic's local REST API triage dashboard.

**How does the 8-hour notification window factor into your strategy?**
If blood test results or changes in wait time occur within 8 hours, the clinic can send a push notification to update the patient directly through the App Clip's notification channel.

---

### 3. Platform Extensions (if applicable)

Does your solution require new Reactiv Clips capabilities that do not exist today? If so, describe them and explain why they are required.
No new capabilities required.

---

### 4. Prototype Description

What does your working prototype demonstrate? Which screens/flows are implemented?
The prototype implements `TriageAppClipExperience`, showing a form that accepts user symptoms and submits them as a JSON payload via an HTTP POST request to `http://localhost:3000/api/triage`. It handles loading states and displays a success overlay when the API returns a 200 response, successfully integrating with the Triage Dashboard API.

Minimum expectation:
- A working `ClipExperience`
- Invokable via your URL pattern in Invocation Console
- At least one complete user flow with a clear end state

---

### 5. Impact Hypothesis

How does this create measurable business impact? Be specific about:
- Measurably reduces front-desk wait times and congestion during peak hours.
- Improves patient satisfaction scores by empowering them to act immediately upon arrival.
- Reduces time-to-triage for potentially critical cases since data enters the system before the patient reaches the desk.

---

### Demo Video

Link: N/A

### Screenshot(s)
N/A
