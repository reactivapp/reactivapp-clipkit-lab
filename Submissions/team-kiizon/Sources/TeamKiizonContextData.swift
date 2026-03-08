// TeamKiizonContextData.swift
import SwiftUI

// MARK: - Context Models

private enum WeatherCondition: String {
    case hot, cold, rainy, snowy, mild

    func label(_ lang: Language) -> String {
        switch self {
        case .hot:   return lang == .zh ? "炎热" : lang == .fr ? "Journee chaude"  : "Hot day"
        case .cold:  return lang == .zh ? "寒冷" : lang == .fr ? "Froid dehors"    : "Cold out"
        case .rainy: return lang == .zh ? "下雨" : lang == .fr ? "Jour de pluie"   : "Rainy day"
        case .snowy: return lang == .zh ? "下雪" : lang == .fr ? "Enneige"         : "Snowy"
        case .mild:  return lang == .zh ? "晴朗" : lang == .fr ? "Temps agreable"  : "Nice out"
        }
    }

    var icon: String {
        switch self {
        case .hot:   return "sun.max.fill"
        case .cold:  return "thermometer.snowflake"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "snowflake"
        case .mild:  return "cloud.sun.fill"
        }
    }

    var chipColor: Color {
        switch self {
        case .hot:   return .orange
        case .cold:  return .cyan
        case .rainy: return .indigo
        case .snowy: return .teal
        case .mild:  return .green
        }
    }

    var boostedItemNames: Set<String> {
        switch self {
        case .hot:
            return ["Sour Plum Drink", "Chrysanthemum Wolfberry Tea", "Sweet Soy Milk",
                    "Pickled Vinegar Peanuts", "Spicy Vinegar Tofu Skin"]
        case .cold, .snowy:
            return ["Classic Beef Noodle Soup", "Braised Beef Noodle Soup",
                    "Spicy & Sour Glass Noodle Soup", "Century Egg & Lean Pork Congee",
                    "Sweet Soy Milk", "Mom's Soup Dumplings"]
        case .rainy:
            return ["Classic Beef Noodle Soup", "Braised Beef Noodle Soup",
                    "Century Egg & Lean Pork Congee", "Spicy & Sour Glass Noodle Soup",
                    "Mom's Soup Dumplings"]
        case .mild:
            return []
        }
    }
}

private enum Holiday: String {
    case canadaDay      = "canada_day"
    case thanksgiving   = "thanksgiving"
    case christmas      = "christmas"
    case valentines     = "valentines"
    case halloween      = "halloween"
    case victoriaDay    = "victoria_day"
    case newYears       = "new_years"
    case chineseNewYear = "cny"

    func label(_ lang: Language) -> String {
        switch self {
        case .canadaDay:      return lang == .zh ? "加拿大国庆" : lang == .fr ? "Fete du Canada"    : "Canada Day"
        case .thanksgiving:   return lang == .zh ? "感恩节"    : lang == .fr ? "Action de graces"  : "Thanksgiving"
        case .christmas:      return lang == .zh ? "圣诞节"    : lang == .fr ? "Noel"              : "Christmas"
        case .valentines:     return lang == .zh ? "情人节"    : lang == .fr ? "Saint-Valentin"    : "Valentine's Day"
        case .halloween:      return lang == .zh ? "万圣节"    : lang == .fr ? "Halloween"         : "Halloween"
        case .victoriaDay:    return lang == .zh ? "维多利亚日" : lang == .fr ? "Fete de Victoria"  : "Victoria Day"
        case .newYears:       return lang == .zh ? "元旦"      : lang == .fr ? "Jour de l'An"      : "New Year's"
        case .chineseNewYear: return lang == .zh ? "春节"      : lang == .fr ? "Nouvel An Chinois" : "Chinese New Year"
        }
    }

    var icon: String {
        switch self {
        case .canadaDay:      return "maple.leaf"
        case .thanksgiving:   return "leaf.fill"
        case .christmas:      return "snowflake"
        case .valentines:     return "heart.fill"
        case .halloween:      return "moon.stars.fill"
        case .victoriaDay:    return "crown.fill"
        case .newYears:       return "sparkles"
        case .chineseNewYear: return "flame.fill"
        }
    }

    var chipColor: Color {
        switch self {
        case .canadaDay:      return .red
        case .thanksgiving:   return .orange
        case .christmas:      return .green
        case .valentines:     return .pink
        case .halloween:      return .purple
        case .victoriaDay:    return .blue
        case .newYears:       return .yellow
        case .chineseNewYear: return .red
        }
    }

    var featuredItemNames: Set<String> {
        switch self {
        case .canadaDay:
            return ["Braised Pork Pan-Fried Buns", "Magic Fried Chicken Wings",
                    "Sour Plum Drink", "Mom's Soup Dumplings", "Crispy Fried Chicken Bites"]
        case .thanksgiving:
            return ["Braised Beef Noodle Soup", "Classic Beef Noodle Soup",
                    "Century Egg & Lean Pork Congee", "Grilled Pork Belly Egg on Rice"]
        case .christmas:
            return ["Braised Pork Pan-Fried Buns", "Mom's Soup Dumplings",
                    "Chrysanthemum Wolfberry Tea", "Century Egg & Lean Pork Congee"]
        case .valentines:
            return ["Mom's Soup Dumplings", "Siu Mai Bamboo & Sticky Rice",
                    "Chrysanthemum Wolfberry Tea", "Sour Plum Drink"]
        case .halloween:
            return ["Spicy & Sour Glass Noodle Soup", "Magic Fried Chicken Wings",
                    "Crispy Fried Chicken Bites", "Spicy Vinegar Tofu Skin"]
        case .victoriaDay:
            return ["Magic Fried Chicken Wings", "Braised Pork Pan-Fried Buns",
                    "Fresh Pork Pan-Fried Buns", "Sour Plum Drink"]
        case .newYears:
            return ["Braised Pork Pan-Fried Buns", "Mom's Soup Dumplings",
                    "Sweet Soy Milk", "Classic Beef Noodle Soup"]
        case .chineseNewYear:
            return ["Braised Pork Pan-Fried Buns", "Fresh Pork Pan-Fried Buns",
                    "Mom's Soup Dumplings", "Siu Mai Bamboo & Sticky Rice",
                    "Sour Plum Drink", "Century Egg & Lean Pork Congee"]
        }
    }
}

private struct MenuContext {
    let weather: WeatherCondition?
    let holiday: Holiday?
    let hour: Int
}
