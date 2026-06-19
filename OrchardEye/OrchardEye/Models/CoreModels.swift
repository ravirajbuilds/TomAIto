//
//  CoreModels.swift
//  OrchardEye
//
//  The core data types shared across the scan pipeline:
//  capture → quality gate → disease + crop-health → spectral → fusion → verdict.
//

import Foundation
import SwiftUI

// MARK: - Crop & Variety

enum Crop: String, Codable, CaseIterable, Identifiable {
    case apple, cherry, tomato

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple:  return "Apple"
        case .cherry: return "Sweet Cherry"
        case .tomato: return "Tomato"
        }
    }

    var emoji: String {
        switch self {
        case .apple:  return "🍎"
        case .cherry: return "🍒"
        case .tomato: return "🍅"
        }
    }
}

struct Variety: Codable, Hashable, Identifiable {
    var name: String
    var crop: Crop

    var id: String { "\(crop.rawValue)-\(name)" }
    var displayName: String { "\(name) \(crop.displayName.lowercased())" }

    static let apples = ["Cosmic Crisp", "Honeycrisp", "Gala", "Fuji", "Red Delicious", "Granny Smith"]
        .map { Variety(name: $0, crop: .apple) }
    static let cherries = ["Bing", "Rainier", "Sweetheart", "Skeena"]
        .map { Variety(name: $0, crop: .cherry) }
    static let tomatoes = ["Roma", "Beefsteak", "Heirloom", "Cherry"]
        .map { Variety(name: $0, crop: .tomato) }

    static let all: [Variety] = apples + cherries + tomatoes
    static let `default` = apples[0]
}

// MARK: - Disease

/// One disease (or the "healthy" result) with plain-language guidance.
struct DiseaseInfo: Codable, Hashable, Identifiable {
    var name: String
    var isHealthy: Bool
    var infectious: Bool
    var treatable: Bool
    var summary: String   // what it is
    var action: String    // what to do next

    var id: String { name }
}

extension DiseaseInfo {
    static let healthy = DiseaseInfo(
        name: "Healthy — no disease detected", isHealthy: true, infectious: false, treatable: true,
        summary: "No visible disease symptoms were found on this sample.",
        action: "Keep monitoring on your normal schedule.")

    // Apple
    static let appleScab = DiseaseInfo(
        name: "Apple scab", isHealthy: false, infectious: true, treatable: true,
        summary: "A fungal disease (Venturia inaequalis) causing olive-green to brown velvety lesions on leaves and fruit.",
        action: "Remove fallen leaves and apply a protectant fungicide before the next wet period.")
    static let appleBlackRot = DiseaseInfo(
        name: "Black rot", isHealthy: false, infectious: true, treatable: true,
        summary: "A fungal disease causing 'frog-eye' leaf spots and a firm fruit rot, often from cankered wood.",
        action: "Prune out cankers and mummified fruit; protect with fungicide in warm, wet weather.")
    static let appleRust = DiseaseInfo(
        name: "Cedar apple rust", isHealthy: false, infectious: true, treatable: true,
        summary: "Bright orange-yellow leaf spots; needs nearby junipers to complete its life cycle.",
        action: "Remove nearby junipers if possible; apply fungicide from pink bud through early summer.")
    static let fireBlight = DiseaseInfo(
        name: "Fire blight", isHealthy: false, infectious: true, treatable: false,
        summary: "A fast bacterial disease (Erwinia amylovora); shoots wilt into a 'shepherd's crook' and blacken.",
        action: "Cut 30 cm below visible infection in dry weather; sterilize tools between cuts. No cure once systemic.")

    // Cherry
    static let littleCherry = DiseaseInfo(
        name: "Little cherry / X-disease", isHealthy: false, infectious: true, treatable: false,
        summary: "A virus/phytoplasma complex producing small, pale, low-sugar, bitter fruit. Spread by leafhoppers and mealybugs.",
        action: "No cure — confirm by lab test and remove infected trees to protect the block. Control insect vectors.")
    static let cherryPowderyMildew = DiseaseInfo(
        name: "Powdery mildew", isHealthy: false, infectious: true, treatable: true,
        summary: "White powdery fungal colonies on leaves and fruit, common in the Pacific Northwest.",
        action: "Improve airflow; apply sulfur or a labeled fungicide on a protectant schedule.")
    static let bacterialCanker = DiseaseInfo(
        name: "Bacterial canker", isHealthy: false, infectious: true, treatable: false,
        summary: "Pseudomonas syringae; gumming cankers and dieback, especially damaging to young trees.",
        action: "Prune in dry summer weather; avoid frost injury. Manage copper sprays in fall/spring.")

    // Tomato
    static let tomatoEarlyBlight = DiseaseInfo(
        name: "Early blight", isHealthy: false, infectious: true, treatable: true,
        summary: "Alternaria solani; concentric 'target' spots on lower leaves, spreading upward.",
        action: "Remove affected leaves, mulch to limit soil splash, apply fungicide if spreading.")
    static let tomatoLateBlight = DiseaseInfo(
        name: "Late blight", isHealthy: false, infectious: true, treatable: false,
        summary: "Phytophthora infestans; greasy gray-green lesions that can destroy a crop in days in cool, wet weather.",
        action: "Act fast — remove and bag infected plants; protect remaining plants. Highly contagious.")
    static let tomatoSeptoria = DiseaseInfo(
        name: "Septoria leaf spot", isHealthy: false, infectious: true, treatable: true,
        summary: "Many small circular spots with dark borders and pale centers on lower foliage.",
        action: "Remove lower leaves, water at the base, and apply fungicide on a regular schedule.")

    /// Candidate diseases for a crop (excluding healthy), used by the mock classifier.
    static func candidates(for crop: Crop) -> [DiseaseInfo] {
        switch crop {
        case .apple:  return [appleScab, appleBlackRot, appleRust, fireBlight]
        case .cherry: return [littleCherry, cherryPowderyMildew, bacterialCanker]
        case .tomato: return [tomatoEarlyBlight, tomatoLateBlight, tomatoSeptoria]
        }
    }
}

// MARK: - Crop health

struct CropHealth: Codable, Hashable {
    var score: Int          // 0–100 overall
    var chlorosisPct: Double // % yellow/off-green
    var lesionPct: Double    // % lesion/spot coverage
    var sizeEstimate: Double // 0–1 relative size in frame
    var lifecycleStage: String

    var scoreColor: Color {
        switch score {
        case 80...:  return .green
        case 55..<80: return .yellow
        default:     return .red
        }
    }
}

// MARK: - Spectral / ripeness

enum RipenessClass: String, Codable, CaseIterable {
    case unripe, ripe, overripe

    var displayName: String {
        switch self {
        case .unripe:   return "Not ready"
        case .ripe:     return "Ripe"
        case .overripe: return "Overripe"
        }
    }
    var color: Color {
        switch self {
        case .unripe:   return .orange
        case .ripe:     return .green
        case .overripe: return .brown
        }
    }
}

struct SpectralReading: Codable, Hashable {
    var channels: [Double]   // 18 reflectance values (0–1)
    var ripeness: RipenessClass
    var brix: Double         // estimated °Brix
    var stability: Double    // 0–1, from averaging repeated reads

    /// AS7265x channel center wavelengths (nm), 410–940 nm.
    static let wavelengths: [Int] = [410, 435, 460, 485, 510, 535, 560, 585,
                                     610, 645, 680, 705, 730, 760, 810, 860, 900, 940]
}

// MARK: - Fusion outputs

enum Verdict: String, Codable {
    case diseased, notReady, premium

    var title: String {
        switch self {
        case .diseased: return "Diseased"
        case .notReady: return "Healthy — not ready"
        case .premium:  return "Healthy & premium"
        }
    }
    var emoji: String {
        switch self {
        case .diseased: return "🔴"
        case .notReady: return "🟠"
        case .premium:  return "🟢"
        }
    }
    var color: Color {
        switch self {
        case .diseased: return .red
        case .notReady: return .orange
        case .premium:  return .green
        }
    }
}

enum RiskLabel: String, Codable {
    case infectious, treatable, cosmetic, none

    var displayName: String {
        switch self {
        case .infectious: return "Likely infectious"
        case .treatable:  return "Treatable"
        case .cosmetic:   return "Cosmetic"
        case .none:       return "No disease"
        }
    }
}

enum Urgency: String, Codable {
    case low, medium, high

    var displayName: String {
        switch self {
        case .low:    return "Low urgency"
        case .medium: return "Act soon"
        case .high:   return "Act now"
        }
    }
    var color: Color {
        switch self {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }
}

struct FusionResult {
    var verdict: Verdict
    var recommendation: String
    var risk: RiskLabel
    var urgency: Urgency
    var spoken: String
}

// MARK: - Weather

struct WeatherSnapshot: Codable, Hashable {
    var tempC: Double
    var humidityPct: Double
    var precipRecentMM: Double
    var precipForecastMM: Double
    var summary: String
    var capturedAt: Date

    var diseasePressure: String {
        // Warm + humid + recent moisture favors fungal/bacterial spread.
        if tempC >= 15 && humidityPct >= 70 { return "high" }
        if tempC >= 10 && humidityPct >= 55 { return "moderate" }
        return "low"
    }
}

// MARK: - Scan record (persisted)

struct ScanRecord: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var plantTag: String           // groups repeat scans of one plant/block (powers trends)
    var variety: Variety
    var imageData: Data?           // downscaled JPEG for history
    var disease: DiseaseInfo
    var diseaseConfidence: Double  // 0–1
    var alternatives: [String]
    var health: CropHealth
    var spectral: SpectralReading
    var verdict: Verdict
    var recommendation: String
    var risk: RiskLabel
    var urgency: Urgency
    var weather: WeatherSnapshot?
    var userConfirmed: Bool?       // F7: nil = unreviewed, true = confirmed, false = corrected
    var userCorrectionNote: String?
}
