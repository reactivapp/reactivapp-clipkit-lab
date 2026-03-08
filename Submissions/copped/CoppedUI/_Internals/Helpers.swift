import SwiftUI
import UIKit

// MARK: - Collection

extension Collection {
  var isNotEmpty: Bool { !self.isEmpty }
}

// MARK: - Optional

extension Optional {
  var isNil: Bool { self == nil }
  var isNotNil: Bool { self != nil }
}

extension Optional where Wrapped: Collection {
  var isNotNilAndEmpty: Bool {
    if let self { return self.isNotEmpty } else { return false }
  }
  var isNilOrEmpty: Bool {
    if let self { return self.isEmpty } else { return true }
  }
}

// MARK: - Array

extension Array {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

// MARK: - View: Size Observer

extension View {
  func observeSize(_ closure: @escaping (_ size: CGSize) -> Void) -> some View {
    self.overlay(
      GeometryReader { geometry in
        Color.clear
          .onAppear { closure(geometry.size) }
          .onChange(of: geometry.size) { newValue in closure(newValue) }
      }
    )
  }
}

// MARK: - View: Liquid Glass

extension View {
  /// Applies either native Liquid Glass (iOS 26+, when `useLiquidGlass` is true)
  /// or the classic `GlassBackground` with clip + stroke.
  func liquidGlass(
    enabled: Bool = false,
    cornerRadius: CGFloat = 20,
    blurStyle: UIBlurEffect.Style = Theme.current.layout.glass.blurStyle,
    tint: Color = Theme.current.layout.glass.tint,
    borderColor: Color = Theme.current.layout.glass.border,
    borderWidth: CGFloat = Theme.current.layout.glass.borderWidth,
    useCapsule: Bool = false,
    accentColor: Color? = nil
  ) -> some View {
    let resolvedTint = accentColor?.opacity(0.15) ?? tint
    let resolvedBorder = accentColor?.opacity(0.3) ?? borderColor
    return _liquidGlassBody(
      enabled: enabled, cornerRadius: cornerRadius,
      blurStyle: blurStyle, tint: resolvedTint,
      borderColor: resolvedBorder, borderWidth: borderWidth,
      useCapsule: useCapsule, accentColor: accentColor
    )
  }

  @available(iOS 26.0, *)
  @ViewBuilder
  private func _nativeGlass(
    cornerRadius: CGFloat,
    useCapsule: Bool,
    accentColor: Color?
  ) -> some View {
    if let accentColor {
      if useCapsule {
        self.glassEffect(.regular.interactive().tint(accentColor), in: .capsule)
          .shadow(color: .clear, radius: 0)
      } else {
        self.glassEffect(.regular.interactive().tint(accentColor), in: .rect(cornerRadius: cornerRadius))
          .shadow(color: .clear, radius: 0)
      }
    } else {
      if useCapsule {
        self.glassEffect(.regular.interactive(), in: .capsule)
          .shadow(color: .clear, radius: 0)
      } else {
        self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
          .shadow(color: .clear, radius: 0)
      }
    }
  }

  @ViewBuilder
  private func _liquidGlassBody(
    enabled: Bool,
    cornerRadius: CGFloat,
    blurStyle: UIBlurEffect.Style,
    tint: Color,
    borderColor: Color,
    borderWidth: CGFloat,
    useCapsule: Bool,
    accentColor: Color?
  ) -> some View {
    if enabled, #available(iOS 26.0, *) {
      _nativeGlass(cornerRadius: cornerRadius, useCapsule: useCapsule, accentColor: accentColor)
    } else {
      _classicGlass(cornerRadius: cornerRadius, blurStyle: blurStyle, tint: tint,
                    borderColor: borderColor, borderWidth: borderWidth, useCapsule: useCapsule)
    }
  }

  @ViewBuilder
  private func _classicGlass(
    cornerRadius: CGFloat,
    blurStyle: UIBlurEffect.Style,
    tint: Color,
    borderColor: Color,
    borderWidth: CGFloat,
    useCapsule: Bool
  ) -> some View {
    if useCapsule {
      self
        .background(GlassBackground(style: blurStyle, tint: tint, cornerRadius: 999))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(borderColor, lineWidth: borderWidth))
    } else {
      self
        .background(GlassBackground(style: blurStyle, tint: tint, cornerRadius: cornerRadius))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(borderColor, lineWidth: borderWidth)
        )
    }
  }
}

// MARK: - View: Transparent Presentation Background

struct TransparentBackground: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    DispatchQueue.main.async {
      view.superview?.superview?.backgroundColor = .clear
    }
    return view
  }
  func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
  @ViewBuilder
  func transparentPresentationBackground() -> some View {
    if #available(iOS 16.4, *) {
      self.presentationBackground(.clear)
    } else {
      self.background(TransparentBackground())
    }
  }

  @ViewBuilder
  func disableScrollWhenContentFits() -> some View {
    if #available(iOS 16.4, *) {
      self.scrollBounceBehavior(.basedOnSize)
    } else {
      self.onAppear {
        UIScrollView.appearance().bounces = false
      }
    }
  }
}
