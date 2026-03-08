//  OasisExperience.swift
//  ReactivChallengeKit
//
//  Copyright © 2025 Reactiv Technologies Inc. All rights reserved.
//

import SwiftUI

struct OasisExperience: ClipExperience {
    static let urlPattern = "oasis.app/refuge/:locationId"
    static let clipName = "Oasis"
    static let clipDescription = "A zero-pressure space to cultivate calm through micro-actions."
    static let teamName = "Oasis Team"
    static let touchpoint: JourneyTouchpoint = .utility
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    // MARK: - State

    @AppStorage("oasis.worldLevel") private var worldLevel: Int = 0
    @AppStorage("oasis.completedTasks") private var completedTasksData: Data = Data()
    
    @State private var phase: ExperiencePhase = .welcome
    @State private var selectedTask: MicroTask?
    @State private var showReward = false
    @State private var currentChoices: [MicroTask] = []
    
    enum ExperiencePhase {
        case welcome
        case choosing
        case reward
        case goodbye
    }

    struct MicroTask: Identifiable, Hashable, Codable {
        let id: String
        let title: String
        let icon: String
        let rewardDescription: String
        let worldEffect: String
    }

    private let allTasks: [MicroTask] = [
        MicroTask(id: "hydrate", title: "Drink some water", icon: "drop.fill", rewardDescription: "Your creek is flowing beautifully.", worldEffect: "creek"),
        MicroTask(id: "move", title: "Roll my shoulders", icon: "figure.walk", rewardDescription: "A new tree has taken root.", worldEffect: "tree"),
        MicroTask(id: "rest", title: "Close eyes for 30s", icon: "eye.slash.fill", rewardDescription: "The sun is setting peacefully.", worldEffect: "sunset"),
        MicroTask(id: "nourish", title: "Eat a small snack", icon: "leaf.fill", rewardDescription: "Berries are ripening in the brush.", worldEffect: "berries"),
        MicroTask(id: "breathe", title: "3 deep breaths", icon: "wind", rewardDescription: "The fog has cleared for you.", worldEffect: "clearSky"),
        MicroTask(id: "tidy", title: "Tidy one tiny thing", icon: "sparkles", rewardDescription: "The path ahead is clear.", worldEffect: "cleanPath"),
        MicroTask(id: "connect", title: "Send a nice text", icon: "message.fill", rewardDescription: "Birds have come to visit.", worldEffect: "birds"),
        MicroTask(id: "hygiene", title: "Wash face or hands", icon: "hand.raised.fill", rewardDescription: "A gentle rain leaves a rainbow.", worldEffect: "rainbow"),
        MicroTask(id: "outside", title: "Feel the fresh air", icon: "sun.max.fill", rewardDescription: "Fireflies dance in the evening.", worldEffect: "fireflies"),
        MicroTask(id: "wildcard", title: "I did something else", icon: "star.fill", rewardDescription: "A warm campfire keeps you cozy.", worldEffect: "campfire")
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background World View
            OasisWorldView(level: worldLevel, activeEffect: selectedTask?.worldEffect)
                .ignoresSafeArea()

            // Foreground Content
            VStack {
                switch phase {
                case .welcome:
                    welcomeView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                case .choosing:
                    choiceView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                case .reward:
                    rewardView
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                case .goodbye:
                    goodbyeView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60) // Stay above Simulator elements
        }
        .animation(.spring(duration: 0.8), value: phase)
        .onAppear {
            generateChoices()
            
            // 4-8s (The Welcome)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    phase = .choosing
                }
            }
        }
    }

    // MARK: - Views

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Text("Take a slow breath.")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .italic()
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text("What do you have energy for right now?")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var choiceView: some View {
        VStack(spacing: 20) {
            Text("SMALL ACTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(2.0)
                .padding(.bottom, 4)

            ForEach(currentChoices) { task in
                Button {
                    selectTask(task)
                } label: {
                    HStack(spacing: 20) {
                        Image(systemName: task.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(.blue)
                            .frame(width: 54, height: 54)
                            .background(.blue.opacity(0.1), in: .circle)
                        
                        Text(task.title)
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 28))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var rewardView: some View {
        VStack(spacing: 32) {
            if let task = selectedTask {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 56))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.bounce, value: showReward)
                    
                    Text("Beautiful.")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                }
                
                Text(task.rewardDescription)
                    .font(.system(size: 20))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                
                Button {
                    withAnimation {
                        phase = .goodbye
                    }
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(.blue, in: .capsule)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 12)
            }
        }
    }

    private var goodbyeView: some View {
        VStack(spacing: 20) {
            Text("You did enough for right now.")
                .font(.system(size: 26, weight: .medium, design: .serif))
                .multilineTextAlignment(.center)
            
            Text("See you later.")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
            
            Button {
                // Return action
            } label: {
                HStack {
                    Text("Return to my day")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(.blue, in: .capsule)
            }
            .padding(.top, 24)
            
            // Show notification preview as "Gentle Ripples"
            notificationStrategyView
                .padding(.top, 40)
        }
    }

    private var notificationStrategyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GENTLE RIPPLES")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1.5)
                .padding(.horizontal, 8)
            
            NotificationPreview(
                template: NotificationTemplate(
                    title: "A calm thought",
                    body: "Your Oasis is waiting for you. Take a second to breathe if you need it.",
                    journeyStage: "Afterglow",
                    triggerDescription: "2h window",
                    delayFromInvocation: 7200
                )
            )
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - Helper Methods

    private func generateChoices() {
        var shuffled = allTasks.shuffled()
        // Ensure wildcard is always one of the 3
        if let wildcardIdx = shuffled.firstIndex(where: { $0.id == "wildcard" }) {
            let wildcard = shuffled.remove(at: wildcardIdx)
            currentChoices = Array(shuffled.prefix(2)) + [wildcard]
            currentChoices.shuffle()
        } else {
            currentChoices = Array(shuffled.prefix(3))
        }
    }

    private func selectTask(_ task: MicroTask) {
        selectedTask = task
        
        // Haptic Pulse: zero-pressure validation
        #if !targetEnvironment(simulator)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
        
        // Audio: Organic chime followed by 3s ambient nature fade
        // PlaySound("organic_chime.mp3")
        // PlaySound("nature_ambient.mp3", fadeOutAfter: 3.0)
        
        // Simulating the 16-24s (The Reward)
        withAnimation(.easeInOut(duration: 2.0)) {
            showReward = true
            phase = .reward
        }
        
        worldLevel += 1
        saveCompletedTask(task)
    }

    private func saveCompletedTask(_ task: MicroTask) {
        var completed = getCompletedTasks()
        completed.append(task.id)
        if let data = try? JSONEncoder().encode(completed) {
            completedTasksData = data
        }
    }

    private func getCompletedTasks() -> [String] {
        if let completed = try? JSONDecoder().decode([String].self, from: completedTasksData) {
            return completed
        }
        return []
    }
}

// MARK: - World View

struct OasisWorldView: View {
    let level: Int
    let activeEffect: String?
    
    var body: some View {
        ZStack {
            // Background Color Transition
            LinearGradient(
                colors: backgroundColorForLevel(level),
                startPoint: .top,
                endPoint: .bottom
            )
            .animation(.easeInOut(duration: 4.0), value: level)
            
            GeometryReader { geo in
                ZStack {
                    // Sunset effect
                    if level > 2 || activeEffect == "sunset" {
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 400, height: 400)
                            .position(x: geo.size.width * 0.8, y: geo.size.height * 0.2)
                            .blur(radius: 80)
                            .transition(.opacity)
                    }

                    // Creek
                    if level > 0 || activeEffect == "creek" {
                        WatercolorPath(points: [
                            CGPoint(x: 0, y: geo.size.height * 0.75),
                            CGPoint(x: geo.size.width * 0.3, y: geo.size.height * 0.7),
                            CGPoint(x: geo.size.width * 0.7, y: geo.size.height * 0.8),
                            CGPoint(x: geo.size.width, y: geo.size.height * 0.75)
                        ])
                        .fill(Color.blue.opacity(0.25))
                        .blur(radius: 10)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    // Tree
                    if level > 1 || activeEffect == "tree" {
                        TreeShape()
                            .fill(Color.green.opacity(0.35))
                            .blur(radius: 12)
                            .frame(width: 250, height: 400)
                            .position(x: geo.size.width * 0.2, y: geo.size.height * 0.55)
                            .transition(.scale(scale: 0.1).combined(with: .opacity))
                    }
                    
                    // Rainbow
                    if level > 7 || activeEffect == "rainbow" {
                        RainbowView()
                            .position(x: geo.size.width * 0.5, y: geo.size.height * 0.4)
                            .transition(.opacity)
                    }
                    
                    // Birds
                    if level > 6 || activeEffect == "birds" {
                        BirdsView(size: geo.size)
                    }
                    
                    // Fireflies
                    if level > 8 || activeEffect == "fireflies" {
                        FirefliesView()
                    }
                }
            }
            
            // Atmospheric Fog
            FogView(level: level, activeEffect: activeEffect)
        }
    }
    
    private func backgroundColorForLevel(_ level: Int) -> [Color] {
        if level == 0 {
            return [Color(white: 0.95), Color(white: 0.85)]
        } else if level < 5 {
            return [Color.blue.opacity(0.15), Color.green.opacity(0.15)]
        } else {
            return [Color.blue.opacity(0.25), Color.orange.opacity(0.2)]
        }
    }
}

// MARK: - Specialized Shapes & Views

struct WatercolorPath: Shape {
    let points: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

struct TreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Foliage
        path.addEllipse(in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height * 0.8))
        // Trunk
        path.addRect(CGRect(x: rect.midX - 15, y: rect.height * 0.7, width: 30, height: rect.height * 0.3))
        return path
    }
}

struct RainbowView: View {
    var body: some View {
        ZStack {
            ForEach(0..<7) { i in
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(
                        AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], center: .center),
                        lineWidth: 4
                    )
                    .frame(width: 200 + Double(i * 10), height: 200 + Double(i * 10))
                    .opacity(0.15)
                    .blur(radius: 2)
            }
        }
    }
}

struct FirefliesView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<15 {
                    let x = size.width * (0.5 + 0.35 * sin(time * 0.5 + Double(i) * 1.5))
                    let y = size.height * (0.6 + 0.25 * cos(time * 0.7 + Double(i) * 2.1))
                    
                    let opacity = 0.3 + 0.4 * sin(time * 2.0 + Double(i))
                    context.fill(Circle().path(in: CGRect(x: x, y: y, width: 4, height: 4)), with: .color(.yellow.opacity(opacity)))
                    context.addFilter(.blur(radius: 2))
                }
            }
        }
    }
}

struct BirdsView: View {
    let size: CGSize
    var body: some View {
        ForEach(0..<4) { i in
            Image(systemName: "bird.fill")
                .font(.system(size: 14))
                .foregroundStyle(.black.opacity(0.2))
                .position(x: size.width * (0.7 + 0.05 * Double(i)), y: size.height * (0.3 + 0.03 * Double(i)))
                .offset(y: 5 * sin(Date().timeIntervalSinceReferenceDate + Double(i)))
        }
    }
}

struct FogView: View {
    let level: Int
    let activeEffect: String?
    
    var body: some View {
        ZStack {
            if level < 5 && activeEffect != "clearSky" {
                Color.white.opacity(0.45)
                    .blur(radius: 60)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 5.0), value: level)
            }
        }
    }
}
