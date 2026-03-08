Noimport SwiftUI
import MapKit
import CoreLocation

// MARK: - Brand colour
private extension Color {
    static let brand = Color(red: 0.95, green: 0.42, blue: 0.00)          // #F26B00 orange
    static let brandLight = Color(red: 0.95, green: 0.42, blue: 0.00).opacity(0.12)
}

// MARK: - NaloxoneNow

struct NaloxoneNow: ClipExperience {
    static let urlPattern      = "naloxonenow.app/:code"
    static let clipName        = "NaloxoneNow"
    static let clipDescription = "Overdose response guide, naloxone locator and support resources"
    static let teamName        = "CommunityHealth"
    static let touchpoint: JourneyTouchpoint  = .onSite
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    @State private var selectedTab: NNTab = .emergency
    @State private var selectedLocation: NaloxoneLocation? = nil

    enum NNTab { case emergency, locator, resources }

    var body: some View {
        VStack(spacing: 0) {
            // ── Tab content ──────────────────────────────────────────────
            ZStack {
                switch selectedTab {
                case .emergency: EmergencyTab()
                case .locator:   LocatorTab(selectedLocation: $selectedLocation)
                case .resources: ResourcesTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── Tab bar ───────────────────────────────────────────────────
            NNTabBar(selected: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Tab bar

private struct NNTabBar: View {
    @Binding var selected: NaloxoneNow.NNTab

    var body: some View {
        HStack(spacing: 0) {
            tabItem(icon: "exclamationmark.circle", label: "Emergency", tab: .emergency)
            tabItem(icon: "mappin.and.ellipse",     label: "Locator",   tab: .locator)
            tabItem(icon: "heart.text.square",      label: "Resources", tab: .resources)
        }
        .frame(height: 56)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .top)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func tabItem(icon: String, label: String, tab: NaloxoneNow.NNTab) -> some View {
        let active = selected == tab
        Button {
            selected = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: active ? .semibold : .regular))
                Text(label)
                    .font(.system(size: 10, weight: active ? .semibold : .regular))
            }
            .foregroundColor(active ? .brand : Color(.systemGray))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Emergency Tab

private struct EmergencyTab: View {
    var body: some View {
        VStack(spacing: 0) {
            // Orange header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("What to do if someone is OverDosing")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Text("Overdose response guide")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .background(Color.brand)

            ScrollView {
                VStack(spacing: 16) {
                    // Emergency contacts card
                    SectionCard(title: "Emergency Contacts", icon: "phone.fill", color: .brand) {
                        CallRow(
                            iconBg: Color(red: 0.6, green: 0.05, blue: 0.05),
                            icon: "phone.fill",
                            title: "Call 911",
                            subtitle: "Emergency Services",
                            phone: "911"
                        )
                    }

                    // Overdose steps card
                    SectionCard(title: "If Someone is Overdosing", icon: "exclamationmark.circle", color: .brand) {
                        VStack(spacing: 0) {
                            StepRow(n: 1, title: "Check for signs",
                                    detail: "Unconscious, slow/no breathing, blue lips or nails, pinpoint pupils")
                            Divider().padding(.leading, 52)
                            StepRow(n: 2, title: "Call 911 immediately",
                                    detail: "Give exact location, stay on the line")
                            Divider().padding(.leading, 52)
                            StepRow(n: 3, title: "Give naloxone",
                                    detail: "Administer nasal spray or injection — see instructions below")
                            Divider().padding(.leading, 52)
                            StepRow(n: 4, title: "Turn on side (recovery position)",
                                    detail: "Keep airway clear, monitor breathing")
                            Divider().padding(.leading, 52)
                            StepRow(n: 5, title: "Stay until help arrives",
                                    detail: "Give 2nd dose after 2–3 min if no response. Naloxone wears off in 30–90 min.")
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Nasal spray instructions
                    SectionCard(title: "Nasal Spray (NARCAN®)", icon: "cross.vial.fill", color: .brand) {
                        VStack(spacing: 0) {
                            StepRow(n: 1, title: "Lay person on their back",
                                    detail: "Support the neck so the head tilts back slightly")
                            Divider().padding(.leading, 52)
                            StepRow(n: 2, title: "Insert nozzle into one nostril",
                                    detail: "Place nozzle tip in one nostril until your fingers touch the bottom of their nose")
                            Divider().padding(.leading, 52)
                            StepRow(n: 3, title: "Press plunger firmly",
                                    detail: "Press firmly with thumb to release the full dose into the nostril")
                            Divider().padding(.leading, 52)
                            StepRow(n: 4, title: "Wait 2–3 minutes",
                                    detail: "If no response, give second dose in the other nostril")
                            Divider().padding(.leading, 52)
                            StepRow(n: 5, title: "Place in recovery position",
                                    detail: "Turn on side — naloxone may wear off before opioids. Stay with them.")
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Injection instructions
                    SectionCard(title: "Injection (Evzio® / Generic)", icon: "syringe.fill", color: Color(red: 0.70, green: 0.25, blue: 0.00)) {
                        VStack(spacing: 0) {
                            StepRow(n: 1, title: "Remove cap and prep site",
                                    detail: "Outer thigh or upper arm — can inject through clothing")
                            Divider().padding(.leading, 52)
                            StepRow(n: 2, title: "Hold auto-injector firmly",
                                    detail: "Place tip against injection site, hold firmly in place")
                            Divider().padding(.leading, 52)
                            StepRow(n: 3, title: "Press down and hold 5 seconds",
                                    detail: "You'll hear a click — keep pressing until injection is complete")
                            Divider().padding(.leading, 52)
                            StepRow(n: 4, title: "Remove and massage",
                                    detail: "Remove needle/device and rub the area for 10 seconds")
                            Divider().padding(.leading, 52)
                            StepRow(n: 5, title: "Repeat if needed",
                                    detail: "Give 2nd dose after 2–3 min with no response. Do not give more than 2 doses unless advised.")
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Important notes
                    SectionCard(title: "Important to Know", icon: "info.circle.fill", color: Color(red: 0.18, green: 0.55, blue: 0.34)) {
                        VStack(alignment: .leading, spacing: 8) {
                            NoteRow(icon: "clock.fill", text: "Naloxone works within 2–5 minutes and lasts 30–90 minutes — opioids may outlast it. Stay with the person.")
                            Divider().padding(.leading, 28)
                            NoteRow(icon: "exclamationmark.triangle.fill", text: "Naloxone is safe for everyone — it will not harm someone who has NOT taken opioids.")
                            Divider().padding(.leading, 28)
                            NoteRow(icon: "heart.fill", text: "Good Samaritan laws protect you — call 911. You will not get in trouble for helping.")
                            Divider().padding(.leading, 28)
                            NoteRow(icon: "pills.fill", text: "Free naloxone kits are available at pharmacies across Ontario — no prescription needed.")
                        }
                        .padding(.horizontal, 4)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Location Manager

private class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}

// MARK: - Locator Tab

private struct LocatorTab: View {
    @Binding var selectedLocation: NaloxoneLocation?
    @StateObject private var locationMgr = LocationManager()
    @State private var searchText: String = ""
    @State private var addressText: String = ""
    @State private var searchedCoord: CLLocationCoordinate2D? = nil
    @State private var isSearchingAddress = false
    @State private var displayCount = 30

    // Default map region — Ontario, Canada
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.7, longitude: -79.42),
        span: MKCoordinateSpan(latitudeDelta: 3.5, longitudeDelta: 3.5)
    )

    private var referenceCoord: CLLocationCoordinate2D? {
        searchedCoord ?? locationMgr.userLocation?.coordinate
    }

    private var filteredLocations: [NaloxoneLocation] {
        let base = OntarioNaloxoneKits.locations
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()

        // Build list with optional distance sort
        var result: [NaloxoneLocation]
        if let coord = referenceCoord {
            let ref = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            result = base
                .compactMap { loc -> (NaloxoneLocation, Double)? in
                    guard let lat = loc.latitude, let lon = loc.longitude else { return nil }
                    let d = ref.distance(from: CLLocation(latitude: lat, longitude: lon))
                    return (loc, d)
                }
                .sorted { $0.1 < $1.1 }
                .map { $0.0 }
        } else {
            result = base
        }

        if query.isEmpty { return result }
        return result.filter {
            $0.name.lowercased().contains(query) ||
            ($0.address?.lowercased().contains(query) ?? false) ||
            ($0.notes?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Orange header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Find Naloxone")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Text("\(OntarioNaloxoneKits.locations.count) Ontario naloxone kit sites")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .background(Color.brand)

            // Search / location bar
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search by name or area…", text: $searchText)
                        .font(.subheadline)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle")
                        .foregroundColor(.secondary)
                    TextField("Enter address to find closest…", text: $addressText)
                        .font(.subheadline)
                        .onSubmit { geocodeAddress() }
                    if isSearchingAddress {
                        ProgressView().scaleEffect(0.7)
                    } else if !addressText.isEmpty {
                        Button { addressText = ""; searchedCoord = nil } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                    Button {
                        locationMgr.requestLocation()
                        addressText = "Using current location…"
                        searchedCoord = nil
                    } label: {
                        Image(systemName: "location.fill")
                            .foregroundColor(.brand)
                    }
                    .accessibilityLabel("Use my current location")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGroupedBackground))

            // Map
            Map(coordinateRegion: $region, annotationItems: mapAnnotations) { loc in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: loc.latitude ?? 0,
                    longitude: loc.longitude ?? 0
                )) {
                    Circle()
                        .fill(selectedLocation?.id == loc.id ? Color.brand : Color.brand.opacity(0.6))
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .onTapGesture { selectedLocation = loc }
                }
            }
            .frame(height: 180)
            .onChange(of: referenceCoord?.latitude) { _, _ in
                if let coord = referenceCoord {
                    withAnimation {
                        region = MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                        )
                    }
                }
            }

            Divider()

            // Result count
            HStack {
                let shown = min(displayCount, filteredLocations.count)
                Text("Showing \(shown) of \(filteredLocations.count) locations")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if referenceCoord != nil {
                    Label("Sorted by distance", systemImage: "arrow.up.arrow.down")
                        .font(.caption2)
                        .foregroundColor(.brand)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))

            // Lazy location list
            ScrollView {
                LazyVStack(spacing: 10, pinnedViews: []) {
                    ForEach(filteredLocations.prefix(displayCount)) { loc in
                        LocationRow(
                            loc: loc,
                            isSelected: selectedLocation?.id == loc.id,
                            referenceCoord: referenceCoord
                        )
                        .onTapGesture {
                            selectedLocation = loc
                            if let lat = loc.latitude, let lon = loc.longitude {
                                withAnimation {
                                    region = MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                    )
                                }
                            }
                        }
                    }

                    if displayCount < filteredLocations.count {
                        Button {
                            displayCount += 30
                        } label: {
                            Text("Load more (\(filteredLocations.count - displayCount) remaining)")
                                .font(.subheadline)
                                .foregroundColor(.brand)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
        }
        .onChange(of: searchText) { _, _ in displayCount = 30 }
    }

    // Only show first 100 pins on map for performance
    private var mapAnnotations: [NaloxoneLocation] {
        filteredLocations.prefix(100).filter { $0.latitude != nil && $0.longitude != nil }
    }

    private func geocodeAddress() {
        let trimmed = addressText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSearchingAddress = true
        CLGeocoder().geocodeAddressString(trimmed) { placemarks, _ in
            isSearchingAddress = false
            if let coord = placemarks?.first?.location?.coordinate {
                searchedCoord = coord
                withAnimation {
                    region = MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                    )
                }
            }
        }
    }
}

// MARK: - Resources Tab

private struct ResourcesTab: View {
    var body: some View {
        VStack(spacing: 0) {
            // Orange header (matching other tabs)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Support Resources")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    Text("Help & information")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .background(Color.brand)

            ScrollView {
                VStack(spacing: 16) {
                    // Peer support
                    SectionCard(title: "Peer Support Groups",
                                icon: "person.2.fill",
                                color: .brand) {
                        VStack(spacing: 0) {
                            ResourceRow(title: "Narcotics Anonymous (NA)",
                                        subtitle: "Fellowship of people in recovery",
                                        phone: "18187739999",
                                        url: nil)
                            Divider().padding(.leading, 16)
                            ResourceRow(title: "SMART Recovery",
                                        subtitle: "Science-based addiction support",
                                        phone: nil,
                                        url: "https://smartrecovery.org")
                            Divider().padding(.leading, 16)
                            ResourceRow(title: "Nar-Anon Family Groups",
                                        subtitle: "Support for families & friends",
                                        phone: "18004776291",
                                        url: nil)
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Government
                    SectionCard(title: "Government Resources",
                                icon: "building.columns.fill",
                                color: .brand) {
                        VStack(spacing: 0) {
                            ResourceRow(title: "SAMHSA National Helpline",
                                        subtitle: "Treatment referral & info service\n1-800-662-4357  •  24/7 Free & Confidential",
                                        phone: "18006624357",
                                        url: "https://www.samhsa.gov")
                            Divider().padding(.leading, 16)
                            ResourceRow(title: "FindTreatment.gov",
                                        subtitle: "Locate treatment facilities nearby",
                                        phone: nil,
                                        url: "https://findtreatment.gov")
                            Divider().padding(.leading, 16)
                            ResourceRow(title: "Ontario Naloxone Program",
                                        subtitle: "Free naloxone kits across Ontario",
                                        phone: nil,
                                        url: "https://www.ontario.ca/page/where-get-free-naloxone-kit")
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Reusable sub-views

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            content
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct CallRow: View {
    let iconBg: Color
    let icon: String
    let title: String
    let subtitle: String
    let phone: String

    var body: some View {
        Button {
            if let url = URL(string: "tel://\(phone)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(iconBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline).bold()
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Call \(title)")
    }
}

private struct StepRow: View {
    let n: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.brand)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).bold()
                    .foregroundColor(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct LocationRow: View {
    let loc: NaloxoneLocation
    let isSelected: Bool
    var referenceCoord: CLLocationCoordinate2D? = nil

    private var distanceText: String? {
        guard let coord = referenceCoord,
              let lat = loc.latitude,
              let lon = loc.longitude else { return nil }
        let ref = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let meters = ref.distance(from: CLLocation(latitude: lat, longitude: lon))
        let km = meters / 1000
        return km < 1
            ? String(format: "%.0f m away", meters)
            : String(format: "%.1f km away", km)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isSelected ? Color.brand : Color.brand.opacity(0.6))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 3) {
                Text(loc.name)
                    .font(.subheadline).bold()
                    .foregroundColor(.primary)
                Text(loc.address ?? "Mobile service")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    // Open / Closed badge
                    Text(loc.isOpen ? "Open" : "Closed")
                        .font(.caption2).bold()
                        .foregroundColor(loc.isOpen ? Color(red: 0.10, green: 0.50, blue: 0.20) : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(loc.isOpen ? Color(red: 0.88, green: 0.97, blue: 0.88) : Color(.systemGray5))
                        .clipShape(Capsule())
                    if let dist = distanceText {
                        Text(dist)
                            .font(.caption2)
                            .foregroundColor(.brand)
                    }
                }
                if let notes = loc.notes {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            VStack(spacing: 6) {
                // Google Maps directions button
                if let lat = loc.latitude, let lon = loc.longitude,
                   let mapURL = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(lat),\(lon)") {
                    Link(destination: mapURL) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color(red: 0.20, green: 0.60, blue: 1.00))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Get directions to \(loc.name)")
                }
                // Phone button
                if let phone = loc.phone {
                    Button {
                        let digits = phone.filter { $0.isNumber }
                        if let url = URL(string: "tel://\(digits)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.brand)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Call \(loc.name)")
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct ResourceRow: View {
    let title: String
    let subtitle: String
    let phone: String?
    let url: String?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline).bold()
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            HStack(spacing: 8) {
                if let phone = phone {
                    Button {
                        if let u = URL(string: "tel://\(phone)") { UIApplication.shared.open(u) }
                    } label: {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.brand)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Call \(title)")
                }
                if let urlStr = url, let link = URL(string: urlStr) {
                    Link(destination: link) {
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.brand)
                    }
                    .accessibilityLabel("Open \(title)")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct NoteRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.brand)
                .frame(width: 18)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#if DEBUG
struct NaloxoneNow_Previews: PreviewProvider {
    static var previews: some View {
        NaloxoneNow(context: ClipContext(invocationURL: URL(string: "https://naloxonenow.app/preview")!))
    }
}
#endif
a
