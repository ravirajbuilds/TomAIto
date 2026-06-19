//
//  QualityGate.swift
//  OrchardEye
//
//  Stage 2 of the pipeline: cheaply reject unusable captures BEFORE inference,
//  and tell the user exactly how to retake. This is the biggest real-world
//  accuracy lever (lab-trained models degrade on bad field photos).
//

import UIKit

struct QualityResult {
    var passed: Bool
    var issues: [String]   // human-readable retake tips
}

enum ImageQualityGate {

    static func check(_ image: UIImage) -> QualityResult {
        let s = ImageAnalysis.stats(for: image)
        var issues: [String] = []

        if s.brightness < 0.12 {
            issues.append("Too dark — move into better light.")
        } else if s.brightness > 0.93 {
            issues.append("Too bright or glare — angle away from the sun.")
        }

        if s.detail < 0.05 {
            issues.append("Looks blurry — hold steady and tap to focus.")
        }

        let subject = s.greenFraction + s.brownFraction + s.yellowFraction
        if subject < 0.06 {
            issues.append("No leaf or fruit detected — move closer and fill the frame.")
        }

        return QualityResult(passed: issues.isEmpty, issues: issues)
    }
}
