import SwiftUI

// MARK: - AlertButtonVM

public struct AlertButtonVM: ComponentVM {
  public var title: String = ""
  public var animationScale: AnimationScale = .medium
  public var color: ComponentColor?
  public var cornerRadius: ComponentRadius = .medium
  public var style: ButtonStyle = .filled
  public init() {}
}

// MARK: - AlertVM

public struct AlertVM: ComponentVM {
  public var title: String?
  public var message: String?
  public var primaryButton: AlertButtonVM?
  public var secondaryButton: AlertButtonVM?
  public var backgroundColor: UniversalColor?
  public var borderWidth: BorderWidth = .small
  public var closesOnOverlayTap: Bool = false
  public var contentPaddings: Paddings = .init(padding: 16)
  public var cornerRadius: ContainerRadius = .medium
  public var overlayStyle: ModalOverlayStyle = .dimmed
  public var transition: ModalTransition = .fast
  public init() {}
}

extension AlertVM {
  var modalVM: CenterModalVM {
    CenterModalVM {
      $0.backgroundColor = self.backgroundColor
      $0.borderWidth = self.borderWidth
      $0.closesOnOverlayTap = self.closesOnOverlayTap
      $0.contentPaddings = self.contentPaddings
      $0.cornerRadius = self.cornerRadius
      $0.overlayStyle = self.overlayStyle
      $0.transition = self.transition
      $0.size = .small
    }
  }

  var primaryButtonVM: ButtonVM? {
    let vm = primaryButton.map(mapAlertButtonVM)
    return secondaryButton.isNotNil ? vm : (vm ?? Self.defaultButtonVM)
  }

  var secondaryButtonVM: ButtonVM? {
    secondaryButton.map(mapAlertButtonVM)
  }

  private func mapAlertButtonVM(_ model: AlertButtonVM) -> ButtonVM {
    ButtonVM {
      $0.title = model.title
      $0.animationScale = model.animationScale
      $0.color = model.color
      $0.cornerRadius = model.cornerRadius
      $0.style = model.style
      $0.isFullWidth = true
    }
  }

  static let buttonsSpacing: CGFloat = 12

  static let defaultButtonVM = ButtonVM {
    $0.title = "OK"
    $0.color = .primary
    $0.style = .filled
    $0.isFullWidth = true
  }
}

// MARK: - AlertButtonsOrientationCalculator

struct AlertButtonsOrientationCalculator {
  enum Orientation { case vertical, horizontal }

  static func preferredOrientation(model: AlertVM) -> Orientation {
    guard let primary = model.primaryButtonVM,
          let secondary = model.secondaryButtonVM else {
      return .vertical
    }
    // Heuristic: short titles → horizontal
    let threshold = 14
    return (primary.title.count <= threshold && secondary.title.count <= threshold)
      ? .horizontal : .vertical
  }
}

// MARK: - AlertContent (internal)

struct AlertContent: View {
  @Binding var isPresented: Bool
  let model: AlertVM
  let primaryAction: (() -> Void)?
  let secondaryAction: (() -> Void)?

  var body: some View {
    SUCenterModal(
      isVisible: $isPresented,
      model: model.modalVM,
      header: {
        if model.message.isNotNil, let text = model.title { titleView(text) }
      },
      body: {
        if let text = model.message { messageView(text) }
        else if let text = model.title { titleView(text) }
      },
      footer: {
        switch AlertButtonsOrientationCalculator.preferredOrientation(model: model) {
        case .horizontal:
          HStack(spacing: AlertVM.buttonsSpacing) {
            buttonView(model: model.secondaryButtonVM, action: secondaryAction)
            buttonView(model: model.primaryButtonVM, action: primaryAction)
          }
        case .vertical:
          VStack(spacing: AlertVM.buttonsSpacing) {
            buttonView(model: model.primaryButtonVM, action: primaryAction)
            buttonView(model: model.secondaryButtonVM, action: secondaryAction)
          }
        }
      }
    )
  }

  private func titleView(_ text: String) -> some View {
    Text(text)
      .font(UniversalFont.mdHeadline.font)
      .foregroundStyle(UniversalColor.foreground.color)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .fixedSize(horizontal: false, vertical: true)
  }

  private func messageView(_ text: String) -> some View {
    Text(text)
      .font(UniversalFont.mdBody.font)
      .foregroundStyle(UniversalColor.secondaryForeground.color)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  private func buttonView(model: ButtonVM?, action: (() -> Void)?) -> some View {
    if let model {
      SUButton(model: model) {
        action?()
        isPresented = false
      }
    }
  }
}

// MARK: - View Extensions

extension View {
  public func suAlert(
    isPresented: Binding<Bool>,
    model: AlertVM,
    primaryAction: (() -> Void)? = nil,
    secondaryAction: (() -> Void)? = nil,
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    self.modal(
      isVisible: isPresented,
      transitionDuration: model.transition.value,
      onDismiss: onDismiss
    ) {
      AlertContent(
        isPresented: isPresented,
        model: model,
        primaryAction: primaryAction,
        secondaryAction: secondaryAction
      )
    }
  }

  public func suAlert<Item: Identifiable>(
    item: Binding<Item?>,
    model: @escaping (Item) -> AlertVM,
    primaryAction: ((Item) -> Void)? = nil,
    secondaryAction: ((Item) -> Void)? = nil,
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    self.modal(
      item: item,
      transitionDuration: { model($0).transition.value },
      onDismiss: onDismiss
    ) { unwrapped in
      AlertContent(
        isPresented: .init(
          get: { item.wrappedValue.isNotNil },
          set: { if $0 { item.wrappedValue = unwrapped } else { item.wrappedValue = nil } }
        ),
        model: model(unwrapped),
        primaryAction: { primaryAction?(unwrapped) },
        secondaryAction: { secondaryAction?(unwrapped) }
      )
    }
  }
}
