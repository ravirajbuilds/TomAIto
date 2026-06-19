//
//  WeatherProvider.swift
//  OrchardEye
//
//  Pulls weather from the free, key-less Open-Meteo API and caches the last
//  value so voice guidance still works offline. Always falls back to a typical
//  central-WA snapshot — a scan must never depend on the network.
//

import Foundation

final class WeatherProvider {

    // Default to Wenatchee, WA (WA-08 tree-fruit core) when no GPS is available.
    private let defaultLat = 47.42
    private let defaultLon = -120.31
    private let cacheKey = "cachedWeather"

    func current(lat: Double? = nil, lon: Double? = nil) async -> WeatherSnapshot {
        let latitude = lat ?? defaultLat
        let longitude = lon ?? defaultLon

        if let live = try? await fetch(lat: latitude, lon: longitude) {
            cache(live)
            return live
        }
        return cached() ?? Self.fallback()
    }

    // MARK: - Network

    private func fetch(lat: Double, lon: Double) async throws -> WeatherSnapshot {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude", value: String(lat)),
            .init(name: "longitude", value: String(lon)),
            .init(name: "current", value: "temperature_2m,relative_humidity_2m,precipitation"),
            .init(name: "hourly", value: "precipitation"),
            .init(name: "forecast_days", value: "1")
        ]
        guard let url = comps.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(OMResponse.self, from: data)

        let forecast = (decoded.hourly?.precipitation.prefix(12).reduce(0, +)) ?? 0
        let temp = decoded.current.temperature_2m
        let humidity = decoded.current.relative_humidity_2m

        return WeatherSnapshot(
            tempC: temp,
            humidityPct: humidity,
            precipRecentMM: decoded.current.precipitation,
            precipForecastMM: forecast,
            summary: Self.summarize(temp: temp, humidity: humidity, forecast: forecast),
            capturedAt: Date())
    }

    private struct OMResponse: Codable {
        struct Current: Codable {
            let temperature_2m: Double
            let relative_humidity_2m: Double
            let precipitation: Double
        }
        struct Hourly: Codable { let precipitation: [Double] }
        let current: Current
        let hourly: Hourly?
    }

    // MARK: - Cache & fallback

    private func cache(_ s: WeatherSnapshot) {
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func cached() -> WeatherSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let s = try? JSONDecoder().decode(WeatherSnapshot.self, from: data) else { return nil }
        return s
    }

    static func fallback() -> WeatherSnapshot {
        WeatherSnapshot(tempC: 24, humidityPct: 45, precipRecentMM: 0, precipForecastMM: 0,
                        summary: "Warm and dry (typical seasonal estimate — offline)", capturedAt: Date())
    }

    static func summarize(temp: Double, humidity: Double, forecast: Double) -> String {
        let t = String(format: "%.0f°C", temp)
        let h = String(format: "%.0f%% RH", humidity)
        if forecast > 1 { return "\(t), \(h), rain expected" }
        if humidity >= 70 { return "\(t), \(h), humid" }
        return "\(t), \(h), dry"
    }
}
