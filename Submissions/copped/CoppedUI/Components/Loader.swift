import SwiftUI

// MARK: - LoadingVM

public struct LoadingVM: ComponentVM {
  /// The color of the spinner.
  public var color: ComponentColor?
  /// The line cap style of the arc.
  public var lineCap: LineCap = .round
  /// Optional fixed line width. Auto-calculated from size if nil.
  public var lineWidth: CGFloat?
  /// Predefined size. Pass nil to fill available space.
  public var size: ComponentSize? = .medium

  public init() {}
}

extension LoadingVM {
  var preferredColor: UniversalColor {
    color?.main ?? .accent
  }
  var loadingLineWidth: CGFloat {
    if let lineWidth { return lineWidth }
    switch size {
    case .small:  return 2.5
    case .large:  return 3.5
    default:      return 3.0
    }
  }
  var preferredSize: CGSize? {
    switch size {
    case .small:  return CGSize(width: 24, height: 24)
    case .medium: return CGSize(width: 36, height: 36)
    case .large:  return CGSize(width: 48, height: 48)
    case nil:     return nil
    }
  }
  func radius(for size: CGSize) -> CGFloat {
    min(size.width, size.height) / 2 - loadingLineWidth / 2
  }
  func center(for size: CGSize) -> CGPoint {
    CGPoint(x: size.width / 2, y: size.height / 2)
  }
}

// MARK: - SULoading

/// A spinning arc loading indicator.
/// Replace the body with your custom spinner when ready.
public struct SULoading: View {
  public var model: LoadingVM
  @State private var rotation: Double = 0

  public init(model: LoadingVM = .init()) {
    self.model = model
  }

  public var body: some View {
    GeometryReader { geometry in
      let sz = model.preferredSize ?? geometry.size
      let center = model.center(for: sz)
      let radius = model.radius(for: sz)

      ZStack {
        // Track ring
        Circle()
          .stroke(model.preferredColor.color.opacity(0.15), lineWidth: model.loadingLineWidth)

        // Spinning arc (75% of circle)
        Path { path in
          path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(270),
            clockwise: false
          )
        }
        .stroke(
          model.preferredColor.color,
          style: StrokeStyle(lineWidth: model.loadingLineWidth, lineCap: model.lineCap.cgLineCap)
        )
        .rotationEffect(.degrees(rotation))
        .onAppear {
          withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
            rotation = 360
          }
        }
      }
      .frame(width: sz.width, height: sz.height)
    }
    .frame(width: model.preferredSize?.width, height: model.preferredSize?.height)
  }
}
