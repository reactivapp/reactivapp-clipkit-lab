import SwiftUI
import UIKit

/// A structure that represents a universal color for both UIKit and SwiftUI,
/// with light and dark theme variants.
public struct UniversalColor: Hashable {

  // MARK: - ColorRepresentable

  public enum ColorRepresentable: Hashable {
    case rgba(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)
    case uiColor(UIColor)
    case color(Color)

    public static func hex(_ value: String) -> Self {
      let start: String.Index
      if value.hasPrefix("#") {
        start = value.index(value.startIndex, offsetBy: 1)
      } else {
        start = value.startIndex
      }
      let hexColor = String(value[start...])
      let scanner = Scanner(string: hexColor)
      var hexNumber: UInt64 = 0
      if hexColor.count == 6 && scanner.scanHexInt64(&hexNumber) {
        let r = CGFloat((hexNumber & 0x00ff0000) >> 16)
        let g = CGFloat((hexNumber & 0x0000ff00) >> 8)
        let b = CGFloat(hexNumber & 0x000000ff)
        return .rgba(r: r, g: g, b: b, a: 1.0)
      } else {
        assertionFailure("Unable to initialize color from hex: \(value)")
        return .rgba(r: 0, g: 0, b: 0, a: 1.0)
      }
    }

    fileprivate func withOpacity(_ alpha: CGFloat) -> Self {
      switch self {
      case .rgba(let r, let g, let b, _):
        return .rgba(r: r, g: g, b: b, a: alpha)
      case .uiColor(let uiColor):
        return .uiColor(uiColor.withAlphaComponent(alpha))
      case .color(let color):
        return .color(color.opacity(alpha))
      }
    }

    fileprivate var uiColor: UIColor {
      switch self {
      case .rgba(let red, let green, let blue, let alpha):
        return UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
      case .uiColor(let uiColor):
        return uiColor
      case .color(let color):
        return UIColor(color)
      }
    }

    private var rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
      switch self {
      case let .rgba(r, g, b, a):
        return (r, g, b, a)
      case .uiColor, .color:
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red * 255, green * 255, blue * 255, alpha)
      }
    }

    fileprivate func blended(with other: Self) -> Self {
      let rgba = self.rgba
      let otherRgba = other.rgba
      let red   = rgba.r * rgba.a + otherRgba.r * (1.0 - rgba.a)
      let green = rgba.g * rgba.a + otherRgba.g * (1.0 - rgba.a)
      let blue  = rgba.b * rgba.a + otherRgba.b * (1.0 - rgba.a)
      return .rgba(r: red, g: green, b: blue, a: 1.0)
    }
  }

  // MARK: - Properties

  public let light: ColorRepresentable
  public let dark: ColorRepresentable

  // MARK: - Factory

  public static func themed(light: ColorRepresentable, dark: ColorRepresentable) -> Self {
    return Self(light: light, dark: dark)
  }

  public static func universal(_ universal: ColorRepresentable) -> Self {
    return Self(light: universal, dark: universal)
  }

  // MARK: - Conversions

  public var uiColor: UIColor {
    return UIColor { trait in
      switch trait.userInterfaceStyle {
      case .dark:
        return self.dark.uiColor
      default:
        return self.light.uiColor
      }
    }
  }

  public var color: Color {
    return Color(self.uiColor)
  }

  public var cgColor: CGColor {
    return self.uiColor.cgColor
  }

  // MARK: - Methods

  public func withOpacity(_ alpha: CGFloat) -> Self {
    return .init(light: self.light.withOpacity(alpha), dark: self.dark.withOpacity(alpha))
  }

  public func enabled(_ isEnabled: Bool) -> Self {
    return isEnabled ? self : self.withOpacity(Theme.current.layout.disabledOpacity)
  }

  public func blended(with other: Self) -> Self {
    return .init(
      light: self.light.blended(with: other.light),
      dark: self.dark.blended(with: other.dark)
    )
  }
}
