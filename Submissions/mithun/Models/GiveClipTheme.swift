import SwiftUI

extension Color {
    static let giveGreen = Color(red: 0x2E / 255.0, green: 0x7D / 255.0, blue: 0x32 / 255.0)
    static let giveLightGreen = Color(red: 0xF1 / 255.0, green: 0xF8 / 255.0, blue: 0xE9 / 255.0)
    static let giveTextPrimary = Color(red: 0x21 / 255.0, green: 0x21 / 255.0, blue: 0x21 / 255.0)
    static let giveTextSecondary = Color(red: 0x75 / 255.0, green: 0x75 / 255.0, blue: 0x75 / 255.0)
}

extension ShapeStyle where Self == Color {
    static var giveGreen: Color { .init(red: 0x2E / 255.0, green: 0x7D / 255.0, blue: 0x32 / 255.0) }
    static var giveLightGreen: Color { .init(red: 0xF1 / 255.0, green: 0xF8 / 255.0, blue: 0xE9 / 255.0) }
    static var giveTextPrimary: Color { .init(red: 0x21 / 255.0, green: 0x21 / 255.0, blue: 0x21 / 255.0) }
    static var giveTextSecondary: Color { .init(red: 0x75 / 255.0, green: 0x75 / 255.0, blue: 0x75 / 255.0) }
}
