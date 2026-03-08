import SwiftUI

// MARK: - ExpandableCard

/// A glass-effect card that expands from a compact preview to a full detail view.
/// Uses matched geometry + spring animation for a fluid expand/collapse.
public struct ExpandableCard<Preview: View, Detail: View>: View {
  @Binding var isExpanded: Bool
  let preview: () -> Preview
  let detail: () -> Detail
  var onExpandChange: ((Bool) -> Void)?

  /// Corner radius for collapsed state.
  var cornerRadius: CGFloat = 24
  /// Background blur style.
  var blurStyle: UIBlurEffect.Style = Theme.current.layout.glass.blurStyle
  /// Background tint on top of blur.
  var tint: Color = Theme.current.layout.glass.tint
  /// Border color.
  var borderColor: Color = Theme.current.layout.glass.border
  /// Border width.
  var borderWidth: CGFloat = Theme.current.layout.glass.borderWidth
  /// Collapsed card height. `nil` lets the preview size naturally.
  var collapsedHeight: CGFloat? = nil
  var useLiquidGlass: Bool = false

  public init(
    isExpanded: Binding<Bool>,
    cornerRadius: CGFloat = 24,
    blurStyle: UIBlurEffect.Style = Theme.current.layout.glass.blurStyle,
    tint: Color = Theme.current.layout.glass.tint,
    borderColor: Color = Theme.current.layout.glass.border,
    borderWidth: CGFloat = Theme.current.layout.glass.borderWidth,
    collapsedHeight: CGFloat? = nil,
    useLiquidGlass: Bool = false,
    onExpandChange: ((Bool) -> Void)? = nil,
    @ViewBuilder preview: @escaping () -> Preview,
    @ViewBuilder detail: @escaping () -> Detail
  ) {
    self._isExpanded = isExpanded
    self.cornerRadius = cornerRadius
    self.blurStyle = blurStyle
    self.tint = tint
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.collapsedHeight = collapsedHeight
    self.useLiquidGlass = useLiquidGlass
    self.onExpandChange = onExpandChange
    self.preview = preview
    self.detail = detail
  }

  public var body: some View {
    VStack(spacing: 0) {
      // Preview is always visible
      preview()
        .frame(height: collapsedHeight)
        .frame(maxWidth: .infinity)
        .clipped()

      // Detail slides in when expanded
      if isExpanded {
        detail()
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .liquidGlass(
      enabled: useLiquidGlass,
      cornerRadius: cornerRadius,
      blurStyle: blurStyle,
      tint: tint,
      borderColor: borderColor,
      borderWidth: borderWidth
    )
    .shadow(
      color: Theme.current.layout.glass.shadowColor,
      radius: Theme.current.layout.glass.shadowRadius,
      x: Theme.current.layout.glass.shadowOffset.width,
      y: Theme.current.layout.glass.shadowOffset.height
    )
    .onTapGesture {
      let newValue = !isExpanded
      onExpandChange?(newValue)
      withAnimation(Theme.current.layout.motion.smooth.animation) {
        isExpanded.toggle()
      }
    }
    .animation(Theme.current.layout.motion.smooth.animation, value: isExpanded)
  }
}

// MARK: - GlassCard

/// Standalone frosted-glass card. Use directly when you don't need expand/collapse.
public struct GlassCard<Content: View>: View {
  let content: () -> Content
  var cornerRadius: CGFloat = 24
  var blurStyle: UIBlurEffect.Style = Theme.current.layout.glass.blurStyle
  var tint: Color = Theme.current.layout.glass.tint
  var borderColor: Color = Theme.current.layout.glass.border
  var borderWidth: CGFloat = Theme.current.layout.glass.borderWidth

  var useLiquidGlass: Bool = false

  public init(
    cornerRadius: CGFloat = 24,
    blurStyle: UIBlurEffect.Style = Theme.current.layout.glass.blurStyle,
    tint: Color = Theme.current.layout.glass.tint,
    borderColor: Color = Theme.current.layout.glass.border,
    borderWidth: CGFloat = Theme.current.layout.glass.borderWidth,
    useLiquidGlass: Bool = false,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.cornerRadius = cornerRadius
    self.blurStyle = blurStyle
    self.tint = tint
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.useLiquidGlass = useLiquidGlass
    self.content = content
  }

  public var body: some View {
    content()
      .liquidGlass(
        enabled: useLiquidGlass,
        cornerRadius: cornerRadius,
        blurStyle: blurStyle,
        tint: tint,
        borderColor: borderColor,
        borderWidth: borderWidth
      )
  }
}

// MARK: - GlassBackground

/// UIKit blur view wrapped for SwiftUI.
public struct GlassBackground: UIViewRepresentable {
  let style: UIBlurEffect.Style
  let tint: Color
  let cornerRadius: CGFloat

  public init(
    style: UIBlurEffect.Style = Theme.current.layout.glass.blurStyle,
    tint: Color = Theme.current.layout.glass.tint,
    cornerRadius: CGFloat = 20
  ) {
    self.style = style
    self.tint = tint
    self.cornerRadius = cornerRadius
  }

  public func makeUIView(context: Context) -> UIVisualEffectView {
    let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
    view.clipsToBounds = true
    view.layer.cornerRadius = cornerRadius
    view.layer.cornerCurve = .continuous

    // Tint overlay
    let tintView = UIView()
    tintView.backgroundColor = UIColor(tint)
    tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.contentView.addSubview(tintView)

    return view
  }

  public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
    uiView.effect = UIBlurEffect(style: style)
    uiView.layer.cornerRadius = cornerRadius
  }
}
