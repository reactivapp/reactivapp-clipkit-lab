# NaloxoneNow

NaloxoneNow is an App Clip submission built with the Reactiv Challenge Kit. It provides immediate access to naloxone kit locations, an overdose response guide, emergency contact actions, and support resources.

## Files
- `NaloxoneNow.swift` - Main ClipExperience implementation (UI and actions).
- `MockData.swift` - Sample naloxone locations used by the locator UI.

## How to run
1. Open `ReactivChallengeKit/ReactivChallengeKit.xcodeproj` in Xcode.
2. Build the project. Submissions are compiled via `GeneratedSubmissions.swift`.
3. In the simulator, open the Simulator shell provided by the project (if available) or run the app target and choose the simulated Clip invocation.

Note: This submission uses mock location data and a static map preview. It does not persist any location data.

## Privacy & Accessibility
- No location data is stored persistently. If integrated with live location services, request transient location access and explain purpose.
- Use system colors and semantic text to support Dynamic Type and Dark Mode.
- Add VoiceOver accessible labels on key UI elements.

## Next steps
- Integrate real Maps and geocoding to show live nearby naloxone availability.
- Connect to a backend for real-time open/availability status.
- Add localization and unit tests.
