import SwiftUI

struct ImpactCounter: View {
    let startValue: Int
    let endValue: Int
    let duration: Double

    @State private var displayedValue: Int
    @State private var hasStarted = false

    init(startValue: Int, endValue: Int, duration: Double = 1.5) {
        self.startValue = startValue
        self.endValue = endValue
        self.duration = duration
        _displayedValue = State(initialValue: startValue)
    }

    var body: some View {
        Text("\(displayedValue)")
            .font(.system(size: 36, weight: .bold))
            .foregroundStyle(.green)
            .contentTransition(.numericText(value: Double(displayedValue)))
            .onAppear {
                guard !hasStarted else { return }
                hasStarted = true
                animateCounter()
            }
    }

    private func animateCounter() {
        let totalSteps = abs(endValue - startValue)
        guard totalSteps > 0 else { return }

        let interval = duration / Double(totalSteps)
        let direction = endValue > startValue ? 1 : -1

        for step in 1...totalSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                withAnimation(.easeOut(duration: 0.1)) {
                    displayedValue = startValue + (step * direction)
                }
            }
        }
    }
}
