//  ClipBetNetworking.swift
//  ClipBet
//
//  API client for ClipBet backend.
//  All calls go through URLSession to the Express + Supabase + Stripe backend.
//  Set useMockData = true for simulator demo without backend.
//

import Foundation

// MARK: - API Configuration

enum ClipBetAPIConfig {
    /// Toggle to use mock data instead of real API calls
    static var useMockData = true

    /// Backend URL — set to your Railway/local deployment
    static var baseURL = "http://localhost:3001"
}

// MARK: - API Response Types

struct EventResponse: Decodable {
    let event: APIEvent
    let qr_url: String?
}

struct SingleEventResponse: Decodable {
    let event: APIEvent
}

struct PlaceBetResponse: Decodable {
    let bet_id: String
    let client_secret: String
    let payment_intent_id: String
}

struct SignInResponse: Decodable {
    let organizer: APIOrganizer
    let is_new: Bool
    let needs_tos: Bool
    let needs_stripe: Bool
}

struct ResolveResponse: Decodable {
    let status: String
    let total_pool: Double
    let platform_fee: Double
    let winner_pool: Double
    let winners: Int
    let losers: Int
}

struct CancelResponse: Decodable {
    let status: String
    let refunded_bets: Int
}

// MARK: - API Models (snake_case from backend)

struct APIEvent: Decodable {
    let id: String
    let name: String
    let description: String?
    let image_url: String?
    let status: String
    let minimum_bet: Double?
    let betting_window: String?
    let organizer_id: String
    let location_lat: Double?
    let location_lng: Double?
    let location_name: String?
    let event_time: String?
    let event_end_time: String?
    let total_pool: Double?
    let platform_fee: Double?
    let winner_pool: Double?
    let winning_option_id: String?
    let created_at: String
    let started_at: String?
    let closed_at: String?
    let resolved_at: String?
    let options: [APIOption]?
    let organizers: APIOrganizer?
}

struct APIOption: Decodable {
    let id: String
    let event_id: String
    let name: String
    let total_bets: Int?
    let total_amount: Double?
    let percentage: Double?
}

struct APIOrganizer: Decodable {
    let id: String
    let rating: Double?
    let events_created: Int?
    let apple_user_id: String?
    let stripe_connect_id: String?
    let tos_agreed_at: String?
    let verified_at: String?
}

// MARK: - API Client

final class ClipBetAPI {

    static let shared = ClipBetAPI()
    private init() {}

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    // MARK: - Fetch Event

    func fetchEvent(id: String, completion: @escaping (Result<PredictionEvent, Error>) -> Void) {
        if ClipBetAPIConfig.useMockData {
            completion(.success(ClipBetMockData.primaryEvent))
            return
        }

        let url = URL(string: "\(ClipBetAPIConfig.baseURL)/events/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(.failure(APIError.noData)) }
                return
            }
            do {
                let response = try self.decoder.decode(SingleEventResponse.self, from: data)
                let event = self.mapEvent(response.event)
                DispatchQueue.main.async { completion(.success(event)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - Create Event

    func createEvent(
        name: String,
        description: String?,
        imageURL: String?,
        options: [String],
        minimumBet: Double,
        organizerId: String,
        locationName: String?,
        locationLat: Double?,
        locationLng: Double?,
        eventTime: Date?,
        completion: @escaping (Result<(PredictionEvent, String), Error>) -> Void
    ) {
        if ClipBetAPIConfig.useMockData {
            let mockId = UUID()
            var mockEvent = ClipBetMockData.primaryEvent
            // Override with user input for mock
            let event = PredictionEvent(
                id: mockId,
                name: name,
                description: description,
                imageURL: imageURL,
                location: locationName ?? "Unknown",
                locationLat: locationLat ?? 0,
                locationLng: locationLng ?? 0,
                organizer: "You",
                organizerId: UUID(),
                status: .live,
                outcomes: options.map { BetOutcome(id: UUID(), name: $0, totalAmount: 0, betCount: 0) },
                minimumBet: minimumBet,
                bettingWindow: .manual,
                createdAt: Date(),
                eventTime: eventTime
            )
            let qrURL = "clipbet.io/event/\(mockId.uuidString.prefix(8).lowercased())"
            completion(.success((event, qrURL)))
            return
        }

        let url = URL(string: "\(ClipBetAPIConfig.baseURL)/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "name": name,
            "options": options,
            "minimum_bet": minimumBet,
            "organizer_id": organizerId,
        ]
        if let description { body["description"] = description }
        if let imageURL { body["image_url"] = imageURL }
        if let locationName { body["location_name"] = locationName }
        if let locationLat { body["location_lat"] = locationLat }
        if let locationLng { body["location_lng"] = locationLng }
        if let eventTime { body["event_time"] = ISO8601DateFormatter().string(from: eventTime) }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(.failure(APIError.noData)) }
                return
            }
            do {
                let response = try self.decoder.decode(EventResponse.self, from: data)
                let event = self.mapEvent(response.event)
                let qrURL = response.qr_url ?? "clipbet.io/event/\(response.event.id)"
                DispatchQueue.main.async { completion(.success((event, qrURL))) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - Place Bet

    func placeBet(
        eventId: String,
        optionId: String,
        amount: Double,
        email: String,
        nickname: String,
        completion: @escaping (Result<PlaceBetResponse, Error>) -> Void
    ) {
        if ClipBetAPIConfig.useMockData {
            let mock = PlaceBetResponse(
                bet_id: UUID().uuidString,
                client_secret: "pi_mock_\(UUID().uuidString.prefix(8))_secret",
                payment_intent_id: "pi_mock_\(UUID().uuidString.prefix(8))"
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(.success(mock))
            }
            return
        }

        let url = URL(string: "\(ClipBetAPIConfig.baseURL)/events/\(eventId)/bets")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "option_id": optionId,
            "amount": amount,
            "email": email,
            "nickname": nickname,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(.failure(APIError.noData)) }
                return
            }
            do {
                let response = try self.decoder.decode(PlaceBetResponse.self, from: data)
                DispatchQueue.main.async { completion(.success(response)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - Close Bets

    func closeBets(eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if ClipBetAPIConfig.useMockData {
            completion(.success(()))
            return
        }
        patchStatus(eventId: eventId, status: "bets_closed", completion: completion)
    }

    // MARK: - Resolve Event

    func resolveEvent(
        eventId: String,
        winningOptionId: String,
        organizerId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        if ClipBetAPIConfig.useMockData {
            completion(.success(()))
            return
        }

        let url = URL(string: "\(ClipBetAPIConfig.baseURL)/organizers/events/\(eventId)/resolve")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "winning_option_id": winningOptionId,
            "organizer_id": organizerId,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }

    // MARK: - Cancel Event

    func cancelEvent(
        eventId: String,
        organizerId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        if ClipBetAPIConfig.useMockData {
            completion(.success(()))
            return
        }

        let url = URL(string: "\(ClipBetAPIConfig.baseURL)/organizers/events/\(eventId)/cancel")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["organizer_id": organizerId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }

    // MARK: - Sign In Organizer

    func signinOrganizer(
        appleUserId: String,
        completion: @escaping (Result<SignInResponse, Error>) -> Void
    ) {
        if ClipBetAPIConfig.useMockData {
            let mock = SignInResponse(
                organizer: APIOrganizer(
                    id: UUID().uuidString,
                    rating: 5.0,
                    events_created: 0,
                    apple_user_id: appleUserId,
                    stripe_connect_id: nil,
                    tos_agreed_at: nil,
                    verified_at: nil
                ),
                is_new: true,
                needs_tos: true,
                needs_stripe: true
            )
            completion(.success(mock))
            return
        }

        let url = URL(string: "\(ClipBetAPIConfig.baseURL)/organizers/signin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: ["apple_user_id": appleUserId]
        )

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(.failure(APIError.noData)) }
                return
            }
            do {
                let response = try self.decoder.decode(SignInResponse.self, from: data)
                DispatchQueue.main.async { completion(.success(response)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - Helpers

    private func patchStatus(eventId: String, status: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "\(ClipBetAPIConfig.baseURL)/events/\(eventId)/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["status": status])

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }

    private func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        return isoFormatter.date(from: string)
    }

    func mapEvent(_ api: APIEvent) -> PredictionEvent {
        let outcomes = (api.options ?? []).map { opt in
            BetOutcome(
                id: UUID(uuidString: opt.id) ?? UUID(),
                name: opt.name,
                totalAmount: opt.total_amount ?? 0,
                betCount: opt.total_bets ?? 0
            )
        }

        let status: EventStatus = {
            switch api.status {
            case "planned": return .planned
            case "live": return .live
            case "bets_closed": return .betsClosed
            case "resolved": return .resolved
            case "cancelled": return .cancelled
            default: return .live
            }
        }()

        return PredictionEvent(
            id: UUID(uuidString: api.id) ?? UUID(),
            name: api.name,
            description: api.description,
            imageURL: api.image_url,
            location: api.location_name ?? "Unknown Location",
            locationLat: api.location_lat ?? 0,
            locationLng: api.location_lng ?? 0,
            organizer: api.organizers?.apple_user_id ?? "Organizer",
            organizerId: UUID(uuidString: api.organizer_id) ?? UUID(),
            status: status,
            outcomes: outcomes,
            minimumBet: api.minimum_bet ?? 5,
            bettingWindow: .manual,
            createdAt: parseDate(api.created_at) ?? Date(),
            eventTime: parseDate(api.event_time),
            eventEndTime: parseDate(api.event_end_time),
            startedAt: parseDate(api.started_at),
            closedAt: parseDate(api.closed_at),
            resolvedAt: parseDate(api.resolved_at),
            resolvedOutcomeId: api.winning_option_id.flatMap { UUID(uuidString: $0) }
        )
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case noData
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .noData: return "No data received"
        case .invalidResponse: return "Invalid response"
        case .serverError(let msg): return msg
        }
    }
}
