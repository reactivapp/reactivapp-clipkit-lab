import SwiftUI

struct CauseLandingView: View {
    let cause: CauseData
    @EnvironmentObject var donationState: DonationState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(.giveGreen, in: Circle())
                    .padding(.top, 24)

                VStack(spacing: 4) {
                    Text(cause.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.giveTextPrimary)
                        .multilineTextAlignment(.center)
                    Text(cause.city)
                        .font(.system(size: 16))
                        .foregroundStyle(.giveTextSecondary)
                }

                Text("Neighbours helping neighbours in \(cause.city)")
                    .font(.system(size: 16).italic())
                    .foregroundStyle(.giveGreen)

                Text(cause.scenario)
                    .font(.system(size: 14))
                    .foregroundStyle(.giveTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 32)

                GoalProgressBar(current: cause.mealsToday, goal: cause.dailyGoal)
                    .padding(.horizontal, 16)

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.giveTextSecondary)
                    Text("\(cause.donorsThisWeek) people gave in \(cause.city) this week")
                        .font(.system(size: 13))
                        .foregroundStyle(.giveTextSecondary)
                }

                CityLeaderboard(currentCauseId: cause.id)
                    .padding(.horizontal, 16)

                Button {
                    withAnimation(.spring(duration: 0.35)) {
                        donationState.currentScreen = .amount
                    }
                } label: {
                    Text("Feed Someone Today")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.giveGreen, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }
}
