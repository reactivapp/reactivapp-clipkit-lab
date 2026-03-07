import SwiftUI

struct CityLeaderboard: View {
    let currentCauseId: String

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 0) {
                ForEach(CauseData.allCauses) { cause in
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.green)

                        Text(cause.city)
                            .font(.system(size: 14, weight: cause.id == currentCauseId ? .bold : .medium))

                        Spacer()

                        Text("\(cause.mealsToday) meals")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)

                    if cause.id != CauseData.allCauses.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 14))
                Text("City Leaderboard")
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .tint(.green)
    }
}
