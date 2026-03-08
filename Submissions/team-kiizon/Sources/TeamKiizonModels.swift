// TeamKiizonModels.swift
import SwiftUI

// MARK: - Language

private enum Language: String {
    case en, zh, fr
}

// MARK: - Order Mode

private enum OrderMode: CaseIterable {
    case dineIn, takeout, delivery

    func label(_ lang: Language) -> String {
        switch self {
        case .dineIn:    return lang == .zh ? "堂食" : lang == .fr ? "Sur place"   : "Dine In"
        case .takeout:   return lang == .zh ? "外带" : lang == .fr ? "A emporter"  : "Takeout"
        case .delivery:  return lang == .zh ? "外卖" : lang == .fr ? "Livraison"   : "Delivery"
        }
    }

    var icon: String {
        switch self {
        case .dineIn:   return "fork.knife"
        case .takeout:  return "bag.fill"
        case .delivery: return "bicycle"
        }
    }
}

// MARK: - Menu Categories

private enum MenuCategory: String, CaseIterable {
    case recommended
    case signatureBuns
    case appetizers
    case noodlesRice
    case friedChicken
    case warmCongee
    case drinks

    func displayName(_ lang: Language) -> String {
        switch self {
        case .recommended:   return lang == .zh ? "为您推荐"   : lang == .fr ? "Pour Vous"        : "For You"
        case .signatureBuns: return lang == .zh ? "招牌包"     : lang == .fr ? "Brioches Maison"  : "Signature Buns"
        case .appetizers:    return lang == .zh ? "开胃小食"   : lang == .fr ? "Entrees"          : "Appetizers"
        case .noodlesRice:   return lang == .zh ? "面食饭食"   : lang == .fr ? "Nouilles & Riz"   : "Noodles & Rice"
        case .friedChicken:  return lang == .zh ? "炸鸡"      : lang == .fr ? "Poulet Frit"      : "Fried Chicken"
        case .warmCongee:    return lang == .zh ? "暖心粥粉"   : lang == .fr ? "Soupes Chaudes"   : "Congee & Noodles"
        case .drinks:        return lang == .zh ? "饮品"      : lang == .fr ? "Boissons"         : "Drinks"
        }
    }

    var icon: String {
        switch self {
        case .recommended:   return "sparkles"
        case .signatureBuns: return "circle.grid.3x3.fill"
        case .appetizers:    return "leaf"
        case .noodlesRice:   return "fork.knife"
        case .friedChicken:  return "bolt.fill"
        case .warmCongee:    return "thermometer.medium"
        case .drinks:        return "cup.and.saucer.fill"
        }
    }
}

// MARK: - Data Models

private struct BistroMenuItem: Identifiable {
    let id = UUID()
    let name: String
    let nameZH: String
    let nameFR: String
    let description: String
    let descriptionZH: String
    let descriptionFR: String
    let price: Double
    let category: MenuCategory
    let systemImage: String
    let localImagePath: String?
    let allergens: [String]
    let calories: Int

    func displayName(_ lang: Language) -> String {
        switch lang { case .en: return name; case .zh: return nameZH; case .fr: return nameFR }
    }

    func displayDescription(_ lang: Language) -> String {
        switch lang { case .en: return description; case .zh: return descriptionZH; case .fr: return descriptionFR }
    }
}

private struct RestaurantCartEntry: Identifiable {
    let id = UUID()
    let menuItem: BistroMenuItem
    var quantity: Int
    var modifications: String = ""
}
