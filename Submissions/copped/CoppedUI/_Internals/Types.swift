import SwiftUI
import UIKit

// MARK: - AnimationScale

public enum AnimationScale: Hashable {
  case none
  case small
  case medium
  case large
  case custom(_ value: CGFloat)
}

extension AnimationScale {
  public var value: CGFloat {
    switch self {
    case .none:             return 1.0
    case .small:            return Theme.current.layout.animationScale.small
    case .medium:           return Theme.current.layout.animationScale.medium
    case .large:            return Theme.current.layout.animationScale.large
    case .custom(let val):
      guard val >= 0 && val <= 1.0 else {
        assertionFailure("Animation scale must be 0.0–1.0")
        return 1.0
      }
      return val
    }
  }
}

// MARK: - BorderWidth

public enum BorderWidth: Hashable {
  case none, small, medium, large
}

extension BorderWidth {
  public var value: CGFloat {
    switch self {
    case .none:   return 0.0
    case .small:  return Theme.current.layout.borderWidth.small
    case .medium: return Theme.current.layout.borderWidth.medium
    case .large:  return Theme.current.layout.borderWidth.large
    }
  }
}

// MARK: - ButtonStyle

public enum ButtonStyle: Hashable {
  case filled
  case plain
  case light
  case bordered(BorderWidth)
  case minimal
  case glass
}

// MARK: - ComponentRadius

public enum ComponentRadius: Hashable {
  case none, small, medium, large, full
  case custom(CGFloat)
}

extension ComponentRadius {
  public func value(for height: CGFloat = 10_000) -> CGFloat {
    let maxValue = height / 2
    let value: CGFloat = switch self {
    case .none:           0
    case .small:          Theme.current.layout.componentRadius.small
    case .medium:         Theme.current.layout.componentRadius.medium
    case .large:          Theme.current.layout.componentRadius.large
    case .full:           height / 2
    case .custom(let v):  v
    }
    return min(value, maxValue)
  }
}

// MARK: - ComponentSize

public enum ComponentSize: Hashable {
  case small, medium, large
}

// MARK: - ContainerRadius

public enum ContainerRadius: Hashable {
  case none, small, medium, large
  case custom(CGFloat)
}

extension ContainerRadius {
  public var value: CGFloat {
    switch self {
    case .none:          return 0
    case .small:         return Theme.current.layout.containerRadius.small
    case .medium:        return Theme.current.layout.containerRadius.medium
    case .large:         return Theme.current.layout.containerRadius.large
    case .custom(let v): return v
    }
  }
}

// MARK: - InputStyle

public enum InputStyle: Hashable {
  case light, bordered, faded
}

// MARK: - LineCap

public enum LineCap {
  case butt, round, square
}

extension LineCap {
  var cgLineCap: CGLineCap {
    switch self {
    case .butt:   return .butt
    case .round:  return .round
    case .square: return .square
    }
  }
}

// MARK: - Paddings

public struct Paddings: Hashable {
  public var top: CGFloat
  public var leading: CGFloat
  public var bottom: CGFloat
  public var trailing: CGFloat

  public init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
    self.top = top; self.leading = leading; self.bottom = bottom; self.trailing = trailing
  }
  public init(horizontal: CGFloat, vertical: CGFloat) {
    self.top = vertical; self.leading = horizontal; self.bottom = vertical; self.trailing = horizontal
  }
  public init(padding: CGFloat) {
    self.top = padding; self.leading = padding; self.bottom = padding; self.trailing = padding
  }
}

extension Paddings {
  public var edgeInsets: EdgeInsets {
    EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
  }
  public var uiEdgeInsets: UIEdgeInsets {
    UIEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
  }
}

// MARK: - SubmitType

public enum SubmitType {
  case done, go, send, join, route, search, `return`, next, `continue`
}

extension SubmitType {
  public var returnKeyType: UIReturnKeyType {
    switch self {
    case .done:     return .done
    case .go:       return .go
    case .send:     return .send
    case .join:     return .join
    case .route:    return .route
    case .search:   return .search
    case .return:   return .default
    case .next:     return .next
    case .continue: return .continue
    }
  }
  public var submitLabel: SubmitLabel {
    switch self {
    case .done:     return .done
    case .go:       return .go
    case .send:     return .send
    case .join:     return .join
    case .route:    return .route
    case .search:   return .search
    case .return:   return .return
    case .next:     return .next
    case .continue: return .continue
    }
  }
}

// MARK: - TextAutocapitalization

public enum TextAutocapitalization {
  case never, characters, words, sentences
}

extension TextAutocapitalization {
  public var textAutocapitalizationType: UITextAutocapitalizationType {
    switch self {
    case .never:      return .none
    case .characters: return .allCharacters
    case .words:      return .words
    case .sentences:  return .sentences
    }
  }
  public var textInputAutocapitalization: SwiftUI.TextInputAutocapitalization {
    switch self {
    case .never:      return .never
    case .characters: return .characters
    case .words:      return .words
    case .sentences:  return .sentences
    }
  }
}
