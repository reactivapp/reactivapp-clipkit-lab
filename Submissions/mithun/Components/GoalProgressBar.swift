import SwiftUI

struct GoalProgressBar: View {
    let current: Int
    let goal: Int

    @State private var animatedProgress: CGFloat = 0

    private var targetProgress: CGFloat {
        guard goal > 0 else { return 0 }
        return min(CGFloat(current) / CGFloat(goal), 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(current) / \(goal) meals today")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.giveTextPrimary)
                Spacer()
                Text("\(Int(targetProgress * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.giveGreen)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.giveLightGreen)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.giveGreen)
                        .frame(width: geo.size.width * animatedProgress, height: 12)
                }
            }
            .frame(height: 12)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedProgress = targetProgress
                }
            }
        }
    }
}
