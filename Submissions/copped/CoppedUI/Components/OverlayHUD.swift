import SwiftUI

// MARK: - OverlayHUD

/// Full-screen blocking overlay with optional message.
/// Shows a glass card with a spinner and label.
/// Use `.overlayHUD(isPresented:message:)` view modifier.
public struct OverlayHUD: View {
  var message: String?
  var blurStyle: UIBlurEffect.Style = Theme.current.layout.glass.blurStyle
  var useLiquidGlass: Bool = false
  var onTap: (() -> Void)? = nil

  public init(message: String? = nil, useLiquidGlass: Bool = false, onTap: (() -> Void)? = nil) {
    self.message = message
    self.useLiquidGlass = useLiquidGlass
    self.onTap = onTap
  }

  public var body: some View {
    ZStack {
      // Dimmed background
      Color.black.opacity(Theme.current.layout.overlay.hudDim)
        .ignoresSafeArea()

      // HUD card
      VStack(spacing: 16) {
        SULoading(model: LoadingVM {
          $0.color = .accent
          $0.size = .medium
        })

        if let message {
          Text(message)
            .font(.custom(Manrope.medium, size: 14))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
        }
      }
      .padding(28)
      .liquidGlass(
        enabled: useLiquidGlass,
        cornerRadius: 20,
        blurStyle: blurStyle
      )
      .onTapGesture { onTap?() }
    }
  }
}

// MARK: - View Modifier

extension View {
  /// Presents a full-screen blocking HUD overlay.
  ///
  /// ```swift
  /// ContentView()
  ///   .overlayHUD(isPresented: $isLoading, message: "Loading...")
  /// ```
  public func overlayHUD(isPresented: Binding<Bool>, message: String? = nil, useLiquidGlass: Bool = false, onTap: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) -> some View {
    ZStack {
      self
      if isPresented.wrappedValue {
        OverlayHUD(message: message, useLiquidGlass: useLiquidGlass, onTap: onTap)
          .transition(.opacity)
          .zIndex(999)
      }
    }
    .animation(.easeInOut(duration: Theme.current.layout.motion.fadeDuration), value: isPresented.wrappedValue)
    .onChange(of: isPresented.wrappedValue) { newValue in
      if !newValue { onDismiss?() }
    }
  }
}
