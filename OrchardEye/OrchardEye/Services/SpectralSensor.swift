//
//  SpectralSensor.swift
//  OrchardEye
//
//  Stage 1/4 (spectral). `SpectralSensor` is the seam a real CoreBluetooth
//  AS7265x bridge plugs into. `SimulatedSpectralSensor` synthesizes a plausible
//  18-channel reflectance curve so the NIR flow works with no hardware.
//  `QualityModel` maps a reading → ripeness + estimated Brix.
//

import Foundation

enum SensorError: Error { case notConnected }

protocol SpectralSensor: AnyObject {
    var isConnected: Bool { get }
    func connect() async throws
    func read() async throws -> [Double]   // 18 reflectance channels (0–1)
}

final class SimulatedSpectralSensor: SpectralSensor {
    private(set) var isConnected = false

    // The "fruit" being measured. Held stable so the 3 rapid reads of one scan
    // agree (high stability); a fresh fruit is assumed after a short gap.
    private var baseBrix = Double.random(in: 8...18)
    private var lastRead = Date.distantPast

    func connect() async throws {
        try? await Task.sleep(nanoseconds: 800_000_000)
        isConnected = true
    }

    func read() async throws -> [Double] {
        guard isConnected else { throw SensorError.notConnected }
        try? await Task.sleep(nanoseconds: 400_000_000)

        // New fruit if it's been a couple seconds since the last read.
        if Date().timeIntervalSince(lastRead) > 2 {
            baseBrix = Double.random(in: 8...18)
        }
        lastRead = Date()
        let ripe01 = (baseBrix - 8) / 10.0   // 0 unripe … 1 very ripe

        var channels: [Double] = []
        for wl in SpectralReading.wavelengths {
            var v: Double
            if wl < 560 {
                v = 0.18 + 0.04 * ripe01                    // visible blue-green
            } else if wl < 700 {
                let dip = (wl == 680 ? 0.10 : 0.05) * (1 - ripe01)  // chlorophyll absorption fades as it ripens
                v = 0.30 + 0.25 * ripe01 - dip
            } else {
                v = 0.55 + 0.30 * ripe01                    // NIR plateau rises with ripeness
            }
            v += Double.random(in: -0.01...0.01)            // small per-read noise → high stability
            channels.append(min(1, max(0, v)))
        }
        return channels
    }
}

enum QualityModel {

    /// Map an 18-channel reflectance reading to ripeness + estimated °Brix.
    /// (Stand-in for the per-variety PLS / shallow-ANN calibration in the PRD.)
    static func evaluate(channels: [Double], variety: Variety) -> (RipenessClass, Double) {
        let wavelengths = SpectralReading.wavelengths
        guard channels.count == wavelengths.count else { return (.unripe, 10) }

        // Ripeness rises as the NIR plateau lifts and the 680 nm chlorophyll dip
        // fills in. Combine both into a 0–1 ripeness, then to °Brix.
        let nir = average(channels, atOrAbove: 760)                 // ~0.55 … 0.85
        let redDip = channels[wavelengths.firstIndex(of: 680) ?? 0] // ~0.20 … 0.55
        let ripeFromNIR = (nir - 0.55) / 0.30
        let ripeFromRed = (redDip - 0.20) / 0.35
        let ripe01 = max(0, min(1, (ripeFromNIR + ripeFromRed) / 2))

        let brix = 8 + ripe01 * 10                                  // 8 … 18 °Brix
        let ripeness: RipenessClass
        switch brix {
        case ..<11.5:     ripeness = .unripe
        case 11.5..<15.5: ripeness = .ripe
        default:          ripeness = .overripe
        }
        return (ripeness, (brix * 10).rounded() / 10)
    }

    private static func average(_ channels: [Double], atOrAbove wl: Int) -> Double {
        let idxs = SpectralReading.wavelengths.enumerated()
            .filter { $0.element >= wl }
            .map { $0.offset }
        let vals = idxs.map { channels[$0] }
        return vals.isEmpty ? 0 : vals.reduce(0, +) / Double(vals.count)
    }

    /// Average several reads channel-by-channel.
    static func averageReads(_ reads: [[Double]]) -> [Double] {
        guard let first = reads.first else { return [] }
        var out = [Double](repeating: 0, count: first.count)
        for r in reads where r.count == first.count {
            for i in 0..<r.count { out[i] += r[i] }
        }
        return out.map { $0 / Double(reads.count) }
    }

    /// 0–1 stability score from how tightly repeated reads agree.
    static func stability(_ reads: [[Double]]) -> Double {
        guard reads.count > 1, let first = reads.first else { return 1 }
        let mean = averageReads(reads)
        var totalVar = 0.0
        for r in reads where r.count == first.count {
            for i in 0..<r.count { totalVar += (r[i] - mean[i]) * (r[i] - mean[i]) }
        }
        let mse = totalVar / Double(reads.count * first.count)
        return max(0, min(1, 1 - mse * 30))
    }
}
