//
//  AppModel.swift
//  OrchardEye
//
//  App-wide state + service wiring (injected via @EnvironmentObject), plus the
//  local scan store (JSON persistence + CSV export, F4).
//

import Foundation
import SwiftUI

// MARK: - JSON helpers (ISO-8601 dates)

extension JSONEncoder {
    static var orchard: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}
extension JSONDecoder {
    static var orchard: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

// MARK: - Scan store

@MainActor
final class ScanStore: ObservableObject {
    @Published private(set) var records: [ScanRecord] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("scans.json")
    }()

    init() { load() }

    func add(_ record: ScanRecord) {
        records.insert(record, at: 0)
        save()
    }

    func update(_ record: ScanRecord) {
        if let i = records.firstIndex(where: { $0.id == record.id }) {
            records[i] = record
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    var plantTags: [String] {
        Array(Set(records.map { $0.plantTag })).sorted()
    }

    func records(forPlant tag: String) -> [ScanRecord] {
        records.filter { $0.plantTag == tag }.sorted { $0.date < $1.date }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder.orchard.decode([ScanRecord].self, from: data) else { return }
        records = decoded.sorted { $0.date > $1.date }
    }

    private func save() {
        if let data = try? JSONEncoder.orchard.encode(records) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: CSV export (F4)

    func exportCSV() -> URL? {
        let header = ["date", "plant_tag", "variety", "crop", "disease", "confidence",
                      "is_healthy", "health_score", "chlorosis_pct", "lesion_pct",
                      "lifecycle_stage", "ripeness", "brix", "verdict", "risk", "urgency",
                      "recommendation", "weather_temp_c", "weather_humidity_pct", "user_confirmed"]
        let df = ISO8601DateFormatter()

        var lines = [header.joined(separator: ",")]
        for r in records.sorted(by: { $0.date < $1.date }) {
            let row: [String] = [
                df.string(from: r.date),
                r.plantTag,
                r.variety.name,
                r.variety.crop.displayName,
                r.disease.name,
                String(format: "%.2f", r.diseaseConfidence),
                r.disease.isHealthy ? "yes" : "no",
                String(r.health.score),
                String(format: "%.1f", r.health.chlorosisPct),
                String(format: "%.1f", r.health.lesionPct),
                r.health.lifecycleStage,
                r.spectral.ripeness.rawValue,
                String(format: "%.1f", r.spectral.brix),
                r.verdict.rawValue,
                r.risk.rawValue,
                r.urgency.rawValue,
                r.recommendation,
                r.weather.map { String(format: "%.1f", $0.tempC) } ?? "",
                r.weather.map { String(format: "%.0f", $0.humidityPct) } ?? "",
                r.userConfirmed.map { $0 ? "confirmed" : "corrected" } ?? ""
            ]
            lines.append(row.map(Self.csvEscape).joined(separator: ","))
        }

        let csv = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("OrchardEye-scans.csv")
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private static func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }
}

// MARK: - App model

@MainActor
final class AppModel: ObservableObject {
    @Published var hasOnboarded: Bool
    @Published var isSensorPaired: Bool = false
    @Published var isCalibrated: Bool = false
    @Published var selectedVariety: Variety
    @Published var currentWeather: WeatherSnapshot?

    let store = ScanStore()
    let voice = VoiceGuide()
    let classifier: DiseaseClassifier = MockDiseaseClassifier()
    let sensor: SpectralSensor = SimulatedSpectralSensor()
    let weatherProvider = WeatherProvider()

    private let onboardKey = "hasOnboarded"
    private let varietyKey = "selectedVariety"

    init() {
        let d = UserDefaults.standard
        hasOnboarded = d.bool(forKey: onboardKey)
        if let data = d.data(forKey: varietyKey),
           let v = try? JSONDecoder().decode(Variety.self, from: data) {
            selectedVariety = v
        } else {
            selectedVariety = .default
        }
        isSensorPaired = hasOnboarded
        isCalibrated = hasOnboarded
    }

    func completeOnboarding(variety: Variety) {
        selectedVariety = variety
        hasOnboarded = true
        isSensorPaired = true
        isCalibrated = true
        persist()
    }

    func setVariety(_ v: Variety) {
        selectedVariety = v
        persist()
    }

    func resetOnboarding() {
        hasOnboarded = false
        isSensorPaired = false
        isCalibrated = false
        persist()
    }

    func refreshWeather() async {
        currentWeather = await weatherProvider.current()
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(hasOnboarded, forKey: onboardKey)
        if let data = try? JSONEncoder().encode(selectedVariety) {
            d.set(data, forKey: varietyKey)
        }
    }
}
