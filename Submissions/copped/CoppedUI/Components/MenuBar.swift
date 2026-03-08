import SwiftUI

// MARK: - MenuBarItem

public struct MenuBarItem: Identifiable {
  public let id: Int
  public let icon: String
  public let label: String

  public init(id: Int, icon: String, label: String) {
    self.id = id
    self.icon = icon
    self.label = label
  }
}

// MARK: - MenuBar

/// Apple Music-style slim pill menu bar with an integrated liquid glass action button.
/// Tight vertical padding creates the refined "pill" aesthetic.
public struct MenuBar: View {
  let items: [MenuBarItem]
  @Binding var selection: Int

  var actionIcon: String = "plus"
  var actionLabel: String? = nil
  var accentColor: Color = UniversalColor.accent.color
  var inactiveColor: Color = .primary.opacity(Theme.current.layout.overlay.inactiveContent)
  var blurStyle: UIBlurEffect.Style = Theme.current.layout.glass.blurStyle
  var bottomPadding: CGFloat = 24
  var useLiquidGlass: Bool = false
  var onAction: (() -> Void)? = nil
  var onSelectionChanged: ((Int) -> Void)? = nil

  public init(
    items: [MenuBarItem],
    selection: Binding<Int>,
    actionIcon: String = "plus",
    actionLabel: String? = nil,
    accentColor: Color = UniversalColor.accent.color,
    bottomPadding: CGFloat = 24,
    useLiquidGlass: Bool = false,
    onAction: (() -> Void)? = nil,
    onSelectionChanged: ((Int) -> Void)? = nil
  ) {
    self.items = items
    self._selection = selection
    self.actionIcon = actionIcon
    self.actionLabel = actionLabel
    self.accentColor = accentColor
    self.bottomPadding = bottomPadding
    self.useLiquidGlass = useLiquidGlass
    self.onAction = onAction
    self.onSelectionChanged = onSelectionChanged
  }

  public var body: some View {
    let content = VStack(spacing: 16) {
      // Liquid glass action button above
      actionButton

      // Navigation pills below
      navigationPills
    }
    .padding(.horizontal, 24)
    .padding(.bottom, bottomPadding)
    .contentShape(Rectangle())
    .background(Color.black.opacity(0.001))
    .onTapGesture {} // blocks touch pass-through to views behind

    if #available(iOS 26.0, *) {
      GlassEffectContainer {
        content
      }
    } else {
      content
    }
  }

  private var navigationPills: some View {
    HStack(spacing: 2) {
      ForEach(items) { item in
        MenuBarPill(
          item: item,
          isSelected: selection == item.id,
          accentColor: accentColor,
          inactiveColor: inactiveColor
        ) {
          withAnimation(Theme.current.layout.motion.snappy.animation) {
            selection = item.id
          }
          onSelectionChanged?(item.id)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 64)
    .liquidGlass(
      enabled: true,
      cornerRadius: 32,
      blurStyle: blurStyle,
      tint: Theme.Layout.Glass.prominent.tint,
      borderColor: Theme.Layout.Glass.prominent.border,
      borderWidth: Theme.current.layout.glass.borderWidth
    )
    .shadow(
      color: Theme.current.layout.glass.shadowColor,
      radius: Theme.current.layout.glass.shadowRadius,
      x: Theme.current.layout.glass.shadowOffset.width,
      y: Theme.current.layout.glass.shadowOffset.height
    )
  }

  private var actionButton: some View {
    Button {
      onAction?()
    } label: {
      HStack(spacing: 6) {
        Image(systemName: actionIcon)
          .font(.system(size: 15, weight: .semibold))
        if let actionLabel {
          Text(actionLabel)
            .font(.custom(Manrope.semiBold, size: 13))
        }
      }
      .foregroundStyle(.primary)
      .frame(maxWidth: .infinity)
      .frame(height: 48)
    }
    .buttonStyle(.plain)
    .liquidGlass(
      enabled: true,
      cornerRadius: 24,
      blurStyle: blurStyle,
      tint: Theme.Layout.Glass.prominent.tint,
      borderColor: Theme.Layout.Glass.prominent.border,
      borderWidth: Theme.current.layout.glass.borderWidth
    )
    .shadow(
      color: Theme.current.layout.glass.shadowColor,
      radius: Theme.current.layout.glass.shadowRadius,
      x: Theme.current.layout.glass.shadowOffset.width,
      y: Theme.current.layout.glass.shadowOffset.height
    )
  }
}

// MARK: - MenuBarPill

private struct MenuBarPill: View {
  let item: MenuBarItem
  let isSelected: Bool
  let accentColor: Color
  let inactiveColor: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: item.icon)
          .font(.system(size: 18, weight: isSelected ? .semibold : .regular))

        Text(item.label)
          .font(.custom(Manrope.medium, size: 10))
      }
      .foregroundStyle(isSelected ? accentColor : inactiveColor)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 7)
    }
    .buttonStyle(.plain)
    .animation(Theme.current.layout.motion.snappy.animation, value: isSelected)
  }
}

// MARK: - MenuBarContainer

/// Wraps content with a MenuBar overlay at the bottom.
public struct MenuBarContainer<Content: View>: View {
  @Binding var selection: Int
  let items: [MenuBarItem]
  let actionIcon: String
  let actionLabel: String?
  let useLiquidGlass: Bool
  let onAction: (() -> Void)?
  let onSelectionChanged: ((Int) -> Void)?
  let content: (Int) -> Content

  public init(
    selection: Binding<Int>,
    items: [MenuBarItem],
    actionIcon: String = "plus",
    actionLabel: String? = nil,
    useLiquidGlass: Bool = false,
    onAction: (() -> Void)? = nil,
    onSelectionChanged: ((Int) -> Void)? = nil,
    @ViewBuilder content: @escaping (Int) -> Content
  ) {
    self._selection = selection
    self.items = items
    self.actionIcon = actionIcon
    self.actionLabel = actionLabel
    self.useLiquidGlass = useLiquidGlass
    self.onAction = onAction
    self.onSelectionChanged = onSelectionChanged
    self.content = content
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      content(selection)
        .ignoresSafeArea()

      MenuBar(
        items: items,
        selection: $selection,
        actionIcon: actionIcon,
        actionLabel: actionLabel,
        useLiquidGlass: useLiquidGlass,
        onAction: onAction,
        onSelectionChanged: onSelectionChanged
      )
      .zIndex(1)
    }
    .ignoresSafeArea()
  }
}
