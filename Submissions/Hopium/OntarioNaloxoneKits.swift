// OntarioNaloxoneKits.swift
// Ontario Naloxone Kits — runtime loader
// Replaces the static array with a JSON-based loader to avoid compiler timeouts.
//
// Data source: Ontario Ministry of Health naloxone locations (ArcGIS)
// JSON file: arcgis_locations.json (bundled as a resource)

import Foundation

// MARK: - NaloxoneLocation model

struct NaloxoneLocation: Identifiable {
    let id: UUID
    let name: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let isOpen: Bool
    let distanceMeters: Double?
    let phone: String?
    let notes: String?

    var distanceText: String {
        guard let meters = distanceMeters else { return "—" }
        let km = meters / 1000
        if km < 1 {
            return String(format: "%.1f mi", meters / 1609.34)
        } else {
            return String(format: "%.1f km", km)
        }
    }

    var openInfo: String {
        isOpen ? "Open now" : "Closed"
    }
}

// MARK: - JSON decodable shape (matches arcgis_locations.json)

private struct ArcGISRoot: Decodable {
    let records: [ArcGISRecord]
}

private struct ArcGISRecord: Decodable {
    let latitude: Double?
    let longitude: Double?
    let en: ArcGISLocalised
}

private struct ArcGISLocalised: Decodable {
    let location_name: String
    let address: String?
    let city: String?
    let postal_code: String?
    let public_health_region: String?
    let telephone: String?
    let location_type: String?
    let additional_information: String?
}

// MARK: - OntarioNaloxoneKits

enum OntarioNaloxoneKits {

    /// All naloxone kit locations loaded lazily from the bundled JSON file.
    static let locations: [NaloxoneLocation] = {
        guard let url = Bundle.main.url(forResource: "arcgis_locations", withExtension: "json") else {
            assertionFailure("arcgis_locations.json not found in bundle — add it to the Xcode target.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let root = try JSONDecoder().decode(ArcGISRoot.self, from: data)
            return root.records.map { record in
                let en = record.en
                let fullAddress: String? = [en.address, en.city, en.postal_code]
                    .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                    .nonEmpty
                let notes: String? = [en.location_type, en.public_health_region]
                    .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .joined(separator: " · ")
                    .nonEmpty
                return NaloxoneLocation(
                    id: UUID(),
                    name: en.location_name,
                    address: fullAddress,
                    latitude: record.latitude,
                    longitude: record.longitude,
                    isOpen: true,
                    distanceMeters: nil,
                    phone: en.telephone?.trimmingCharacters(in: .whitespaces).nonEmpty,
                    notes: notes
                )
            }
        } catch {
            assertionFailure("Failed to parse arcgis_locations.json: \(error)")
            return []
        }
    }()
}

// MARK: - String helper

extension String {
    /// Returns nil if the string is empty after trimming whitespace.
    var nonEmpty: String? { isEmpty ? nil : self }
}
