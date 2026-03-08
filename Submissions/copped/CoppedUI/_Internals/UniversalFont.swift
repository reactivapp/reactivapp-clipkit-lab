import SwiftUI
import UIKit

/// A universal font container for both UIKit and SwiftUI.
public enum UniversalFont: Hashable {

  public enum Weight: Hashable {
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
  }

  case custom(name: String, size: CGFloat)
  case system(size: CGFloat, weight: Weight)

  // MARK: - Conversions

  public var uiFont: UIFont {
    switch self {
    case .custom(let name, let size):
      guard let font = UIFont(name: name, size: size) else {
        assertionFailure("Unable to initialize font '\(name)'")
        return UIFont.systemFont(ofSize: size)
      }
      return font
    case .system(let size, let weight):
      return UIFont.systemFont(ofSize: size, weight: weight.uiFontWeight)
    }
  }

  public var font: Font {
    switch self {
    case .custom(let name, let size):
      return Font.custom(name, size: size)
    case .system(let size, let weight):
      return Font.system(size: size, weight: weight.swiftUIFontWeight)
    }
  }

  // MARK: - Helpers

  public func withSize(_ size: CGFloat) -> Self {
    switch self {
    case .custom(let name, _):
      return .custom(name: name, size: size)
    case .system(_, let weight):
      return .system(size: size, weight: weight)
    }
  }

  public func withRelativeSize(_ shift: CGFloat) -> Self {
    switch self {
    case .custom(let name, let size):
      return .custom(name: name, size: size + shift)
    case .system(let size, let weight):
      return .system(size: size + shift, weight: weight)
    }
  }
}

// MARK: - Weight Conversions

extension UniversalFont.Weight {
  var uiFontWeight: UIFont.Weight {
    switch self {
    case .ultraLight: return .ultraLight
    case .thin:       return .thin
    case .light:      return .light
    case .regular:    return .regular
    case .medium:     return .medium
    case .semibold:   return .semibold
    case .bold:       return .bold
    case .heavy:      return .heavy
    case .black:      return .black
    }
  }

  var swiftUIFontWeight: Font.Weight {
    switch self {
    case .ultraLight: return .ultraLight
    case .thin:       return .thin
    case .light:      return .light
    case .regular:    return .regular
    case .medium:     return .medium
    case .semibold:   return .semibold
    case .bold:       return .bold
    case .heavy:      return .heavy
    case .black:      return .black
    }
  }
}

// MARK: - Theme-linked Presets

extension UniversalFont {
  public static var smHeadline: UniversalFont { Theme.current.layout.typography.headline.small }
  public static var mdHeadline: UniversalFont { Theme.current.layout.typography.headline.medium }
  public static var lgHeadline: UniversalFont { Theme.current.layout.typography.headline.large }

  public static var smBody: UniversalFont { Theme.current.layout.typography.body.small }
  public static var mdBody: UniversalFont { Theme.current.layout.typography.body.medium }
  public static var lgBody: UniversalFont { Theme.current.layout.typography.body.large }

  public static var smButton: UniversalFont { Theme.current.layout.typography.button.small }
  public static var mdButton: UniversalFont { Theme.current.layout.typography.button.medium }
  public static var lgButton: UniversalFont { Theme.current.layout.typography.button.large }

  public static var smCaption: UniversalFont { Theme.current.layout.typography.caption.small }
  public static var mdCaption: UniversalFont { Theme.current.layout.typography.caption.medium }
  public static var lgCaption: UniversalFont { Theme.current.layout.typography.caption.large }
}
