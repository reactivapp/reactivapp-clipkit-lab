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

    // MARK: - Outcomes

    static let outcomes1: [BetOutcome] = [
        BetOutcome(id: UUID(), name: "Raptors win", totalAmount: 1250, betCount: 23),
        BetOutcome(id: UUID(), name: "Celtics win", totalAmount: 890, betCount: 17),
    ]

    static let outcomes2: [BetOutcome] = [
        BetOutcome(id: UUID(), name: "Yes, encore", totalAmount: 680, betCount: 31),
        BetOutcome(id: UUID(), name: "No encore", totalAmount: 220, betCount: 9),
    ]

    // MARK: - Events

    static let events: [PredictionEvent] = [
        // Live event
        PredictionEvent(
            id: UUID(),
            name: "Will the Raptors beat the Celtics tonight?",
            description: "Game 4 of the Eastern Conference. Raptors need this win to tie the series.",
            imageURL: nil,
            location: "Scotiabank Arena, Toronto",
            locationLat: 43.6435,
            locationLng: -79.3791,
            organizer: "ArenaHost",
            organizerId: organizer1.id,
            status: .live,
            outcomes: outcomes1,
            minimumBet: 5,
            bettingWindow: .manual,
            createdAt: Calendar.current.date(byAdding: .minute, value: -47, to: Date()) ?? Date(),
            eventTime: Calendar.current.date(byAdding: .minute, value: -30, to: Date())
        ),
        // Planned event
        PredictionEvent(
            id: UUID(),
            name: "Will there be an encore?",
            description: nil,
            imageURL: nil,
            location: "Massey Hall, Toronto",
            locationLat: 43.6543,
            locationLng: -79.3787,
            organizer: "ConcertOps",
            organizerId: organizer1.id,
            status: .planned,
            outcomes: outcomes2,
            minimumBet: 5,
            bettingWindow: .manual,
            createdAt: Date(),
            eventTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
        ),
        // Expired/resolved event
        PredictionEvent(
            id: UUID(),
            name: "Will the DJ play a second set?",
            description: "Drake Hotel late night DJ set prediction.",
            imageURL: nil,
            location: "Drake Hotel, Toronto",
            locationLat: 43.6426,
            locationLng: -79.4215,
            organizer: "DrakeHost",
            organizerId: organizer1.id,
            status: .resolved,
            outcomes: [
                BetOutcome(id: UUID(), name: "Yes", totalAmount: 420, betCount: 18),
                BetOutcome(id: UUID(), name: "No", totalAmount: 200, betCount: 12),
            ],
            minimumBet: 5,
            bettingWindow: .manual,
            createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
            resolvedAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date()),
            resolvedOutcomeId: nil
        ),
    ]

    static var primaryEvent: PredictionEvent { events[0] }
    static var plannedEvent: PredictionEvent { events[1] }
    static var expiredEvent: PredictionEvent { events[2] }

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
    ]
}
