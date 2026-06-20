//
//  DiseaseClassifier.swift
//  OrchardEye
//
//  Stage 4 (vision head). `DiseaseClassifier` is the seam a real INT8 Core ML /
//  TFLite model drops into. `MockDiseaseClassifier` derives a plausible result
//  from real on-device image stats so the whole app is demoable today.
//

import UIKit

struct DiseaseClassification {
    var disease: DiseaseInfo
    var confidence: Double      // 0–1
    var alternatives: [String]  // shown when confidence is low
    var health: CropHealth
}

protocol DiseaseClassifier {
    func classify(image: UIImage, crop: Crop) async -> DiseaseClassification
}

/// Confidence below this surfaces the top-2 alternatives instead of one answer.
let kDiseaseConfidenceThreshold = 0.70

final class MockDiseaseClassifier: DiseaseClassifier {

    func classify(image: UIImage, crop: Crop) async -> DiseaseClassification {
        // Simulate on-device inference latency (target < 3 s end-to-end).
        try? await Task.sleep(nanoseconds: 500_000_000)

        let s = ImageAnalysis.stats(for: image)
        let lesion = min(100, s.brownFraction * 200)
        let chlorosis = min(100, s.yellowFraction * 160)
        let symptom = max(lesion, chlorosis)                     // 0–100, strongest symptom
        let healthScore = max(0, min(100, Int(100 - lesion * 0.8 - chlorosis * 0.5)))

        let health = CropHealth(
            score: healthScore,
            chlorosisPct: chlorosis,
            lesionPct: lesion,
            sizeEstimate: min(1, s.greenFraction * 2),
            lifecycleStage: lifecycleStage(for: crop, size: s.greenFraction))

        let candidates = DiseaseInfo.candidates(for: crop)

        // Few symptoms → healthy.
        if symptom < 12 {
            let conf = min(0.97, 0.82 + s.greenFraction * 0.2)
            return DiseaseClassification(
                disease: .healthy, confidence: conf,
                alternatives: candidates.first.map { [$0.name] } ?? [],
                health: health)
        }

        // Otherwise pick a disease deterministically from the symptom signature.
        let idx = Int((s.brownFraction * 97 + s.yellowFraction * 57).rounded()) % max(1, candidates.count)
        let primary = candidates[idx]
        let conf = min(0.95, 0.65 + (symptom / 100) * 0.3)
        let alts = Array(candidates.filter { $0 != primary }.map { $0.name }.prefix(2))

        return DiseaseClassification(
            disease: primary, confidence: conf, alternatives: alts, health: health)
    }

    private func lifecycleStage(for crop: Crop, size: Double) -> String {
        switch crop {
        case .tomato: return size > 0.5 ? "Fruiting" : "Vegetative"
        case .apple:  return size > 0.5 ? "Fruit development" : "Early canopy"
        case .cherry: return size > 0.5 ? "Fruit development" : "Early canopy"
        }
    }
}
