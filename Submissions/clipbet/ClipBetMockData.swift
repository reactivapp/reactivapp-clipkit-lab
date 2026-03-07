//  ClipBetMockData.swift
//  ClipBet
//
//  Mock data for the hackathon demo.
//  In production this comes from the backend API.
//

import Foundation

enum ClipBetMockData {

    // MARK: - Organizers

    static let organizer1 = EventOrganizer(
        id: UUID(),
        appleUserId: "apple_001",
        stripeConnectId: "acct_mock_arena",
        tosAgreedAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
        verifiedAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
        eventsCreated: 12,
        disputesAgainst: 0,
        rating: 4.9
    )

    static let organizer2 = EventOrganizer(
        id: UUID(),
        appleUserId: "apple_002",
        stripeConnectId: "acct_mock_concert",
        tosAgreedAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
        verifiedAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
        eventsCreated: 5,
        disputesAgainst: 0,
        rating: 4.7
    )

    // MARK: - Outcomes

    static let outcomes1: [BetOutcome] = [
        BetOutcome(id: UUID(), name: "Raptors win", totalAmount: 1250, betCount: 23),
        BetOutcome(id: UUID(), name: "Celtics win", totalAmount: 890, betCount: 17),
    ]

    static let outcomes2: [BetOutcome] = [
        BetOutcome(id: UUID(), name: "Under 30 min", totalAmount: 340, betCount: 12),
        BetOutcome(id: UUID(), name: "30 to 60 min", totalAmount: 520, betCount: 18),
        BetOutcome(id: UUID(), name: "Over 60 min", totalAmount: 180, betCount: 7),
    ]

    static let outcomes3: [BetOutcome] = [
        BetOutcome(id: UUID(), name: "Yes, encore", totalAmount: 680, betCount: 31),
        BetOutcome(id: UUID(), name: "No encore", totalAmount: 220, betCount: 9),
    ]

    // MARK: - Events

    static let events: [PredictionEvent] = [
        PredictionEvent(
            id: UUID(),
            name: "Will the Raptors beat the Celtics tonight?",
            location: "Scotiabank Arena, Toronto",
            locationLat: 43.6435,
            locationLng: -79.3791,
            organizer: "ArenaHost",
            organizerId: organizer1.id,
            status: .live,
            outcomes: outcomes1,
            minimumBet: 5,
            bettingWindow: .stayOpen,
            createdAt: Calendar.current.date(byAdding: .minute, value: -47, to: Date()) ?? Date()
        ),
        PredictionEvent(
            id: UUID(),
            name: "How long will the opening act play?",
            location: "Rogers Centre, Toronto",
            locationLat: 43.6414,
            locationLng: -79.3894,
            organizer: "ConcertOps",
            organizerId: organizer2.id,
            status: .live,
            outcomes: outcomes2,
            minimumBet: 5,
            bettingWindow: .atStart,
            createdAt: Calendar.current.date(byAdding: .minute, value: -12, to: Date()) ?? Date()
        ),
        PredictionEvent(
            id: UUID(),
            name: "Will there be an encore?",
            location: "Massey Hall, Toronto",
            locationLat: 43.6543,
            locationLng: -79.3787,
            organizer: "LiveNation",
            organizerId: organizer1.id,
            status: .live,
            outcomes: outcomes3,
            minimumBet: 5,
            bettingWindow: .manual,
            createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        ),
    ]

    static var primaryEvent: PredictionEvent { events[0] }

    // MARK: - Sample Bets

    static let sampleBets: [UserBet] = [
        UserBet(
            id: UUID(),
            eventId: events[0].id,
            outcomeId: outcomes1[0].id,
            amount: 25,
            nickname: "RaptorsFan99",
            email: "fan@example.com",
            status: .confirmed,
            payoutAmount: nil,
            payoutStatus: .none,
            createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date(),
            stripePaymentIntentId: "pi_mock_001"
        ),
        UserBet(
            id: UUID(),
            eventId: events[0].id,
            outcomeId: outcomes1[1].id,
            amount: 10,
            nickname: "Anonymous",
            email: "anon@example.com",
            status: .confirmed,
            payoutAmount: nil,
            payoutStatus: .none,
            createdAt: Calendar.current.date(byAdding: .minute, value: -22, to: Date()) ?? Date(),
            stripePaymentIntentId: "pi_mock_002"
        ),
    ]
}
