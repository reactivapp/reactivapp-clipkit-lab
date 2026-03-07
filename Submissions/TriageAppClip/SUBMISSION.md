## Team Name: Triage Team
## Clip Name: Medical Triage
## Invocation URL Pattern: hospital.ca/triage

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
When patients arrive at a busy clinic or ER, they must wait in line just to report their initial symptoms and hand over their health card. Vital signs like heart rate and respiratory rate are typically only measured once they reach a nurse, creating bottlenecks. This App Clip allows patients to scan a QR code at their seat and, within seconds, have their vitals captured contactlessly via the front camera using the Presage SDK, their Ontario Health Card number scanned via inline OCR, and their symptoms submitted via text or voice dictation — all before seeing a nurse. This compresses the entire intake process into a single, self-service step.

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
1. Patient scans a QR code at their seat in the waiting room (the URL encodes their `seat`).
2. **Step 1 — Face Scan:** The App Clip opens and immediately begins a contactless vitals scan using the front camera (Presage SDK). Heart rate, respiratory rate, and blood pressure are displayed live in pill-shaped badges. After 5 seconds of stable readings, the clip auto-advances.
3. **Step 2 — Health Card:** The camera feed continues while inline OCR (Vision framework) scans for an Ontario Health Card number (OHIP format `XXXX-XXX-XXX-XX`). Once detected, it auto-advances. The patient can also tap "I don't have my health card" to skip.
4. **Step 3 — Symptoms:** The patient describes their symptoms by typing or using the built-in voice dictation button (Speech framework). They tap Submit, which sends a JSON payload (seat number, median vitals, health card number, and symptoms) to the backend API.
5. A success overlay confirms receipt, and the patient waits for a nurse.

**How does the 8-hour notification window factor into your strategy?**
If blood test results, triage priority changes, or updates to estimated wait times occur within 8 hours, the clinic can send a push notification to the patient directly through the App Clip's notification channel — keeping them informed without requiring a full app download.

---

### 3. Platform Extensions (if applicable)

Does your solution require new Reactiv Clips capabilities that do not exist today? If so, describe them and explain why they are required.
No new platform capabilities are required. The clip uses standard iOS frameworks (AVFoundation, Vision, Speech) alongside the Presage SmartSpectra SDK for contactless vitals.

---

### 4. Prototype Description

What does your working prototype demonstrate? Which screens/flows are implemented?
The prototype implements `TriageAppClipExperience` with a complete 3-stage flow:

- **Stage 1 — Face Scan:** Uses the Presage SmartSpectra SDK in continuous mode to capture heart rate, respiratory rate, and phasic blood pressure from the front camera. Vitals are stored in rolling 5-second buffers and displayed as live median values. A mock-vitals mode (`useMockVitals` flag) is available for development without consuming API credits.
- **Stage 2 — Health Card OCR:** Runs Vision `VNRecognizeTextRequest` on the live camera feed every second, matching the Ontario Health Card (OHIP) regex pattern. Detected numbers are displayed and auto-advance the flow. A debug overlay can be toggled via the `showOCRDebugView` flag.
- **Stage 3 — Symptom Entry:** A text editor with an inline voice dictation button (Speech framework). On submit, a JSON payload (`seatNumber`, `heartRate`, `respiratoryRate`, `bloodPressure`, `symptoms`, `healthCardNumber`) is POSTed to `https://hack-canada2026-dashboard.vercel.app/api/triage`. Error states and loading indicators are handled.
- **Success State:** A `ClipSuccessOverlay` confirms submission.

Supporting files:
- `HealthCardScannerView.swift` — `CameraManager` (AVCaptureSession wrapper for mock-mode camera preview and frame capture) and `CameraPreviewView` (SwiftUI UIViewRepresentable for the live preview).

Minimum expectation:
- A working `ClipExperience`
- Invokable via your URL pattern in Invocation Console
- At least one complete user flow with a clear end state

---

### 5. Impact Hypothesis

How does this create measurable business impact? Be specific about:
- **Reduced wait and intake times:** Vitals and health card data are captured before the patient reaches a nurse, cutting per-patient intake time significantly and reducing front-desk congestion during peak hours.
- **Improved triage accuracy and speed:** Real-time vitals arrive on the nurse's dashboard alongside symptoms, enabling faster prioritization of critical cases.
- **Higher patient satisfaction:** Patients feel empowered and engaged from the moment they sit down, rather than waiting passively. The contactless, self-service flow removes friction and reduces perceived wait time.
- **In-person channel benefit:** This directly improves the in-person clinic experience. There is no online commerce component — the value is entirely in streamlining on-site patient flow.

---

### Demo Video

Link: N/A

### Screenshot(s)
N/A
