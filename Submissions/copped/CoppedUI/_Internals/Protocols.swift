import Foundation

// MARK: - Initializable

/// A type that can be initialized with an empty initializer or with a transformation closure.
public protocol Initializable {
  init()
  init(_ transform: (_ value: inout Self) -> Void)
}

extension Initializable {
  public init(_ transform: (_ value: inout Self) -> Void) {
    var defaultValue = Self()
    transform(&defaultValue)
    self = defaultValue
  }
}

// MARK: - Updatable

/// A type whose values can be updated or can create an updated copy.
public protocol Updatable {
  func updating(_ transform: (_ value: inout Self) -> Void) -> Self
  mutating func update(_ transform: (_ value: inout Self) -> Void)
}

extension Updatable {
  public func updating(_ transform: (_ value: inout Self) -> Void) -> Self {
    var copy = self
    transform(&copy)
    return copy
  }

  public mutating func update(_ transform: (_ value: inout Self) -> Void) {
    transform(&self)
  }
}

// MARK: - ComponentVM

/// A protocol that defines a component view model.
public protocol ComponentVM: Equatable, Initializable, Updatable {}
