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

    private var newMealCount: Int {
        cause.mealsToday + 1
    }

    private var originalProgress: CGFloat {
        guard cause.dailyGoal > 0 else { return 0 }
        return CGFloat(cause.mealsToday) / CGFloat(cause.dailyGoal)
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
                    .foregroundStyle(.green)
                    .scaleEffect(showCheckmark ? 1.0 : 0.1)
                    .opacity(showCheckmark ? 1.0 : 0.0)

                if showText {
                    Text("You just fed a family in \(cause.city) today.")
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if showCounter {
                    VStack(spacing: 8) {
                        Text("\(cause.mealsToday) meals")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .strikethrough(true, color: .secondary)

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
                                Spacer()
                                Text("\(newMealCount) / \(cause.dailyGoal)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.green)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 12)

                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.green)
                                        .frame(width: geo.size.width * updatedProgress, height: 12)
                                }
                            }
                            .frame(height: 12)
                        }
                        .padding(.horizontal, 16)

                        HStack(spacing: 6) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.green)
                            Text("We'll send you an update in a few hours")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
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
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.green, lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal, 16)

                        Text("Track your lifetime impact — Download the app")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
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

        scheduleImpactNotification()
    }

    private func scheduleImpactNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = cause.name
            content.body = "Today's count: \(newMealCount) meals packed across \(cause.city). Thank you for being part of it."
            content.sound = .default
            content.categoryIdentifier = "GIVE_IMPACT"

            // 10s for demo; 4 hours (14400s) in production
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(
                identifier: "givekit-impact-\(cause.id)",
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    private func shareGiveClip() {
        let text = "I just helped feed a family in \(cause.city) with one tap. \(cause.mealsToday + 1) meals packed today. Join in: givekit.ca/cause/\(cause.id)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}
