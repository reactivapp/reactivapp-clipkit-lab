import Foundation

// MARK: - Uber-style Color Palette

extension Theme.Palette {
  /// The app palette: black/white base with violet `#7C3AED` accent.
  static var uber: Self {
    var p = Theme.Palette()
    p.accent = ComponentColor(
      main:       .universal(.hex("#7C3AED")),
      contrast:   .universal(.hex("#FFFFFF")),
      background: .themed(light: .hex("#EDE9FE"), dark: .hex("#2E1065"))
    )
    return p
  }
}

// MARK: - App Theme Setup

extension Theme {
  /// Call once at app launch (e.g. in your App init or AppDelegate).
  ///
  /// ```swift
  /// Theme.configureApp()
  /// ```
  public static func configureApp() {
    Theme.current.update {
      $0.layout.typography = .manrope
      $0.colors = .uber
    }
  }
}
