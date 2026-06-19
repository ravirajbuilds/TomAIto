//
//  ImageAnalysis.swift
//  OrchardEye
//
//  Lightweight on-device image stats used by the quality gate and the
//  (placeholder) disease classifier. Real color/greenness analysis — this is
//  the seam where a trained Core ML model would later plug in.
//

import UIKit

struct ImageStats {
    var avgR = 0.0, avgG = 0.0, avgB = 0.0
    var brightness = 0.0      // 0–1 mean luminance
    var greenFraction = 0.0   // healthy green
    var yellowFraction = 0.0  // chlorosis (yellowing)
    var brownFraction = 0.0   // necrosis / lesions
    var detail = 0.0          // 0–1 sharpness proxy (luminance variance)
}

enum ImageAnalysis {

    /// Render the image into a small RGBA grid and compute color/brightness stats.
    static func stats(for image: UIImage, sampleSize: Int = 40) -> ImageStats {
        let w = sampleSize, h = sampleSize
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let cg = image.cgImage else { return ImageStats() }

        return pixels.withUnsafeMutableBytes { raw -> ImageStats in
            guard let base = raw.baseAddress,
                  let ctx = CGContext(data: base, width: w, height: h, bitsPerComponent: 8,
                                      bytesPerRow: w * 4, space: colorSpace, bitmapInfo: bitmapInfo)
            else { return ImageStats() }

            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)))

            let p = base.assumingMemoryBound(to: UInt8.self)
            let n = w * h
            var sr = 0.0, sg = 0.0, sb = 0.0
            var green = 0, yellow = 0, brown = 0
            var lum = [Double](repeating: 0, count: n)

            for i in 0..<n {
                let r = Double(p[i * 4]) / 255.0
                let g = Double(p[i * 4 + 1]) / 255.0
                let b = Double(p[i * 4 + 2]) / 255.0
                sr += r; sg += g; sb += b
                let l = 0.299 * r + 0.587 * g + 0.114 * b
                lum[i] = l
                if g > r && g > b && g > 0.25 {
                    green += 1
                } else if r > 0.45 && g > 0.32 && b < 0.35 && abs(r - g) < 0.28 {
                    yellow += 1
                } else if r > 0.18 && r < 0.62 && g < 0.45 && b < 0.40 && r >= g {
                    brown += 1
                }
            }

            let nd = Double(n)
            let mean = lum.reduce(0, +) / nd
            let variance = lum.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / nd

            return ImageStats(
                avgR: sr / nd, avgG: sg / nd, avgB: sb / nd,
                brightness: mean,
                greenFraction: Double(green) / nd,
                yellowFraction: Double(yellow) / nd,
                brownFraction: Double(brown) / nd,
                detail: min(1.0, variance * 12.0))
        }
    }

    /// Downscale + JPEG-encode for compact history storage.
    static func thumbnailJPEG(_ image: UIImage, maxDimension: CGFloat = 600, quality: CGFloat = 0.7) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1.0, maxDimension / max(size.width, size.height))
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let img = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return img.jpegData(compressionQuality: quality)
    }

    /// Procedurally generated sample leaves so the full flow runs in the Simulator
    /// (which has no camera). `healthy` toggles a clean leaf vs. a spotted one.
    static func sampleLeaf(healthy: Bool) -> UIImage {
        let size = CGSize(width: 500, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { c in
            let ctx = c.cgContext
            UIColor(red: 0.86, green: 0.90, blue: 0.84, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let leafRect = CGRect(x: 80, y: 60, width: 340, height: 380)
            let base = healthy ? UIColor(red: 0.22, green: 0.56, blue: 0.20, alpha: 1)
                               : UIColor(red: 0.42, green: 0.52, blue: 0.18, alpha: 1)
            base.setFill()
            UIBezierPath(ovalIn: leafRect).fill()

            UIColor(red: 0.30, green: 0.45, blue: 0.18, alpha: 1).setStroke()
            let rib = UIBezierPath()
            rib.move(to: CGPoint(x: 250, y: 70))
            rib.addLine(to: CGPoint(x: 250, y: 430))
            rib.lineWidth = 6
            rib.stroke()

            if !healthy {
                for _ in 0..<14 {
                    let x = CGFloat.random(in: 110...370)
                    let y = CGFloat.random(in: 100...400)
                    let d = CGFloat.random(in: 16...44)
                    UIColor(red: 0.80, green: 0.75, blue: 0.25, alpha: 0.5).setFill()
                    UIBezierPath(ovalIn: CGRect(x: x - 6, y: y - 6, width: d + 12, height: d + 12)).fill()
                    UIColor(red: 0.36, green: 0.24, blue: 0.10, alpha: 0.92).setFill()
                    UIBezierPath(ovalIn: CGRect(x: x, y: y, width: d, height: d)).fill()
                }
            }
        }
    }
}
