import SwiftUI
import UIKit

// MARK: - ImageRenderingMode

public enum ImageRenderingMode {
  case template
  case original
}

extension ImageRenderingMode {
  var uiImageRenderingMode: UIImage.RenderingMode {
    switch self {
    case .template: return .alwaysTemplate
    case .original: return .alwaysOriginal
    }
  }
  var imageRenderingModel: Image.TemplateRenderingMode {
    switch self {
    case .template: return .template
    case .original: return .original
    }
  }
}

// MARK: - UniversalImage

/// A platform-agnostic image container supporting SF Symbols and asset catalog images.
public struct UniversalImage: Hashable {

  private enum ImageRepresentable: Hashable {
    case sfSymbol(String)
    case asset(String, Bundle?)
  }

  private let internalImage: ImageRepresentable
  private var renderingMode: ImageRenderingMode?

  private init(image: ImageRepresentable, mode: ImageRenderingMode) {
    self.internalImage = image
    self.renderingMode = mode
  }

  public init(systemName name: String) {
    self.internalImage = .sfSymbol(name)
  }

  public init(_ name: String, bundle: Bundle? = nil) {
    self.internalImage = .asset(name, bundle)
  }
}

extension UniversalImage {
  public var uiImage: UIImage? {
    let image = switch self.internalImage {
    case .sfSymbol(let name):  UIImage(systemName: name)
    case .asset(let name, let bundle): UIImage(named: name, in: bundle, with: nil)
    }
    if let renderingMode {
      return image?.withRenderingMode(renderingMode.uiImageRenderingMode)
    }
    return image
  }

  public var image: Image {
    let image = switch self.internalImage {
    case .sfSymbol(let name):  Image(systemName: name)
    case .asset(let name, let bundle): Image(name, bundle: bundle)
    }
    if let renderingMode {
      return image.renderingMode(renderingMode.imageRenderingModel)
    }
    return image
  }

  public func withRenderingMode(_ mode: ImageRenderingMode) -> Self {
    return Self(image: self.internalImage, mode: mode)
  }
}
