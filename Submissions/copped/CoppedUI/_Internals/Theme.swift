import SwiftUI
import UIKit

// MARK: - Theme

public struct Theme: Initializable, Updatable, Equatable {
  public var colors: Palette = .init()
  public var layout: Layout = .init()
  public init() {}
}

extension Theme {
  public static let didChangeThemeNotification = Notification.Name("didChangeThemeNotification")

  public static var current = Self() {
    didSet {
      NotificationCenter.default.post(name: Self.didChangeThemeNotification, object: nil)
    }
  }
}

// MARK: - Theme.Layout

extension Theme {
  public struct Layout: Initializable, Updatable, Equatable {

    public struct Radius: Equatable {
      public var small: CGFloat
      public var medium: CGFloat
      public var large: CGFloat
      public init(small: CGFloat, medium: CGFloat, large: CGFloat) {
        self.small = small; self.medium = medium; self.large = large
      }
    }

    public struct BorderWidth: Equatable {
      public var small: CGFloat
      public var medium: CGFloat
      public var large: CGFloat
      public init(small: CGFloat, medium: CGFloat, large: CGFloat) {
        self.small = small; self.medium = medium; self.large = large
      }
    }

    public struct AnimationScale: Equatable {
      public var small: CGFloat
      public var medium: CGFloat
      public var large: CGFloat
      public init(small: CGFloat, medium: CGFloat, large: CGFloat) {
        guard small >= 0 && small <= 1.0,
              medium >= 0 && medium <= 1.0,
              large >= 0 && large <= 1.0 else {
          fatalError("Animation scale values must be between 0 and 1")
        }
        self.small = small; self.medium = medium; self.large = large
      }
    }

    public struct ShadowParams: Equatable {
      public var radius: CGFloat
      public var offset: CGSize
      public var color: UniversalColor
      public init(radius: CGFloat, offset: CGSize, color: UniversalColor) {
        self.radius = radius; self.offset = offset; self.color = color
      }
    }

    public struct Shadow: Equatable {
      public var small: ShadowParams
      public var medium: ShadowParams
      public var large: ShadowParams
      public init(small: ShadowParams, medium: ShadowParams, large: ShadowParams) {
        self.small = small; self.medium = medium; self.large = large
      }
    }

    public struct FontSet: Equatable {
      public var small: UniversalFont
      public var medium: UniversalFont
      public var large: UniversalFont
      public init(small: UniversalFont, medium: UniversalFont, large: UniversalFont) {
        self.small = small; self.medium = medium; self.large = large
      }
    }

    public struct Typography: Equatable {
      public var headline: FontSet
      public var body: FontSet
      public var button: FontSet
      public var caption: FontSet
      public init(headline: FontSet, body: FontSet, button: FontSet, caption: FontSet) {
        self.headline = headline; self.body = body; self.button = button; self.caption = caption
      }
    }

    // MARK: Glass Surface Tokens

    public struct Glass: Equatable {
      public var blurStyle: UIBlurEffect.Style
      public var tint: Color
      public var border: Color
      public var borderWidth: CGFloat
      public var shadowColor: Color
      public var shadowRadius: CGFloat
      public var shadowOffset: CGSize

      public init(
        blurStyle: UIBlurEffect.Style = .systemUltraThinMaterialDark,
        tint: Color = .white.opacity(0.06),
        border: Color = .white.opacity(0.15),
        borderWidth: CGFloat = 0.5,
        shadowColor: Color = .clear,
        shadowRadius: CGFloat = 0,
        shadowOffset: CGSize = .zero
      ) {
        self.blurStyle = blurStyle
        self.tint = tint
        self.border = border
        self.borderWidth = borderWidth
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
      }

      // MARK: Presets

      /// Standard glass for cards, modals, expandable cards.
      public static var standard: Self { .init() }

      /// Subtle glass for floating tab bars — lighter tint and border.
      public static var subtle: Self {
        .init(
          tint: .white.opacity(0.04),
          border: .white.opacity(0.12)
        )
      }

      /// Prominent glass for menu bars, action buttons — stronger tint and border.
      public static var prominent: Self {
        .init(
          tint: .white.opacity(0.125),
          border: .white.opacity(0.20)
        )
      }

      /// Shadow modifier values as a tuple for easy application.
      public var shadowParams: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (shadowColor, shadowRadius, shadowOffset.width, shadowOffset.height)
      }
    }

    // MARK: Overlay Tokens

    public struct Overlay: Equatable {
      /// Opacity for modal dimmed overlays (default 0.7)
      public var dim: CGFloat
      /// Opacity for HUD/blocking overlays (default 0.5)
      public var hudDim: CGFloat
      /// Opacity for inactive/secondary text and icons (default 0.5)
      public var inactiveContent: CGFloat
      /// Opacity for dividers (default 0.1)
      public var divider: CGFloat

      public init(
        dim: CGFloat = 0.5,
        hudDim: CGFloat = 0.4,
        inactiveContent: CGFloat = 0.5,
        divider: CGFloat = 0.1
      ) {
        self.dim = dim
        self.hudDim = hudDim
        self.inactiveContent = inactiveContent
        self.divider = divider
      }
    }

    // MARK: Motion Tokens

    public struct SpringParams: Equatable {
      public var response: CGFloat
      public var dampingFraction: CGFloat

      public init(response: CGFloat, dampingFraction: CGFloat) {
        self.response = response
        self.dampingFraction = dampingFraction
      }

      public var animation: Animation {
        .spring(response: response, dampingFraction: dampingFraction)
      }
    }

    public struct Motion: Equatable {
      /// Snappy spring for selection changes (tabs, toggles)
      public var snappy: SpringParams
      /// Smooth spring for expanding/collapsing content
      public var smooth: SpringParams
      /// Duration for quick fades (HUD, overlays)
      public var fadeDuration: TimeInterval

      public init(
        snappy: SpringParams = .init(response: 0.3, dampingFraction: 0.7),
        smooth: SpringParams = .init(response: 0.45, dampingFraction: 0.8),
        fadeDuration: TimeInterval = 0.2
      ) {
        self.snappy = snappy
        self.smooth = smooth
        self.fadeDuration = fadeDuration
      }
    }

    // MARK: Properties

    public var glass: Glass = .init()
    public var overlay: Overlay = .init()
    public var motion: Motion = .init()

    public var disabledOpacity: CGFloat = 0.5

    public var componentRadius: Radius = .init(small: 10.0, medium: 12.0, large: 16.0)
    public var containerRadius: Radius = .init(small: 16.0, medium: 20.0, large: 26.0)

    public var shadow: Shadow = .init(
      small:  .init(radius: 0, offset: .zero, color: .universal(.rgba(r: 0, g: 0, b: 0, a: 0))),
      medium: .init(radius: 0, offset: .zero, color: .universal(.rgba(r: 0, g: 0, b: 0, a: 0))),
      large:  .init(radius: 0, offset: .zero, color: .universal(.rgba(r: 0, g: 0, b: 0, a: 0)))
    )

    public var borderWidth: BorderWidth = .init(small: 0.5, medium: 1.0, large: 2.0)

    public var animationScale: AnimationScale = .init(small: 0.99, medium: 0.98, large: 0.95)

    /// Default typography — overridden by Foundation/Typography.swift at app launch.
    public var typography: Typography = .init(
      headline: .init(
        small:  .system(size: 14, weight: .semibold),
        medium: .system(size: 20, weight: .semibold),
        large:  .system(size: 24, weight: .semibold)
      ),
      body: .init(
        small:  .system(size: 14, weight: .regular),
        medium: .system(size: 16, weight: .regular),
        large:  .system(size: 18, weight: .regular)
      ),
      button: .init(
        small:  .system(size: 14, weight: .medium),
        medium: .system(size: 16, weight: .medium),
        large:  .system(size: 20, weight: .medium)
      ),
      caption: .init(
        small:  .system(size: 10, weight: .regular),
        medium: .system(size: 12, weight: .regular),
        large:  .system(size: 14, weight: .regular)
      )
    )

    public init() {}
  }
}

// MARK: - Theme.Palette

extension Theme {
  public struct Palette: Initializable, Updatable, Equatable {
    public var background: UniversalColor           = .themed(light: .hex("#FFFFFF"), dark: .hex("#000000"))
    public var secondaryBackground: UniversalColor  = .themed(light: .hex("#F5F5F5"), dark: .hex("#323335"))
    public var foreground: UniversalColor           = .themed(light: .hex("#0B0C0E"), dark: .hex("#FFFFFF"))
    public var secondaryForeground: UniversalColor  = .themed(light: .hex("#424355"), dark: .hex("#D6D6D7"))
    public var content1: UniversalColor             = .themed(light: .hex("#EFEFF0"), dark: .hex("#27272a"))
    public var content2: UniversalColor             = .themed(light: .hex("#D4D4D8"), dark: .hex("#3F3F46"))
    public var content3: UniversalColor             = .themed(light: .hex("#B4BDC8"), dark: .hex("#52525b"))
    public var content4: UniversalColor             = .themed(light: .hex("#8C9197"), dark: .hex("#86898B"))
    public var divider: UniversalColor              = .themed(
      light: .rgba(r: 11,  g: 12,  b: 14,  a: 0.12),
      dark:  .rgba(r: 255, g: 255, b: 255, a: 0.15)
    )
    public var primary: ComponentColor = .init(
      main:     .themed(light: .hex("#0B0C0E"), dark: .hex("#FFFFFF")),
      contrast: .themed(light: .hex("#FFFFFF"), dark: .hex("#0B0C0E")),
      background: .themed(light: .hex("#D9D9D9"), dark: .hex("#515253"))
    )
    public var accent: ComponentColor = .init(
      main:       .universal(.hex("#007AFF")),
      contrast:   .universal(.hex("#FFFFFF")),
      background: .themed(light: .hex("#E1EEFE"), dark: .hex("#2B3E53"))
    )
    public var success: ComponentColor = .init(
      main:       .themed(light: .hex("#37D45C"), dark: .hex("#1EC645")),
      contrast:   .themed(light: .hex("#FFFFFF"), dark: .hex("#0B0C0E")),
      background: .themed(light: .hex("#E1FBE7"), dark: .hex("#344B3C"))
    )
    public var warning: ComponentColor = .init(
      main:       .themed(light: .hex("#F4B300"), dark: .hex("#F4B300")),
      contrast:   .universal(.hex("#0B0C0E")),
      background: .themed(light: .hex("#FFF6DD"), dark: .hex("#514A35"))
    )
    public var danger: ComponentColor = .init(
      main:       .themed(light: .hex("#F03E53"), dark: .hex("#D22338")),
      contrast:   .universal(.hex("#FFFFFF")),
      background: .themed(light: .hex("#FFE5E8"), dark: .hex("#4F353A"))
    )
    public init() {}
  }
}

// MARK: - ComponentColor

public struct ComponentColor: Hashable {
  public let main: UniversalColor
  public let contrast: UniversalColor
  public var background: UniversalColor {
    return _background ?? main.withOpacity(0.15).blended(with: .background)
  }
  private let _background: UniversalColor?

  public init(main: UniversalColor, contrast: UniversalColor, background: UniversalColor? = nil) {
    self.main = main; self.contrast = contrast; self._background = background
  }
}

extension ComponentColor {
  public static var primary: Self { Theme.current.colors.primary }
  public static var accent:  Self { Theme.current.colors.accent }
  public static var success: Self { Theme.current.colors.success }
  public static var warning: Self { Theme.current.colors.warning }
  public static var danger:  Self { Theme.current.colors.danger }
}

// MARK: - UniversalColor Static Palette

extension UniversalColor {
  public static var black: Self { .universal(.hex("#000000")) }
  public static var white: Self { .universal(.hex("#FFFFFF")) }
  public static var clear: Self { .universal(.uiColor(.clear)) }

  public static var background:          Self { Theme.current.colors.background }
  public static var secondaryBackground: Self { Theme.current.colors.secondaryBackground }
  public static var foreground:          Self { Theme.current.colors.foreground }
  public static var secondaryForeground: Self { Theme.current.colors.secondaryForeground }
  public static var divider:             Self { Theme.current.colors.divider }
  public static var content1:            Self { Theme.current.colors.content1 }
  public static var content2:            Self { Theme.current.colors.content2 }
  public static var content3:            Self { Theme.current.colors.content3 }
  public static var content4:            Self { Theme.current.colors.content4 }

  public static var primary:           Self { Theme.current.colors.primary.main }
  public static var primaryBackground: Self { Theme.current.colors.primary.background }
  public static var primaryContrast:   Self { Theme.current.colors.primary.contrast }

  public static var accent:           Self { Theme.current.colors.accent.main }
  public static var accentBackground: Self { Theme.current.colors.accent.background }
  public static var accentContrast:   Self { Theme.current.colors.accent.contrast }

  public static var success:           Self { Theme.current.colors.success.main }
  public static var successBackground: Self { Theme.current.colors.success.background }
  public static var successContrast:   Self { Theme.current.colors.success.contrast }

  public static var warning:           Self { Theme.current.colors.warning.main }
  public static var warningBackground: Self { Theme.current.colors.warning.background }
  public static var warningContrast:   Self { Theme.current.colors.warning.contrast }

  public static var danger:           Self { Theme.current.colors.danger.main }
  public static var dangerBackground: Self { Theme.current.colors.danger.background }
  public static var dangerContrast:   Self { Theme.current.colors.danger.contrast }
}
