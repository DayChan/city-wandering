import Foundation
import CoreLocation

enum LocationSource: String {
    case gps, ip, manual
}

@MainActor
class LocationStore: NSObject, ObservableObject {
    @Published var city: CityDef?
    @Published var source: LocationSource?
    @Published var isDetecting = false

    private let locationManager = CLLocationManager()
    private var gpsContinuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        loadPersisted()
    }

    // MARK: - Public

    func detectFromIP() async {
        guard city == nil else { return }  // 已有城市（手动或会话内已检测）
        isDetecting = true
        defer { isDetecting = false }

        guard let found = await fetchIPCity() else { return }
        city = found
        source = .ip
    }

    func detectFromGPS() async {
        isDetecting = true
        defer { isDetecting = false }

        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            // 等待授权回调（简单 sleep，生产可用 AsyncStream）
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else { return }

        let location = await withCheckedContinuation { continuation in
            gpsContinuation = continuation
            locationManager.requestLocation()
        }

        guard let location else { return }
        let coord = location.coordinate
        if let found = findNearestCity(to: coord) {
            city = found
            source = .gps
        } else {
            // GPS 定位成功但不在支持城市范围内，保留坐标信息
            source = .gps
        }
    }

    func selectManual(_ cityDef: CityDef) {
        city = cityDef
        source = .manual
        persist()
    }

    func reset() {
        city = nil
        source = nil
        UserDefaults.standard.removeObject(forKey: "manual_city_slug")
    }

    // MARK: - Persistence (only manual)

    private func persist() {
        guard source == .manual, let city else { return }
        UserDefaults.standard.set(city.slug, forKey: "manual_city_slug")
    }

    private func loadPersisted() {
        guard let slug = UserDefaults.standard.string(forKey: "manual_city_slug"),
              let found = allCities.first(where: { $0.slug == slug }) else { return }
        city = found
        source = .manual
    }

    // MARK: - IP Detection

    private func fetchIPCity() async -> CityDef? {
        guard let url = URL(string: "https://ipinfo.io/json") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONDecoder().decode(IPInfoResponse.self, from: data)

            if let cityName = json.city, let found = matchCityFromIP(cityName) { return found }
            if let region = json.region, let found = matchCityFromIP(region) { return found }
            if let loc = json.loc {
                let parts = loc.split(separator: ",").compactMap { Double($0) }
                if parts.count == 2 {
                    return findNearestCity(to: .init(latitude: parts[0], longitude: parts[1]))
                }
            }
        } catch {}
        return nil
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationStore: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            gpsContinuation?.resume(returning: locations.first)
            gpsContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            gpsContinuation?.resume(returning: nil)
            gpsContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {}
}

private struct IPInfoResponse: Decodable {
    let city: String?
    let region: String?
    let loc: String?
}
