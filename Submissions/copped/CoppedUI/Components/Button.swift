import SwiftUI

// MARK: - ButtonVM

public struct ButtonVM: ComponentVM {
  public var animationScale: AnimationScale = .medium
  public var color: ComponentColor?
  public var contentSpacing: CGFloat = 8.0
  public var cornerRadius: ComponentRadius = .medium
  public var font: UniversalFont?
  public var image: UniversalImage?
  public var imageLocation: ImageLocation = .leading
  @available(*, deprecated, message: "Use image.withRenderingMode(_:) instead.")
  public var imageRenderingMode: ImageRenderingMode?
  @available(*, deprecated, message: "Use image instead.")
  public var imageSrc: ImageSource?
  public var isEnabled: Bool = true
  public var isFullWidth: Bool = false
  public var isLoading: Bool = false
  public var loadingVM: LoadingVM?
  public var size: ComponentSize = .medium
  public var style: ButtonStyle = .filled
  public var title: String = ""
  public init() {}
}

// MARK: - ButtonVM.ImageLocation

extension ButtonVM {
  public enum ImageLocation {
    case leading, trailing
  }
}

// MARK: - ButtonVM.ImageSource (deprecated)

extension ButtonVM {
  public enum ImageSource: Hashable {
    case sfSymbol(String)
    case local(String, bundle: Bundle? = nil)
  }
}

// MARK: - ButtonVM Shared Helpers

extension ButtonVM {
  var isInteractive: Bool { isEnabled && !isLoading }

  var preferredLoadingVM: LoadingVM {
    return loadingVM ?? LoadingVM {
      $0.color = ComponentColor(
        main:     foregroundColor,
        contrast: self.color?.main ?? .background
      )
      $0.size = .small
    }
  }

  var backgroundColor: UniversalColor? {
    switch style {
    case .filled:
      return (color?.main ?? .content2).enabled(isInteractive)
    case .light:
      return (color?.background ?? .content1).enabled(isInteractive)
    case .plain, .bordered, .minimal, .glass:
      return nil
    }
  }

  var foregroundColor: UniversalColor {
    let c: UniversalColor = switch style {
    case .filled:
      color?.contrast ?? .foreground
    case .plain, .light, .bordered, .minimal, .glass:
      color?.main ?? .foreground
    }
    return c.enabled(isInteractive)
  }

  var borderWidth: CGFloat {
    switch style {
    case .filled, .plain, .light, .minimal, .glass: return 0.0
    case .bordered(let bw): return bw.value
    }
  }

  var borderColor: UniversalColor? {
    switch style {
    case .filled, .plain, .light, .minimal, .glass: return nil
    case .bordered:
      return (color?.main ?? .divider).enabled(isInteractive)
    }
  }

  var isGlassStyle: Bool { style == .glass }

  var glassAccentColor: Color? {
    color?.main.color
  }

  var preferredFont: UniversalFont {
    if let font { return font }
    switch size {
    case .small:  return .smButton
    case .medium: return .mdButton
    case .large:  return .lgButton
    }
  }

  var height: CGFloat? {
    switch style {
    case .minimal: return nil
    case .light, .filled, .bordered, .plain, .glass:
      return switch size {
      case .small:  36
      case .medium: 44
      case .large:  52
      }
    }
  }

  var imageSide: CGFloat {
    switch size {
    case .small:  20
    case .medium: 24
    case .large:  28
    }
  }

  var horizontalPadding: CGFloat {
    switch style {
    case .minimal: return 0
    case .light, .filled, .bordered, .plain, .glass:
      if title.isNotEmpty || isLoading {
        return switch size {
        case .small:  16
        case .medium: 20
        case .large:  24
        }
      } else {
        return switch size {
        case .small:  8
        case .medium: 10
        case .large:  12
        }
      }
    }
  }

  var width: CGFloat? { isFullWidth ? 10_000 : nil }

  var imageWithLegacyFallback: UniversalImage? {
    if let image { return image }
    guard let imageSrc else { return nil }
    let img: UniversalImage? = switch imageSrc {
    case .sfSymbol(let name):          UniversalImage(systemName: name)
    case .local(let name, let bundle): UniversalImage(name, bundle: bundle)
    }
    if let imageRenderingMode, let img {
      return img.withRenderingMode(imageRenderingMode)
    }
    return img
  }
}

// MARK: - SUButton

public struct SUButton: View {
  public var model: ButtonVM
  public var action: () -> Void
  public var onLongPress: (() -> Void)?
  @State public var scale: CGFloat = 1.0

  public init(model: ButtonVM, onLongPress: (() -> Void)? = nil, action: @escaping () -> Void = {}) {
    self.model = model
    self.onLongPress = onLongPress
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(spacing: model.contentSpacing) {
        content
      }
    }
    .buttonStyle(CKButtonStyle(model: model))
    .simultaneousGesture(
      DragGesture(minimumDistance: 0.0)
        .onChanged { _ in scale = model.animationScale.value }
        .onEnded   { _ in scale = 1.0 }
    )
    .disabled(!model.isInteractive)
    .modifier(OptionalLongPressModifier(action: onLongPress))
    .scaleEffect(scale, anchor: .center)
    .animation(.easeOut(duration: 0.05), value: scale)
  }

  @ViewBuilder
  private var content: some View {
    switch (model.isLoading, model.imageWithLegacyFallback, model.imageLocation) {
    case (true, _, _) where model.title.isEmpty:
      SULoading(model: model.preferredLoadingVM)
    case (true, _, _):
      SULoading(model: model.preferredLoadingVM)
      Text(model.title)
    case (false, let img?, _) where model.title.isEmpty:
      CKButtonImage(universalImage: img, tintColor: model.foregroundColor, side: model.imageSide)
    case (false, let img?, .leading):
      CKButtonImage(universalImage: img, tintColor: model.foregroundColor, side: model.imageSide)
      Text(model.title)
    case (false, let img?, .trailing):
      Text(model.title)
      CKButtonImage(universalImage: img, tintColor: model.foregroundColor, side: model.imageSide)
    case (false, _, _):
      Text(model.title)
    }
  }
}

// MARK: - Private Helpers

private struct CKButtonImage: View {
  let universalImage: UniversalImage
  let tintColor: UniversalColor
  let side: CGFloat

  var body: some View {
    universalImage.image
      .resizable()
      .scaledToFit()
      .tint(tintColor.color)
      .frame(width: side, height: side)
  }
}

private struct OptionalLongPressModifier: ViewModifier {
  let action: (() -> Void)?

  func body(content: Content) -> some View {
    if let action {
      content.onLongPressGesture(minimumDuration: 0.5, perform: action)
    } else {
      content
    }
  }
}

private struct CKButtonStyle: SwiftUI.ButtonStyle {
  let model: ButtonVM

  func makeBody(configuration: Configuration) -> some View {
    let label = configuration.label
      .font(model.preferredFont.font)
      .lineLimit(1)
      .padding(.horizontal, model.horizontalPadding)
      .frame(maxWidth: model.width)
      .frame(height: model.height)
      .contentShape(.rect)
      .foregroundStyle(model.foregroundColor.color)

    if model.isGlassStyle {
      label.liquidGlass(
        enabled: true,
        cornerRadius: model.cornerRadius.value(),
        accentColor: model.glassAccentColor
      )
    } else {
      label
        .background(model.backgroundColor?.color ?? .clear)
        .clipShape(RoundedRectangle(cornerRadius: model.cornerRadius.value()))
        .overlay {
          RoundedRectangle(cornerRadius: model.cornerRadius.value())
            .strokeBorder(model.borderColor?.color ?? .clear, lineWidth: model.borderWidth)
        }
    }
  }
}
