import SwiftUI
import UserNotifications

struct ImpactConfirmationView: View {
    let cause: CauseData
    @EnvironmentObject var donationState: DonationState

    @State private var showCheckmark = false
    @State private var showText = false
    @State private var showCounter = false
    @State private var showDetails = false
    @State private var updatedProgress: CGFloat = 0

    private var mealsProvided: Int {
        donationState.mealsProvided
    }

    private var newMealCount: Int {
        cause.mealsToday + mealsProvided
    }

    private var newProgress: CGFloat {
        guard cause.dailyGoal > 0 else { return 0 }
        return min(CGFloat(newMealCount) / CGFloat(cause.dailyGoal), 1.0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 24)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.giveGreen)
                    .scaleEffect(showCheckmark ? 1.0 : 0.1)
                    .opacity(showCheckmark ? 1.0 : 0.0)

                if showText {
                    Text("You just provided \(mealsProvided) meal\(mealsProvided == 1 ? "" : "s") in \(cause.city) today.")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.giveTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if showCounter {
                    VStack(spacing: 8) {
                        Text("\(cause.mealsToday) meals")
                            .font(.system(size: 16))
                            .foregroundStyle(.giveTextSecondary)
                            .strikethrough(true, color: .giveTextSecondary)

                        ImpactCounter(
                            startValue: cause.mealsToday,
                            endValue: newMealCount
                        )
                    }
                    .transition(.opacity)
                }

                if showDetails {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Community Goal")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.giveTextPrimary)
                                Spacer()
                                Text("\(newMealCount) / \(cause.dailyGoal)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.giveGreen)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.giveLightGreen)
                                        .frame(height: 12)

                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.giveGreen)
                                        .frame(width: geo.size.width * updatedProgress, height: 12)
                                }
                            }
                            .frame(height: 12)
                        }
                        .padding(.horizontal, 16)

                        HStack(spacing: 6) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.giveGreen)
                            Text("We'll send you an update in a few hours")
                                .font(.system(size: 14))
                                .foregroundStyle(.giveTextSecondary)
                        }

                        Button {
                            shareGiveClip()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 15))
                                Text("Tell someone about \(cause.name)")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.giveGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.giveGreen, lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal, 16)

                        Text("Track your lifetime impact — Download the app")
                            .font(.system(size: 13))
                            .foregroundStyle(.giveTextSecondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear { runEntrySequence() }
    }

    private func runEntrySequence() {
        withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
            showCheckmark = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                showText = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showCounter = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                showDetails = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 1.0)) {
                updatedProgress = newProgress
            }
        }

        writeBackboardMemory()
        scheduleImpactNotification()
    }

    // MARK: - Backboard Memory

    private static let backboardAPIKey = "espr_N8iIQE8wNuJCq1VKebscrrB23EbGvbLHGaQF7BZoD54"
    private static let backboardAssistantId = "6ae73c6a-9d50-47fa-a224-cecb3b4e94d4"

    private func writeBackboardMemory() {
        let amount = donationState.finalAmount
        let meals = donationState.mealsProvided
        let city = cause.city
        let causeId = cause.id

        Task.detached(priority: .utility) {
            let formatter = ISO8601DateFormatter()
            let timestamp = formatter.string(from: Date())

            let metadata: [String: Any] = [
                "causeId": causeId,
                "binLocation": causeId,
                "amount": amount,
                "meals": meals,
                "city": city,
                "timestamp": timestamp,
            ]
            let body: [String: Any] = [
                "content": "Donation: $\(amount), \(meals) meals, \(city), \(causeId)",
                "metadata": metadata,
            ]

            guard let url = URL(string: "https://app.backboard.io/api/assistants/\(Self.backboardAssistantId)/memories"),
                  let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(Self.backboardAPIKey, forHTTPHeaderField: "X-API-Key")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            _ = try? await URLSession.shared.data(for: request)
        }
    }

    private func scheduleImpactNotification() {
        let causeName = cause.name
        let causeCity = cause.city
        let causeId = cause.id
        let mealCount = newMealCount
        let provided = mealsProvided

        Task { @MainActor in
            let center = UNUserNotificationCenter.current()

            GiveClipNotificationDelegate.shared.install(on: center)

            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                guard granted else { return }

                let content = UNMutableNotificationContent()
                content.title = "Flourish • \(causeName)"
                content.body = "Your $\(donationState.finalAmount) provided \(provided) meals. Today's count: \(mealCount) meals packed across \(causeCity). Thank you!"
                content.sound = .default
                content.categoryIdentifier = "GIVE_IMPACT"
                if let logoAttachment = makeNotificationLogoAttachment() {
                    content.attachments = [logoAttachment]
                }

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "givekit-impact-\(causeId)",
                    content: content,
                    trigger: trigger
                )

                try await center.add(request)
            } catch {
                // Silently continue
            }
        }
    }

    private func makeNotificationLogoAttachment() -> UNNotificationAttachment? {
        let possibleNames = ["flourish_notification_logo", "flourish_logo", "logo512", "logo192"]

        for name in possibleNames {
            if let image = UIImage(named: name),
               let data = image.pngData() {
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).png")
                do {
                    try data.write(to: fileURL, options: .atomic)
                    return try UNNotificationAttachment(identifier: "flourish-logo", url: fileURL, options: nil)
                } catch {
                    continue
                }
            }
        }

        return nil
    }

    private func shareGiveClip() {
        let text = "I just funded \(mealsProvided) meals in \(cause.city) \u{1F96B} Tap to give: givekit.ca/cause/\(cause.id)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}

final class GiveClipNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = GiveClipNotificationDelegate()

    func install(on center: UNUserNotificationCenter) {
        center.delegate = self
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
