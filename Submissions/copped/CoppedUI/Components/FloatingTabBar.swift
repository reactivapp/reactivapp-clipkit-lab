import SwiftUI

// MARK: - TabBarItem

public struct TabBarItem: Identifiable {
  public let id: Int
  public let icon: String
  public let label: String

  public init(id: Int, icon: String, label: String) {
    self.id = id
    self.icon = icon
    self.label = label
  }
}

// MARK: - FloatingTabBar

/// Uber-style floating translucent pill tab bar.
/// Hovers above content with a glass blur background.
public struct FloatingTabBar: View {
  let items: [TabBarItem]
  @Binding var selection: Int

  var accentColor: Color = UniversalColor.accent.color
  var inactiveColor: Color = .white.opacity(Theme.current.layout.overlay.inactiveContent)
  var blurStyle: UIBlurEffect.Style = Theme.current.layout.glass.blurStyle
  var bottomPadding: CGFloat = 24
  var useLiquidGlass: Bool = false
  var onSelectionChanged: ((Int) -> Void)? = nil

  public init(
    items: [TabBarItem],
    selection: Binding<Int>,
    accentColor: Color = UniversalColor.accent.color,
    inactiveColor: Color = .white.opacity(Theme.current.layout.overlay.inactiveContent),
    bottomPadding: CGFloat = 24,
    useLiquidGlass: Bool = false,
    onSelectionChanged: ((Int) -> Void)? = nil
  ) {
    self.items = items
    self._selection = selection
    self.accentColor = accentColor
    self.inactiveColor = inactiveColor
    self.bottomPadding = bottomPadding
    self.useLiquidGlass = useLiquidGlass
    self.onSelectionChanged = onSelectionChanged
  }

  public var body: some View {
    HStack(spacing: 0) {
      ForEach(items) { item in
        TabBarButton(
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
    .padding(.horizontal, 8)
    .padding(.vertical, 10)
    .liquidGlass(
      enabled: useLiquidGlass,
      blurStyle: blurStyle,
      tint: Theme.Layout.Glass.subtle.tint,
      borderColor: Theme.Layout.Glass.subtle.border,
      useCapsule: true
    )
    .shadow(
      color: Theme.Layout.Glass.subtle.shadowColor,
      radius: Theme.Layout.Glass.subtle.shadowRadius,
      x: Theme.Layout.Glass.subtle.shadowOffset.width,
      y: Theme.Layout.Glass.subtle.shadowOffset.height
    )
    .padding(.horizontal, 32)
    .padding(.bottom, bottomPadding)
  }
}

// MARK: - TabBarButton

private struct TabBarButton: View {
  let item: TabBarItem
  let isSelected: Bool
  let accentColor: Color
  let inactiveColor: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: item.icon)
          .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
          .foregroundStyle(isSelected ? accentColor : inactiveColor)
          .scaleEffect(isSelected ? 1.1 : 1.0)

        Text(item.label)
          .font(.custom(Manrope.medium, size: 10))
          .foregroundStyle(isSelected ? accentColor : inactiveColor)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 4)
    }
    .buttonStyle(.plain)
    .animation(Theme.current.layout.motion.snappy.animation, value: isSelected)
  }
}

// MARK: - FloatingTabBarContainer

/// Wraps your page views with a floating tab bar overlay at the bottom.
public struct FloatingTabBarContainer<Content: View>: View {
  @Binding var selection: Int
  let items: [TabBarItem]
  let onSelectionChanged: ((Int) -> Void)?
  let content: (Int) -> Content

  public init(
    selection: Binding<Int>,
    items: [TabBarItem],
    onSelectionChanged: ((Int) -> Void)? = nil,
    @ViewBuilder content: @escaping (Int) -> Content
  ) {
    self._selection = selection
    self.items = items
    self.onSelectionChanged = onSelectionChanged
    self.content = content
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      content(selection)
        .ignoresSafeArea()

      FloatingTabBar(items: items, selection: $selection, onSelectionChanged: onSelectionChanged)
    }
    .ignoresSafeArea()
  }
}
