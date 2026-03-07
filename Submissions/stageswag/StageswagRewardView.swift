import SwiftUI

struct StageswagRewardView: View {
    let theme: StageswagTheme

    @State private var appeared = false
    @State private var downloaded = false
    @State private var isPlaying = false
    @State private var playbackProgress: CGFloat = 0.0
    @State private var email = ""
    @State private var emailSent = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var playbackTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                stageswagSuccessIcon

                ClipHeader(
                    title: "Order Confirmed!",
                    subtitle: "Pick up at the merch booth after the show"
                )

                stageswagRewardCard

                stageswagEmailSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
    }

    private var stageswagSuccessIcon: some View {
        ZStack {
            Circle()
                .fill(theme.accentColor.opacity(0.15))
                .frame(width: 100, height: 100)
                .scaleEffect(pulseScale)

            Image(systemName: "music.note")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(theme.accentColor)
                .scaleEffect(appeared ? 1.0 : 0.3)
                .opacity(appeared ? 1.0 : 0.0)
        }
    }

    private var stageswagRewardCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 4) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("EXCLUSIVE REWARD")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
            }
            .foregroundStyle(theme.accentColor)

            VStack(spacing: 6) {
                Text("Unreleased Track")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                Text("Aftershock (Acoustic)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .leading) {
                Image(systemName: "waveform")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(theme.textHighlight.opacity(0.2))
                    .frame(maxWidth: .infinity)

                Image(systemName: "waveform")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(isPlaying ? theme.accentColor : theme.textHighlight.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .mask(alignment: .leading) {
                        GeometryReader { geo in
                            Rectangle()
                                .frame(width: geo.size.width * playbackProgress)
                        }
                    }
            }
            .padding(.vertical, 4)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.textHighlight.opacity(0.15))
                        .frame(height: 4)
                    Capsule()
                        .fill(theme.accentColor)
                        .frame(width: geo.size.width * playbackProgress, height: 4)
                }
            }
            .frame(height: 4)

            HStack {
                Text(stageswagFormatTime(playbackProgress * 198))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("3:18")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 28) {
                Button {
                    stageswagSkipBackward()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(theme.textHighlight)
                }

                Button {
                    stageswagTogglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(theme.accentColor)
                        .contentTransition(.symbolEffect(.replace))
                }

                Button {
                    stageswagSkipForward()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(theme.textHighlight)
                }
            }
            .padding(.vertical, 4)

            HStack(spacing: 10) {
                Button {
                    stageswagTogglePlayback()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPlaying ? "pause.fill" : "headphones")
                            .font(.system(size: 14, weight: .semibold))
                            .contentTransition(.symbolEffect(.replace))
                        Text(isPlaying ? "Pause" : "Listen")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(theme.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.accentColor.opacity(0.15), in: Capsule())
                    .overlay(Capsule().strokeBorder(theme.accentColor.opacity(0.3), lineWidth: 1))
                }

                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        downloaded = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: downloaded ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .contentTransition(.symbolEffect(.replace))
                        Text(downloaded ? "Saved" : "Download")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(downloaded ? Color.green : theme.accentColor, in: Capsule())
                }
                .disabled(downloaded)
            }
        }
        .padding(20)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
        .onDisappear {
            playbackTimer?.invalidate()
        }
    }

    private func stageswagTogglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if playbackProgress < 1.0 {
                    playbackProgress += 0.0005
                } else {
                    isPlaying = false
                    playbackTimer?.invalidate()
                }
            }
        } else {
            playbackTimer?.invalidate()
        }
    }

    private func stageswagSkipBackward() {
        withAnimation(.easeInOut(duration: 0.2)) {
            playbackProgress = max(0, playbackProgress - 0.05)
        }
    }

    private func stageswagSkipForward() {
        withAnimation(.easeInOut(duration: 0.2)) {
            playbackProgress = min(1.0, playbackProgress + 0.05)
        }
    }

    private func stageswagFormatTime(_ seconds: CGFloat) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var stageswagEmailSection: some View {
        VStack(spacing: 12) {
            if emailSent {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.badge.fill")
                        .foregroundStyle(.green)
                    Text("Check your inbox!")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
                .transition(.scale.combined(with: .opacity))
            } else {
                TextField("Email address", text: $email)
                    .font(.system(size: 15))
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))

                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        emailSent = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Send Me the Link")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        email.isEmpty ? Color.gray.opacity(0.4) : theme.secondaryAccent,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .disabled(email.isEmpty)
            }
        }
        .animation(.spring(duration: 0.3), value: emailSent)
    }
}
