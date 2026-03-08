import SwiftUI

// MARK: - ModalOverlayStyle

public enum ModalOverlayStyle: Equatable {
  case dimmed, blurred, transparent
}

// MARK: - ModalSize

public enum ModalSize {
  case small, medium, large, full
}

extension ModalSize {
  public var maxWidth: CGFloat {
    switch self {
    case .small:  return 300
    case .medium: return 400
    case .large:  return 600
    case .full:   return 10_000
    }
  }
}

// MARK: - ModalTransition

public enum ModalTransition: Equatable {
  case none, slow, normal, fast
  case custom(TimeInterval)
}

extension ModalTransition {
  public var value: TimeInterval {
    switch self {
    case .none:          return 0
    case .slow:          return 0.5
    case .normal:        return 0.3
    case .fast:          return 0.2
    case .custom(let v): return max(0, v)
    }
  }
}

// MARK: - ModalVM Protocol

public protocol ModalVM: ComponentVM {
  var backgroundColor: UniversalColor? { get set }
  var borderWidth: BorderWidth { get set }
  var closesOnOverlayTap: Bool { get set }
  var contentPaddings: Paddings { get set }
  var contentSpacing: CGFloat { get set }
  var cornerRadius: ContainerRadius { get set }
  var overlayStyle: ModalOverlayStyle { get set }
  var outerPaddings: Paddings { get set }
  var size: ModalSize { get set }
  var transition: ModalTransition { get set }
  var useLiquidGlass: Bool { get set }
}

extension ModalVM {
  var preferredBackgroundColor: UniversalColor {
    backgroundColor ?? .universal(.rgba(r: 44, g: 44, b: 46, a: 1.0))
  }
}

// MARK: - BottomModalVM

public struct BottomModalVM: ModalVM {
  public var backgroundColor: UniversalColor?
  public var borderWidth: BorderWidth = .small
  public var closesOnOverlayTap: Bool = true
  public var contentPaddings: Paddings = .init(padding: 20)
  public var contentSpacing: CGFloat = 16
  public var cornerRadius: ContainerRadius = .custom(24)
  public var hidesOnSwipe: Bool = true
  public var isDraggable: Bool = true
  public var overlayStyle: ModalOverlayStyle = .dimmed
  public var outerPaddings: Paddings = .init(padding: 20)
  public var size: ModalSize = .medium
  public var transition: ModalTransition = .fast
  public var useLiquidGlass: Bool = false
  public init() {}
}

// MARK: - CenterModalVM

public struct CenterModalVM: ModalVM {
  public var backgroundColor: UniversalColor?
  public var borderWidth: BorderWidth = .small
  public var closesOnOverlayTap: Bool = true
  public var contentPaddings: Paddings = .init(padding: 20)
  public var contentSpacing: CGFloat = 16
  public var cornerRadius: ContainerRadius = .custom(24)
  public var overlayStyle: ModalOverlayStyle = .dimmed
  public var outerPaddings: Paddings = .init(padding: 20)
  public var size: ModalSize = .medium
  public var transition: ModalTransition = .fast
  public var useLiquidGlass: Bool = false
  public init() {}
}

// MARK: - ModalAnimation

enum ModalAnimation {
  static func rubberBandClamp(_ translation: CGFloat) -> CGFloat {
    let dim: CGFloat = 20
    let coef: CGFloat = 0.2
    return (1.0 - (1.0 / ((translation * coef / dim) + 1.0))) * dim
  }

  static func bottomModalOffset(_ translation: CGFloat, model: BottomModalVM) -> CGFloat {
    if translation > 0 {
      return model.hidesOnSwipe
        ? translation
        : (model.isDraggable ? Self.rubberBandClamp(translation) : 0)
    } else {
      return model.isDraggable ? -Self.rubberBandClamp(abs(translation)) : 0
    }
  }

  static func shouldHideBottomModal(
    offset: CGFloat,
    height: CGFloat,
    velocity: CGFloat,
    model: BottomModalVM
  ) -> Bool {
    guard model.hidesOnSwipe else { return false }
    return abs(offset) > height / 2 || velocity > 250
  }
}

// MARK: - ModalOverlay

struct ModalOverlay<VM: ModalVM>: View {
  let model: VM
  @Binding var isVisible: Bool

  init(isVisible: Binding<Bool>, model: VM) {
    self._isVisible = isVisible
    self.model = model
  }

  var body: some View {
    Group {
      switch model.overlayStyle {
      case .dimmed:
        Color.black.opacity(Theme.current.layout.overlay.dim)
      case .blurred:
        Color.clear.background(.ultraThinMaterial)
      case .transparent:
        Color.clear.contentShape(.rect)
      }
    }
    .ignoresSafeArea(.all)
    .onTapGesture {
      if model.closesOnOverlayTap { isVisible = false }
    }
  }
}

// MARK: - ModalContent

struct ModalContent<VM: ModalVM, Header: View, Body: View, Footer: View>: View {
  let model: VM
  let contentHeader: () -> Header
  let contentBody: () -> Body
  let contentFooter: () -> Footer

  @State private var headerSize: CGSize = .zero
  @State private var bodySize: CGSize = .zero
  @State private var footerSize: CGSize = .zero

  init(
    model: VM,
    @ViewBuilder header: @escaping () -> Header,
    @ViewBuilder body: @escaping () -> Body,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self.model = model
    self.contentHeader = header
    self.contentBody = body
    self.contentFooter = footer
  }

  var body: some View {
    VStack(spacing: model.contentSpacing) {
      contentHeader()
        .observeSize { headerSize = $0 }
        .padding(.top, model.contentPaddings.top)
        .padding(.leading, model.contentPaddings.leading)
        .padding(.trailing, model.contentPaddings.trailing)

      ScrollView {
        contentBody()
          .padding(.leading, model.contentPaddings.leading)
          .padding(.trailing, model.contentPaddings.trailing)
          .observeSize { bodySize = $0 }
          .padding(.top, bodyTopPadding)
          .padding(.bottom, bodyBottomPadding)
      }
      .frame(maxWidth: .infinity, maxHeight: scrollViewMaxHeight)
      .disableScrollWhenContentFits()

      contentFooter()
        .observeSize { footerSize = $0 }
        .padding(.leading, model.contentPaddings.leading)
        .padding(.trailing, model.contentPaddings.trailing)
        .padding(.bottom, model.contentPaddings.bottom)
    }
    .frame(maxWidth: model.size.maxWidth, alignment: .leading)
    .modalGlass(model: model)
    .padding(model.outerPaddings.edgeInsets)
  }

  private var bodyTopPadding: CGFloat    { headerSize.height > 0 ? 0 : model.contentPaddings.top }
  private var bodyBottomPadding: CGFloat { footerSize.height > 0 ? 0 : model.contentPaddings.bottom }
  private var scrollViewMaxHeight: CGFloat { bodySize.height + bodyTopPadding + bodyBottomPadding }
}

// MARK: - Modal Glass Helper

extension View {
  @ViewBuilder
  func modalGlass<VM: ModalVM>(model: VM) -> some View {
    let cr = model.cornerRadius.value
    let bw = model.borderWidth.value

    let glass = Theme.current.layout.glass
    if model.useLiquidGlass {
      if #available(iOS 26.0, *) {
        self
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cr))
          .shadow(color: .clear, radius: 0)
      } else {
        self
          .background(GlassBackground(style: glass.blurStyle, tint: glass.tint, cornerRadius: cr))
          .clipShape(RoundedRectangle(cornerRadius: cr, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: cr, style: .continuous)
              .strokeBorder(glass.border, lineWidth: bw)
          )
          .shadow(color: glass.shadowColor, radius: glass.shadowRadius,
                  x: glass.shadowOffset.width, y: glass.shadowOffset.height)
      }
    } else {
      self
        .background(GlassBackground(style: glass.blurStyle, tint: glass.tint, cornerRadius: cr))
        .clipShape(RoundedRectangle(cornerRadius: cr, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: cr, style: .continuous)
            .strokeBorder(glass.border, lineWidth: bw)
        )
        .shadow(color: glass.shadowColor, radius: glass.shadowRadius,
                x: glass.shadowOffset.width, y: glass.shadowOffset.height)
    }
  }
}

// MARK: - SUBottomModal

struct SUBottomModal<Header: View, Body: View, Footer: View>: View {
  let model: BottomModalVM
  @Binding var isVisible: Bool
  let contentHeader: () -> Header
  let contentBody: () -> Body
  let contentFooter: () -> Footer

  @State private var contentHeight: CGFloat = 0
  @State private var contentOffsetY: CGFloat = 0
  @State private var overlayOpacity: CGFloat = 0

  init(
    isVisible: Binding<Bool>,
    model: BottomModalVM,
    @ViewBuilder header: @escaping () -> Header,
    @ViewBuilder body: @escaping () -> Body,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self._isVisible = isVisible
    self.model = model
    self.contentHeader = header
    self.contentBody = body
    self.contentFooter = footer
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      ModalOverlay(isVisible: $isVisible, model: model)
        .opacity(overlayOpacity)

      ModalContent(model: model, header: contentHeader, body: contentBody, footer: contentFooter)
        .observeSize { contentHeight = $0.height }
        .offset(y: contentOffsetY)
        .gesture(
          DragGesture()
            .onChanged { gesture in
              contentOffsetY = ModalAnimation.bottomModalOffset(gesture.translation.height, model: model)
            }
            .onEnded { gesture in
              if ModalAnimation.shouldHideBottomModal(
                offset: contentOffsetY, height: contentHeight,
                velocity: gesture.velocity.height, model: model
              ) {
                isVisible = false
              } else {
                withAnimation(.linear(duration: 0.2)) { contentOffsetY = 0 }
              }
            }
        )
    }
    .onAppear {
      contentOffsetY = screenHeight
      withAnimation(.linear(duration: model.transition.value)) {
        overlayOpacity = 1.0
        contentOffsetY = 0
      }
    }
    .onChange(of: isVisible) { newValue in
      withAnimation(.linear(duration: model.transition.value)) {
        if newValue {
          overlayOpacity = 1.0
          contentOffsetY = 0
        } else {
          overlayOpacity = 0.0
          contentOffsetY = screenHeight
        }
      }
    }
  }

  private var screenHeight: CGFloat { UIScreen.main.bounds.height }
}

// MARK: - SUCenterModal

struct SUCenterModal<Header: View, Body: View, Footer: View>: View {
  let model: CenterModalVM
  @Binding var isVisible: Bool
  let contentHeader: () -> Header
  let contentBody: () -> Body
  let contentFooter: () -> Footer

  @State private var contentOpacity: CGFloat = 0

  init(
    isVisible: Binding<Bool>,
    model: CenterModalVM,
    @ViewBuilder header: @escaping () -> Header,
    @ViewBuilder body: @escaping () -> Body,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self._isVisible = isVisible
    self.model = model
    self.contentHeader = header
    self.contentBody = body
    self.contentFooter = footer
  }

  var body: some View {
    ZStack(alignment: .center) {
      ModalOverlay(isVisible: $isVisible, model: model)
      ModalContent(model: model, header: contentHeader, body: contentBody, footer: contentFooter)
    }
    .opacity(contentOpacity)
    .onAppear {
      withAnimation(.linear(duration: model.transition.value)) { contentOpacity = 1.0 }
    }
    .onChange(of: isVisible) { newValue in
      withAnimation(.linear(duration: model.transition.value)) {
        contentOpacity = newValue ? 1.0 : 0.0
      }
    }
  }
}

// MARK: - ModalPresentationModifier

struct ModalPresentationModifier<Modal: View>: ViewModifier {
  @State var isPresented: Bool = false
  @Binding var isContentVisible: Bool
  @ViewBuilder var content: () -> Modal
  let transitionDuration: TimeInterval
  let onDismiss: (() -> Void)?

  func body(content: Content) -> some View {
    content
      .transaction { $0.disablesAnimations = false }
      .onAppear { if isContentVisible { isPresented = true } }
      .onChange(of: isContentVisible) { isVisible in
        if isVisible {
          isPresented = true
        } else {
          DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
            isPresented = false
          }
        }
      }
      .fullScreenCover(
        isPresented: .init(get: { isPresented }, set: { isContentVisible = $0 }),
        onDismiss: onDismiss,
        content: { self.content().transparentPresentationBackground() }
      )
      .transaction { $0.disablesAnimations = true }
  }
}

struct ModalPresentationWithItemModifier<Modal: View, Item: Identifiable>: ViewModifier {
  @State var presentedItem: Item?
  @Binding var visibleItem: Item?
  @ViewBuilder var content: (Item) -> Modal
  let transitionDuration: (Item) -> TimeInterval
  let onDismiss: (() -> Void)?

  func body(content: Content) -> some View {
    content
      .transaction { $0.disablesAnimations = false }
      .onAppear { presentedItem = visibleItem }
      .onChange(of: visibleItem.isNotNil) { isVisible in
        if isVisible {
          presentedItem = visibleItem
        } else {
          let duration = presentedItem.map { transitionDuration($0) } ?? 0.3
          DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            presentedItem = visibleItem
          }
        }
      }
      .fullScreenCover(
        item: .init(get: { presentedItem }, set: { visibleItem = $0 }),
        onDismiss: onDismiss,
        content: { item in self.content(item).transparentPresentationBackground() }
      )
      .transaction { $0.disablesAnimations = true }
  }
}

// MARK: - View Extensions: modal (internal)

extension View {
  func modal<Modal: View>(
    isVisible: Binding<Bool>,
    transitionDuration: TimeInterval,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> Modal
  ) -> some View {
    modifier(ModalPresentationModifier(
      isContentVisible: isVisible,
      content: content,
      transitionDuration: transitionDuration,
      onDismiss: onDismiss
    ))
  }

  func modal<Modal: View, Item: Identifiable>(
    item: Binding<Item?>,
    transitionDuration: @escaping (Item) -> TimeInterval,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (Item) -> Modal
  ) -> some View {
    modifier(ModalPresentationWithItemModifier(
      visibleItem: item,
      content: content,
      transitionDuration: transitionDuration,
      onDismiss: onDismiss
    ))
  }
}

// MARK: - View Extensions: bottomModal (public)

extension View {
  public func bottomModal<Header: View, Body: View, Footer: View>(
    isPresented: Binding<Bool>,
    model: BottomModalVM = .init(),
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder header: @escaping () -> Header = { EmptyView() },
    @ViewBuilder body: @escaping () -> Body,
    @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
  ) -> some View {
    self.modal(isVisible: isPresented, transitionDuration: model.transition.value, onDismiss: onDismiss) {
      SUBottomModal(isVisible: isPresented, model: model, header: header, body: body, footer: footer)
    }
  }

  public func bottomModal<Item: Identifiable, Header: View, Body: View, Footer: View>(
    item: Binding<Item?>,
    model: @escaping (Item) -> BottomModalVM = { _ in .init() },
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder header: @escaping (Item) -> Header,
    @ViewBuilder body: @escaping (Item) -> Body,
    @ViewBuilder footer: @escaping (Item) -> Footer
  ) -> some View {
    self.modal(item: item, transitionDuration: { model($0).transition.value }, onDismiss: onDismiss) { unwrapped in
      SUBottomModal(
        isVisible: .init(
          get: { item.wrappedValue.isNotNil },
          set: { if $0 { item.wrappedValue = unwrapped } else { item.wrappedValue = nil } }
        ),
        model: model(unwrapped),
        header: { header(unwrapped) },
        body: { body(unwrapped) },
        footer: { footer(unwrapped) }
      )
    }
  }

  public func bottomModal<Item: Identifiable, Body: View>(
    item: Binding<Item?>,
    model: @escaping (Item) -> BottomModalVM = { _ in .init() },
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder body: @escaping (Item) -> Body
  ) -> some View {
    bottomModal(item: item, model: model, onDismiss: onDismiss,
      header: { _ in EmptyView() }, body: body, footer: { _ in EmptyView() })
  }
}

// MARK: - View Extensions: centerModal (public)

extension View {
  public func centerModal<Header: View, Body: View, Footer: View>(
    isPresented: Binding<Bool>,
    model: CenterModalVM = .init(),
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder header: @escaping () -> Header = { EmptyView() },
    @ViewBuilder body: @escaping () -> Body,
    @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
  ) -> some View {
    self.modal(isVisible: isPresented, transitionDuration: model.transition.value, onDismiss: onDismiss) {
      SUCenterModal(isVisible: isPresented, model: model, header: header, body: body, footer: footer)
    }
  }

  public func centerModal<Item: Identifiable, Header: View, Body: View, Footer: View>(
    item: Binding<Item?>,
    model: @escaping (Item) -> CenterModalVM = { _ in .init() },
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder header: @escaping (Item) -> Header,
    @ViewBuilder body: @escaping (Item) -> Body,
    @ViewBuilder footer: @escaping (Item) -> Footer
  ) -> some View {
    self.modal(item: item, transitionDuration: { model($0).transition.value }, onDismiss: onDismiss) { unwrapped in
      SUCenterModal(
        isVisible: .init(
          get: { item.wrappedValue.isNotNil },
          set: { if $0 { item.wrappedValue = unwrapped } else { item.wrappedValue = nil } }
        ),
        model: model(unwrapped),
        header: { header(unwrapped) },
        body: { body(unwrapped) },
        footer: { footer(unwrapped) }
      )
    }
  }

  public func centerModal<Item: Identifiable, Body: View>(
    item: Binding<Item?>,
    model: @escaping (Item) -> CenterModalVM = { _ in .init() },
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder body: @escaping (Item) -> Body
  ) -> some View {
    centerModal(item: item, model: model, onDismiss: onDismiss,
      header: { _ in EmptyView() }, body: body, footer: { _ in EmptyView() })
  }
}
