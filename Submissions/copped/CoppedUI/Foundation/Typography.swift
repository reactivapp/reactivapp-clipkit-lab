import SwiftUI

// MARK: - Manrope Font Names

/// All Manrope weights. Bundle the .ttf files in your app target under these names.
public enum Manrope {
  public static let extraLight = "Manrope-ExtraLight"  // 200
  public static let light      = "Manrope-Light"       // 300
  public static let regular    = "Manrope-Regular"     // 400
  public static let medium     = "Manrope-Medium"      // 500
  public static let semiBold   = "Manrope-SemiBold"    // 600
  public static let bold       = "Manrope-Bold"        // 700
  public static let extraBold  = "Manrope-ExtraBold"   // 800
}

// MARK: - Manrope Type Scale (semantic)

public extension UniversalFont {
  // Display — hero titles
  static var display: UniversalFont   { .custom(name: Manrope.extraBold, size: 34) }

  // Titles
  static var title1: UniversalFont    { .custom(name: Manrope.bold,     size: 28) }
  static var title2: UniversalFont    { .custom(name: Manrope.bold,     size: 22) }
  static var title3: UniversalFont    { .custom(name: Manrope.semiBold, size: 18) }

  // Body
  static var bodyLarge: UniversalFont   { .custom(name: Manrope.regular, size: 18) }
  static var bodyMedium: UniversalFont  { .custom(name: Manrope.regular, size: 16) }
  static var bodySmall: UniversalFont   { .custom(name: Manrope.regular, size: 14) }

  // Labels
  static var labelLarge: UniversalFont  { .custom(name: Manrope.medium, size: 15) }
  static var labelMedium: UniversalFont { .custom(name: Manrope.medium, size: 13) }
  static var labelSmall: UniversalFont  { .custom(name: Manrope.medium, size: 11) }

  // Caption
  static var captionLarge: UniversalFont  { .custom(name: Manrope.regular, size: 13) }
  static var captionMedium: UniversalFont { .custom(name: Manrope.regular, size: 11) }
  static var captionSmall: UniversalFont  { .custom(name: Manrope.regular, size: 10) }

  // Overline / tag
  static var overline: UniversalFont { .custom(name: Manrope.semiBold, size: 10) }
}

// MARK: - Manrope Theme.Layout.Typography preset

extension Theme.Layout.Typography {
  /// Full Manrope typography to apply to the theme.
  static var manrope: Self {
    .init(
      headline: .init(
        small:  .custom(name: Manrope.semiBold, size: 14),
        medium: .custom(name: Manrope.semiBold, size: 20),
        large:  .custom(name: Manrope.bold,     size: 24)
      ),
      body: .init(
        small:  .custom(name: Manrope.regular, size: 14),
        medium: .custom(name: Manrope.regular, size: 16),
        large:  .custom(name: Manrope.regular, size: 18)
      ),
      button: .init(
        small:  .custom(name: Manrope.semiBold, size: 14),
        medium: .custom(name: Manrope.semiBold, size: 16),
        large:  .custom(name: Manrope.semiBold, size: 20)
      ),
      caption: .init(
        small:  .custom(name: Manrope.regular, size: 10),
        medium: .custom(name: Manrope.medium,  size: 12),
        large:  .custom(name: Manrope.medium,  size: 14)
      )
    )
  }
}
