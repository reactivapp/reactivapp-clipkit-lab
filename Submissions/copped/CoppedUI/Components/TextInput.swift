import SwiftUI
import UIKit

// MARK: - TextInputVM

public struct TextInputVM: ComponentVM {
  public var autocapitalization: TextAutocapitalization = .sentences
  public var color: ComponentColor?
  public var cornerRadius: ComponentRadius = .large
  public var font: UniversalFont?
  public var isAutocorrectionEnabled: Bool = true
  public var isEnabled: Bool = true
  public var keyboardType: UIKeyboardType = .default
  public var maxRows: Int?
  public var minRows: Int = 2
  public var placeholder: String?
  public var size: ComponentSize = .medium
  public var style: InputStyle = .light
  public var submitType: SubmitType = .return
  public var tintColor: UniversalColor = .accent
  public init() {}
}

extension TextInputVM {
  var preferredFont: UniversalFont {
    if let font { return font }
    switch size {
    case .small:  return .smBody
    case .medium: return .mdBody
    case .large:  return .lgBody
    }
  }

  var contentPadding: CGFloat { 12 }

  var backgroundColor: UniversalColor {
    switch style {
    case .light, .faded: return color?.background ?? .content1
    case .bordered:      return .background
    }
  }

  var foregroundColor: UniversalColor {
    (color?.main ?? .foreground).enabled(isEnabled)
  }

  var placeholderColor: UniversalColor {
    if let color {
      return color.main.withOpacity(isEnabled ? 0.7 : 0.3)
    }
    return UniversalColor.secondaryForeground.enabled(isEnabled)
  }

  var borderWidth: CGFloat {
    switch style {
    case .light: return 0
    case .bordered, .faded: return BorderWidth.small.value
    }
  }

  var borderColor: UniversalColor {
    (color?.main ?? .divider).enabled(isEnabled)
  }

  var minTextInputHeight: CGFloat {
    let rows = maxRows.map { min($0, minRows) } ?? minRows
    return height(forRows: rows)
  }

  var maxTextInputHeight: CGFloat {
    maxRows.map { height(forRows: max($0, minRows)) } ?? 10_000
  }

  func adaptedCornerRadius(for h: CGFloat = 10_000) -> CGFloat {
    let value = cornerRadius.value(for: h)
    let max   = ComponentRadius.custom(height(forRows: 1) / 2).value(for: h)
    return min(value, max)
  }

  private func height(forRows rows: Int) -> CGFloat {
    let n = max(1, rows)
    return preferredFont.uiFont.lineHeight * CGFloat(n) + 2 * contentPadding
  }

  func shouldUpdateLayout(_ oldModel: Self) -> Bool {
    size != oldModel.size || font != oldModel.font
    || minRows != oldModel.minRows || maxRows != oldModel.maxRows
  }

  var autocorrectionType: UITextAutocorrectionType {
    isAutocorrectionEnabled ? .yes : .no
  }
}

// MARK: - TextInputHeightCalculator

struct TextInputHeightCalculator {
  private static let textView = UITextView()

  static func preferredHeight(for text: String, model: TextInputVM, width: CGFloat) -> CGFloat {
    textView.text = text
    style(textView, with: model)
    let targetSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
    return textView.sizeThatFits(targetSize).height
  }

  private static func style(_ textView: UITextView, with model: TextInputVM) {
    textView.isScrollEnabled = false
    textView.font = model.preferredFont.uiFont
    textView.textContainerInset = .init(top: model.contentPadding, left: model.contentPadding,
                                        bottom: model.contentPadding, right: model.contentPadding)
    textView.textContainer.lineFragmentPadding = 0
  }
}

// MARK: - SUTextInput

public struct SUTextInput<FocusValue: Hashable>: View {
  public var model: TextInputVM
  @Binding public var text: String
  public let globalFocus: FocusState<FocusValue>.Binding?
  public let localFocus: FocusValue
  public var onTextChange: ((String) -> Void)?
  public var onSubmit: (() -> Void)?
  public var onFocusChange: ((Bool) -> Void)?

  @State private var textEditorPreferredHeight: CGFloat = 0

  public init(
    text: Binding<String>,
    globalFocus: FocusState<FocusValue>.Binding,
    localFocus: FocusValue,
    model: TextInputVM = .init(),
    onTextChange: ((String) -> Void)? = nil,
    onSubmit: (() -> Void)? = nil,
    onFocusChange: ((Bool) -> Void)? = nil
  ) {
    self._text = text
    self.globalFocus = globalFocus
    self.localFocus = localFocus
    self.model = model
    self.onTextChange = onTextChange
    self.onSubmit = onSubmit
    self.onFocusChange = onFocusChange
  }

  public var body: some View {
    ZStack(alignment: .topLeading) {
      TextEditor(text: $text)
        .tiContentMargins(model.contentPadding)
        .tiTransparentScrollBackground()
        .frame(
          minHeight: model.minTextInputHeight,
          idealHeight: max(model.minTextInputHeight,
                           min(model.maxTextInputHeight, textEditorPreferredHeight)),
          maxHeight:   max(model.minTextInputHeight,
                           min(model.maxTextInputHeight, textEditorPreferredHeight))
        )
        .lineSpacing(0)
        .font(model.preferredFont.font)
        .foregroundStyle(model.foregroundColor.color)
        .tint(model.tintColor.color)
        .tiApplyFocus(globalFocus: globalFocus, localFocus: localFocus)
        .disabled(!model.isEnabled)
        .keyboardType(model.keyboardType)
        .submitLabel(model.submitType.submitLabel)
        .autocorrectionDisabled(!model.isAutocorrectionEnabled)
        .textInputAutocapitalization(model.autocapitalization.textInputAutocapitalization)

      if let placeholder = model.placeholder, text.isEmpty {
        Text(placeholder)
          .font(model.preferredFont.font)
          .foregroundStyle(model.placeholderColor.color)
          .padding(model.contentPadding)
      }
    }
    .background(
      GeometryReader { geometry in
        model.backgroundColor.color
          .onAppear {
            textEditorPreferredHeight = TextInputHeightCalculator.preferredHeight(
              for: text, model: model, width: geometry.size.width)
          }
          .onChange(of: text) { newText in
            // Detect submit via newline for non-multiline inputs
            if model.submitType != .return, newText.hasSuffix("\n"), let onSubmit {
              text = String(newText.dropLast())
              onSubmit()
              return
            }
            textEditorPreferredHeight = TextInputHeightCalculator.preferredHeight(
              for: newText, model: model, width: geometry.size.width)
            onTextChange?(newText)
          }
          .onChange(of: model) { [oldModel = model] newModel in
            if newModel.shouldUpdateLayout(oldModel) {
              textEditorPreferredHeight = TextInputHeightCalculator.preferredHeight(
                for: text, model: newModel, width: geometry.size.width)
            }
          }
          .onChange(of: geometry.size.width) { w in
            textEditorPreferredHeight = TextInputHeightCalculator.preferredHeight(
              for: text, model: model, width: w)
          }
      }
    )
    .onChange(of: globalFocus?.wrappedValue) { newValue in
      if let newValue {
        onFocusChange?(newValue == localFocus)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: model.adaptedCornerRadius(), style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: model.adaptedCornerRadius(), style: .continuous)
        .strokeBorder(model.borderColor.color, lineWidth: model.borderWidth)
    )
  }
}

// MARK: - Private View Helpers

extension View {
  fileprivate func tiTransparentScrollBackground() -> some View {
    if #available(iOS 16.0, *) {
      return AnyView(self.scrollContentBackground(.hidden))
    } else {
      return AnyView(self.onAppear { UITextView.appearance().backgroundColor = .clear })
    }
  }

  fileprivate func tiContentMargins(_ value: CGFloat) -> some View {
    let defaultMargin: CGFloat = 5
    return self.onAppear {
      UITextView.appearance().textContainerInset = .init(
        top: value, left: value - defaultMargin, bottom: value, right: value - defaultMargin)
      UITextView.appearance().textContainer.lineFragmentPadding = 0
    }
  }

  @ViewBuilder
  fileprivate func tiApplyFocus<FV: Hashable>(
    globalFocus: FocusState<FV>.Binding?,
    localFocus: FV
  ) -> some View {
    if let globalFocus {
      self.focused(globalFocus, equals: localFocus)
    } else {
      self
    }
  }
}

// MARK: - Bool Focus Convenience

extension SUTextInput where FocusValue == Bool {
  public init(
    text: Binding<String>,
    isFocused: FocusState<Bool>.Binding,
    model: TextInputVM = .init(),
    onTextChange: ((String) -> Void)? = nil,
    onSubmit: (() -> Void)? = nil,
    onFocusChange: ((Bool) -> Void)? = nil
  ) {
    self._text = text
    self.globalFocus = isFocused
    self.localFocus = true
    self.model = model
    self.onTextChange = onTextChange
    self.onSubmit = onSubmit
    self.onFocusChange = onFocusChange
  }

  public init(
    text: Binding<String>,
    model: TextInputVM = .init(),
    onTextChange: ((String) -> Void)? = nil,
    onSubmit: (() -> Void)? = nil,
    onFocusChange: ((Bool) -> Void)? = nil
  ) {
    self._text = text
    self.globalFocus = nil
    self.localFocus = true
    self.model = model
    self.onTextChange = onTextChange
    self.onSubmit = onSubmit
    self.onFocusChange = onFocusChange
  }
}
