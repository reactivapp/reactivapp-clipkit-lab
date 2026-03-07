//  ClipBetModels.swift
//  ClipBet — Hyperlocal Prediction Markets via App Clips
//

import Foundation
import SwiftUI

// MARK: - Design System Colors

enum ClipBetColors {
    static let bg           = Color(red: 250/255, green: 248/255, blue: 245/255) // #FAF8F5
    static let surface      = Color(red: 240/255, green: 236/255, blue: 228/255) // #F0ECE4
    static let divider      = Color(red: 226/255, green: 221/255, blue: 213/255) // #E2DDD5
    static let textPrimary  = Color(red: 26/255,  green: 24/255,  blue: 20/255)  // #1A1814
    static let textSecondary = Color(red: 122/255, green: 117/255, blue: 111/255) // #7A756F
    static let textFaint    = Color(red: 176/255, green: 169/255, blue: 159/255) // #B0A99F

    static let yes          = Color(red: 123/255, green: 184/255, blue: 154/255) // #7BB89A
    static let yesFill      = Color(red: 196/255, green: 224/255, blue: 212/255) // #C4E0D4
    static let no           = Color(red: 201/255, green: 123/255, blue: 123/255) // #C97B7B
    static let noFill       = Color(red: 245/255, green: 206/255, blue: 206/255) // #F5CECE
    static let accent       = Color(red: 232/255, green: 160/255, blue: 160/255) // #E8A0A0

    static let dark         = Color(red: 26/255,  green: 24/255,  blue: 20/255)  // #1A1814
}

// MARK: - Event Status

enum EventStatus: String, CaseIterable {
    case live = "LIVE"
    case betsClosed = "BETS CLOSED"
    case resolved = "RESOLVED"
    case cancelled = "CANCELLED"

    var dotColor: Color {
        switch self {
        case .live:        return ClipBetColors.accent
        case .betsClosed:  return ClipBetColors.textSecondary
        case .resolved:    return ClipBetColors.yes
        case .cancelled:   return ClipBetColors.textFaint
        }
    }

    var isPulsing: Bool {
        self == .live
    }
}

// MARK: - Bet Outcome

struct BetOutcome: Identifiable, Hashable {
    let id: UUID
    let name: String
    var totalAmount: Double
    var betCount: Int

    var formattedAmount: String {
        String(format: "$%.0f", totalAmount)
    }
}

// MARK: - Prediction Event

struct PredictionEvent: Identifiable {
    let id: UUID
    let name: String
    let location: String
    let organizer: String
    var status: EventStatus
    var outcomes: [BetOutcome]
    let minimumBet: Double
    let createdAt: Date
    var resolvedOutcomeId: UUID?

    var totalPool: Double {
        outcomes.reduce(0) { $0 + $1.totalAmount }
    }

    var totalBettors: Int {
        outcomes.reduce(0) { $0 + $1.betCount }
    }

    var platformFee: Double {
        totalPool * 0.05
    }

    var winnerPool: Double {
        totalPool - platformFee
    }

    func percentage(for outcome: BetOutcome) -> Double {
        guard totalPool > 0 else { return 0 }
        return (outcome.totalAmount / totalPool) * 100
    }

    func estimatedReturn(betAmount: Double, for outcome: BetOutcome) -> Double {
        let newOutcomeTotal = outcome.totalAmount + betAmount
        let newPoolTotal = totalPool + betAmount
        let winnerPoolAfterFee = newPoolTotal * 0.95
        return (betAmount / newOutcomeTotal) * winnerPoolAfterFee
    }

    var formattedPool: String {
        String(format: "$%.0f", totalPool)
    }

    var timeSinceCreated: String {
        let interval = Date().timeIntervalSince(createdAt)
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - User Bet

struct UserBet: Identifiable {
    let id: UUID
    let eventId: UUID
    let outcomeId: UUID
    let amount: Double
    let nickname: String
    let timestamp: Date
}

// MARK: - Mock Data

enum ClipBetMockData {

    static let outcomes1: [BetOutcome] = [
        BetOutcome(id: UUID(), name: "Raptors win", totalAmount: 1250, betCount: 23),
        BetOutcome(id: UUID(), name: "Celtics win", totalAmount: 890, betCount: 17),
    ]

    static let outcomes2: [BetOutcome] = [
        BetOutcome(id: UUID(), name: "Under 30 min", totalAmount: 340, betCount: 12),
        BetOutcome(id: UUID(), name: "30–60 min", totalAmount: 520, betCount: 18),
        BetOutcome(id: UUID(), name: "Over 60 min", totalAmount: 180, betCount: 7),
    ]

    static let outcomes3: [BetOutcome] = [
        BetOutcome(id: UUID(), name: "Yes, encore", totalAmount: 680, betCount: 31),
        BetOutcome(id: UUID(), name: "No encore", totalAmount: 220, betCount: 9),
    ]

    static let events: [PredictionEvent] = [
        PredictionEvent(
            id: UUID(),
            name: "Will the Raptors beat the Celtics tonight?",
            location: "Scotiabank Arena, Toronto",
            organizer: "ArenaHost",
            status: .live,
            outcomes: outcomes1,
            minimumBet: 5,
            createdAt: Calendar.current.date(byAdding: .minute, value: -47, to: Date()) ?? Date()
        ),
        PredictionEvent(
            id: UUID(),
            name: "How long will the opening act play?",
            location: "Rogers Centre, Toronto",
            organizer: "ConcertOps",
            status: .live,
            outcomes: outcomes2,
            minimumBet: 5,
            createdAt: Calendar.current.date(byAdding: .minute, value: -12, to: Date()) ?? Date()
        ),
        PredictionEvent(
            id: UUID(),
            name: "Will there be an encore?",
            location: "Massey Hall, Toronto",
            organizer: "LiveNation",
            status: .live,
            outcomes: outcomes3,
            minimumBet: 5,
            createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        ),
    ]

    static var primaryEvent: PredictionEvent { events[0] }
}
