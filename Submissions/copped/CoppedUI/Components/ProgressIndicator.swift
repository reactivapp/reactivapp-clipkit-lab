import SwiftUI

// MARK: - ProgressIndicatorView
// Source: https://github.com/exyte/ProgressIndicatorView

public struct ProgressIndicatorView: View {

  public enum IndicatorType {
    case `default`(progress: Binding<CGFloat>)
    case bar(progress: Binding<CGFloat>, backgroundColor: Color = .clear)
    case impulseBar(progress: Binding<CGFloat>, backgroundColor: Color = .clear)
    case dashBar(progress: Binding<CGFloat>, numberOfItems: Int = 8, backgroundColor: Color = .clear)
    case circle(progress: Binding<CGFloat>, lineWidth: CGFloat, strokeColor: Color, backgroundColor: Color = .clear)
  }

  @Binding var isVisible: Bool
  var type: IndicatorType

  public init(isVisible: Binding<Bool>, type: IndicatorType) {
    self._isVisible = isVisible
    self.type = type
  }

  public var body: some View {
    if isVisible {
      indicator
    } else {
      EmptyView()
    }
  }

  private var indicator: some View {
    ZStack {
      switch type {
      case .bar(let progress, let backgroundColor):
        PIBarView(progress: progress, backgroundColor: backgroundColor)
      case .impulseBar(let progress, let backgroundColor):
        PIImpulseBarView(progress: progress, backgroundColor: backgroundColor)
      case .`default`(let progress):
        PIDefaultSectorView(progress: progress)
      case .circle(let progress, let lineWidth, let strokeColor, let backgroundColor):
        PICircleView(progress: progress, lineWidth: lineWidth, strokeColor: strokeColor, backgroundColor: backgroundColor)
      case .dashBar(let progress, let numberOfItems, let backgroundColor):
        PIDashBarView(progress: progress, numberOfItems: numberOfItems, backgroundColor: backgroundColor)
      }
    }
  }
}

// MARK: - Bar

private struct PIBarView: View {
  @Binding var progress: CGFloat
  let backgroundColor: Color

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule()
          .foregroundColor(backgroundColor)
        Capsule()
          .frame(width: min(max(geometry.size.width * progress, 0), geometry.size.width))
          .animation(.easeIn, value: progress)
      }
    }
  }
}

// MARK: - Impulse Bar

private struct PIImpulseBarView: View {
  @Binding var progress: CGFloat
  let backgroundColor: Color

  @State private var size: CGSize = .zero
  @State private var progressWidth: CGFloat = 0
  @State private var impulseOffset: CGFloat = -200.0
  private let animation: Animation = .linear(duration: 1.5).repeatForever(autoreverses: false)
  private let gradientWidth: CGFloat = 100.0
  private let gradient = Gradient(colors: [
    .white.opacity(0.0),
    .white.opacity(0.25),
    .white.opacity(0.5),
    .white.opacity(0.75),
    .white.opacity(0.85),
    .white.opacity(0.75),
    .white.opacity(0.5),
    .white.opacity(0.25),
    .white.opacity(0.0)
  ])

  var body: some View {
    Capsule()
      .fill(backgroundColor)
      .modifier(PISizeGetter(size: $size))
      .overlay(PICapsuleProgressView(width: progressWidth, height: size.height))
      .overlay(gradientView)
      .animation(.easeIn, value: progressWidth)
      .onChange(of: size) { size in
        progressWidth = fmin(fmax(size.width * progress, 0), size.width)
        withAnimation(animation) { impulseOffset = size.width }
      }
      .onChange(of: progress) { progress in
        progressWidth = fmin(fmax(size.width * progress, 0), size.width)
      }
  }

  private var gradientView: some View {
    LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
      .frame(width: gradientWidth)
      .frame(maxWidth: .infinity, alignment: .leading)
      .offset(x: impulseOffset)
      .mask(PICapsuleProgressView(width: progressWidth, height: size.height))
  }
}

private struct PICapsuleProgressView: View {
  let width: CGFloat
  let height: CGFloat

  var body: some View {
    Capsule()
      .frame(width: width < height ? height : width)
      .mask(
        Capsule()
          .frame(width: width < height ? height : width)
          .offset(x: width < height ? width - height : 0)
      )
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct PISizeGetter: ViewModifier {
  @Binding var size: CGSize

  func body(content: Content) -> some View {
    content.background(
      GeometryReader { proxy -> Color in
        if proxy.size != self.size {
          DispatchQueue.main.async { self.size = proxy.size }
        }
        return Color.clear
      }
    )
  }
}

// MARK: - Dash Bar

private struct PIDashBarView: View {
  @Binding var progress: CGFloat
  let numberOfItems: Int
  let backgroundColor: Color
  private let spacing: CGFloat = 4.0

  var body: some View {
    GeometryReader { geometry in
      let itemWidth = (geometry.size.width - CGFloat(numberOfItems - 1) * spacing) / CGFloat(numberOfItems)
      HStack(spacing: spacing) {
        ForEach(0..<numberOfItems, id: \.self) { index in
          PIDashBarItemView(
            backgroundColor: backgroundColor,
            needToFill: progress > (1 / CGFloat(numberOfItems) * CGFloat(index)),
            width: itemWidth
          )
        }
      }
    }
  }
}

private struct PIDashBarItemView: View {
  let backgroundColor: Color
  let needToFill: Bool
  let width: CGFloat

  var body: some View {
    ZStack(alignment: .leading) {
      Capsule().foregroundColor(backgroundColor)
      Capsule()
        .frame(width: needToFill ? width : 0.0)
        .animation(.easeIn, value: needToFill)
    }
  }
}

// MARK: - Circle

private struct PICircleView: View {
  @Binding var progress: CGFloat
  let lineWidth: CGFloat
  let strokeColor: Color
  let backgroundColor: Color

  var body: some View {
    GeometryReader { _ in
      ZStack(alignment: .leading) {
        PIArc(startAngle: .radians(-.pi / 2), endAngle: .radians(.pi * 3 / 2))
          .stroke(backgroundColor, style: .init(lineWidth: lineWidth, lineCap: .butt, lineJoin: .miter))
        PIArc(startAngle: .radians(-.pi / 2), endAngle: .radians(-.pi / 2 + .pi * 3 / 2 * progress))
          .stroke(strokeColor, style: .init(lineWidth: lineWidth, lineCap: .butt, lineJoin: .miter))
          .animation(.easeIn, value: progress)
      }
    }
  }
}

private struct PIArc: Shape {
  var startAngle: Angle
  var endAngle: Angle
  var clockwise: Bool = false

  var animatableData: CGFloat {
    get { CGFloat(endAngle.radians) }
    set { endAngle = Angle(radians: newValue) }
  }

  func path(in rect: CGRect) -> Path {
    Path { path in
      path.addArc(
        center: .init(x: rect.midX, y: rect.midY),
        radius: rect.width / 2.0,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: clockwise
      )
    }
  }
}

// MARK: - Default Sector

private struct PIDefaultSectorView: View {
  @Binding var progress: CGFloat
  private let count: Int = 8
  @State private var rotationAngle: Angle = .radians(0)

  var body: some View {
    GeometryReader { geometry in
      Group {
        ForEach(0..<count, id: \.self) { index in
          PIDefaultSectorItemView(index: index, count: count, size: geometry.size)
            .opacity(progress * 2.0 - CGFloat(index) * 1 / CGFloat(count) - 0.1)
            .animation(.linear, value: progress)
        }
      }
      .rotationEffect(rotationAngle)
      .frame(width: geometry.size.width, height: geometry.size.height)
      .onChange(of: progress) { _ in
        if progress > 1.0 {
          withAnimation(.linear(duration: 1)) { rotationAngle = .radians(.pi * 2.0) }
        } else {
          rotationAngle = .zero
        }
      }
    }
  }
}

private struct PIDefaultSectorItemView: View {
  let index: Int
  let count: Int
  let size: CGSize

  var body: some View {
    let height = size.height / 3.2
    let width = height / 2
    let angle = 2 * .pi / CGFloat(count) * CGFloat(index) - .pi / 2
    let x = (size.width / 2 - height / 2) * cos(angle)
    let y = (size.height / 2 - height / 2) * sin(angle)

    return RoundedRectangle(cornerRadius: width / 2 + 1)
      .frame(width: width, height: height)
      .rotationEffect(.radians(angle + .pi / 2))
      .offset(x: x, y: y)
  }
}
