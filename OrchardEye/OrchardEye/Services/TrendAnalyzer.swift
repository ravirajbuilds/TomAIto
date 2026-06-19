//
//  TrendAnalyzer.swift
//  OrchardEye
//
//  Stage 6 (trends). Turns a plant's scan history into a trajectory:
//  improving / stable / worsening, a spread index, and a "suspicious" flag —
//  the signal that distinguishes a spreading (infectious) problem from a
//  static (cosmetic/treatable) one.
//

import Foundation

enum TrendDirection: String, Codable {
    case improving, stable, worsening
}

struct TrendPoint: Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var healthScore: Int
    var lesionPct: Double
    var brix: Double
}

struct TrendSummary {
    var direction: TrendDirection
    var spreadIndex: Double     // 0–1, how fast lesions are growing
    var flagged: Bool           // worsening enough to warrant attention
    var points: [TrendPoint]
}

enum TrendAnalyzer {

    static func points(for plantTag: String, in records: [ScanRecord]) -> [TrendPoint] {
        records
            .filter { $0.plantTag == plantTag }
            .sorted { $0.date < $1.date }
            .map { TrendPoint(date: $0.date, healthScore: $0.health.score,
                              lesionPct: $0.health.lesionPct, brix: $0.spectral.brix) }
    }

    static func summary(for plantTag: String, in records: [ScanRecord]) -> TrendSummary {
        let pts = points(for: plantTag, in: records)
        guard pts.count >= 2, let first = pts.first, let last = pts.last else {
            return TrendSummary(direction: .stable, spreadIndex: 0, flagged: false, points: pts)
        }

        let healthDelta = last.healthScore - first.healthScore
        let lesionDelta = last.lesionPct - first.lesionPct

        let direction: TrendDirection
        if healthDelta <= -10 || lesionDelta >= 10 {
            direction = .worsening
        } else if healthDelta >= 10 || lesionDelta <= -10 {
            direction = .improving
        } else {
            direction = .stable
        }

        let days = max(1, last.date.timeIntervalSince(first.date) / 86_400)
        let spreadIndex = max(0, min(1, (lesionDelta / days) / 5.0))   // lesion %/day, normalized
        let flagged = direction == .worsening && last.lesionPct > 15

        return TrendSummary(direction: direction, spreadIndex: spreadIndex, flagged: flagged, points: pts)
    }
}
