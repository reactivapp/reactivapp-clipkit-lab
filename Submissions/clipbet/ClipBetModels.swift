//  ClipBetModels.swift
//  ClipBet
//
//  Data models for events, bets, organizers, and outcomes.
//  Based on the full backend schema (Part 8).
//

import Foundation
import SwiftUI

// MARK: - Design System Colors

enum ClipBetColors {
    static let bg           = Color(red: 250/255, green: 248/255, blue: 245/255) // FAF8F5
    static let surface      = Color(red: 240/255, green: 236/255, blue: 228/255) // F0ECE4
    static let divider      = Color(red: 226/255, green: 221/255, blue: 213/255) // E2DDD5
    static let textPrimary  = Color(red: 26/255,  green: 24/255,  blue: 20/255)  // 1A1814
    static let textSecondary = Color(red: 122/255, green: 117/255, blue: 111/255) // 7A756F
    static let textFaint    = Color(red: 176/255, green: 169/255, blue: 159/255) // B0A99F

    static let yes          = Color(red: 123/255, green: 184/255, blue: 154/255) // 7BB89A
    static let yesFill      = Color(red: 196/255, green: 224/255, blue: 212/255) // C4E0D4
    static let no           = Color(red: 201/255, green: 123/255, blue: 123/255) // C97B7B
    static let noFill       = Color(red: 245/255, green: 206/255, blue: 206/255) // F5CECE
    static let accent       = Color(red: 232/255, green: 160/255, blue: 160/255) // E8A0A0

    static let dark         = Color(red: 26/255,  green: 24/255,  blue: 20/255)  // 1A1814
}

// MARK: - Event Status

enum EventStatus: String, CaseIterable {
    case planned = "PLANNED"
    case live = "LIVE"
    case betsClosed = "BETS CLOSED"
    case resolved = "RESOLVED"
    case cancelled = "CANCELLED"

    var dotColor: Color {
        switch self {
        case .planned:     return ClipBetColors.textSecondary
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

// MARK: - Betting Window

enum BettingWindow: String {
    case manual = "Close Manually"
    case atStart = "Close at Start"
    case stayOpen = "Stay Open During Event"
}

// MARK: - Bet Outcome (Option)

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
    let description: String?
    let imageURL: String?
    let location: String
    let locationLat: Double
    let locationLng: Double
    let organizer: String
    let organizerId: UUID
    var status: EventStatus
    var outcomes: [BetOutcome]
    let minimumBet: Double
    let bettingWindow: BettingWindow
    let createdAt: Date
    var eventTime: Date?
    var eventEndTime: Date?
    var startedAt: Date?
    var closedAt: Date?
    var resolvedAt: Date?
    var resolvedOutcomeId: UUID?

    // MARK: - Event State

    var isExpired: Bool {
        status == .resolved || status == .cancelled
    }

    var isAcceptingBets: Bool {
        status == .live
    }

    var isPlanned: Bool {
        status == .planned
    }

    // MARK: - Pool Calculations

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

    var formattedEventTime: String? {
        guard let eventTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: eventTime)
    }

    var timeSinceCreated: String {
        // For planned events, show time until start
        if let eventTime, status == .planned {
            let interval = eventTime.timeIntervalSince(Date())
            if interval > 0 {
                let minutes = Int(interval) / 60
                let hours = minutes / 60
                if hours > 0 {
                    return "starts in \(hours)h \(minutes % 60)m"
                }
                return "starts in \(minutes)m"
            }
        }
        let interval = Date().timeIntervalSince(createdAt)
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Bet Status

enum BetStatus: String {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case won = "Won"
    case lost = "Lost"
    case refunded = "Refunded"
}

// MARK: - Payout Status

enum PayoutStatus: String {
    case none = "None"
    case processing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
}

// MARK: - User Bet

struct UserBet: Identifiable {
    let id: UUID
    let eventId: UUID
    let outcomeId: UUID
    let amount: Double
    let nickname: String
    let email: String
    var status: BetStatus
    var payoutAmount: Double?
    var payoutStatus: PayoutStatus
    let createdAt: Date
    var stripePaymentIntentId: String?
}

// MARK: - Organizer

struct EventOrganizer: Identifiable {
    let id: UUID
    let appleUserId: String
    var stripeConnectId: String?
    let tosAgreedAt: Date?
    let verifiedAt: Date?
    var eventsCreated: Int
    var disputesAgainst: Int
    var rating: Double

    var isVerified: Bool {
        verifiedAt != nil && stripeConnectId != nil
    }

    var isFirstTime: Bool {
        tosAgreedAt == nil
    }
}

// MARK: - Dispute

enum DisputeStatus: String {
    case open = "Open"
    case resolved = "Resolved"
    case rejected = "Rejected"
}

struct BetDispute: Identifiable {
    let id: UUID
    let eventId: UUID
    let bettorId: UUID
    let reason: String
    var status: DisputeStatus
    let createdAt: Date
    var resolvedAt: Date?
    var resolution: String?
}
