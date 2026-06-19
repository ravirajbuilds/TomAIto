//
//  FusionEngine.swift
//  OrchardEye
//
//  Stage 5. Decision-level fusion: combine disease + crop-health + ripeness/Brix
//  + weather + this plant's trend into ONE verdict, a risk label, an urgency,
//  and plain-language + spoken recommendations.
//

import Foundation

enum FusionEngine {

    static func fuse(disease: DiseaseClassification,
                     spectral: SpectralReading,
                     weather: WeatherSnapshot?,
                     priorTrend: TrendSummary?,
                     variety: Variety) -> FusionResult {

        // --- Verdict ---
        let looksDiseased = !disease.disease.isHealthy &&
            (disease.confidence > 0.6 || disease.health.lesionPct > 25)

        let verdict: Verdict
        if looksDiseased {
            verdict = .diseased
        } else if spectral.ripeness == .ripe && disease.health.score >= 80 {
            verdict = .premium
        } else {
            verdict = .notReady
        }

        // --- Risk ---
        let risk: RiskLabel
        if disease.disease.isHealthy {
            risk = .none
        } else if disease.disease.infectious {
            risk = .infectious
        } else if disease.disease.treatable {
            risk = .treatable
        } else {
            risk = .cosmetic
        }

        // --- Urgency: infectiousness + weather pressure + worsening trend ---
        var score = 0
        if verdict == .diseased { score += 1 }
        if !disease.disease.isHealthy && disease.disease.infectious { score += 1 }
        if let w = weather, w.diseasePressure == "high" { score += 1 }
        if priorTrend?.direction == .worsening { score += 1 }
        let urgency: Urgency = score >= 3 ? .high : (score == 2 ? .medium : .low)

        // --- Recommendation ---
        let brixStr = String(format: "%.0f", spectral.brix)
        var rec: String
        switch verdict {
        case .premium:
            rec = "Healthy, about \(brixStr)° Brix — ripe. Pick now for premium grade."
        case .notReady:
            if spectral.ripeness == .unripe {
                rec = "No disease, but about \(brixStr)° Brix — not sweet enough yet. Re-check in a few days."
            } else {
                rec = "No disease, but quality is borderline (~\(brixStr)° Brix). Monitor before harvest."
            }
        case .diseased:
            rec = "\(disease.disease.name) suspected. \(disease.disease.action)"
        }

        // Weather-adaptive timing.
        if let w = weather {
            if w.precipForecastMM > 1 && verdict == .diseased {
                rec += " Rain is expected — if you spray, do it before it arrives."
            } else if w.diseasePressure == "high" && !disease.disease.isHealthy && disease.disease.infectious {
                rec += " Warm, humid conditions favor spread — re-check this block within 3 days."
            }
        }

        // Trend-aware nudge.
        if priorTrend?.direction == .worsening {
            rec += " This plant has been getting worse across scans — treat it as spreading."
        }

        // Low-confidence honesty.
        if !disease.disease.isHealthy && disease.confidence < kDiseaseConfidenceThreshold {
            rec += " Confidence is low — consider another photo from a second angle."
        }

        let spoken = "\(verdict.title). \(rec)"
        return FusionResult(verdict: verdict, recommendation: rec, risk: risk, urgency: urgency, spoken: spoken)
    }
}
