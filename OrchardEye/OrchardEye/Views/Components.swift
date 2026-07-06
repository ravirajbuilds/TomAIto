//
//  Components.swift
//  OrchardEye
//
//  Small reusable views: cards, pills, the spectrum chart, and a camera picker.
//

import SwiftUI
import Charts
import UIKit

// MARK: - Layout

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.brandLeaf.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

struct Pill: View {
    let text: String
    var color: Color = .secondary
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct ConfidenceBar: View {
    let value: Double   // 0–1
    var tint: Color = .accentColor
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.tertiarySystemFill))
                Capsule().fill(tint)
                    .frame(width: max(6, geo.size.width * value))
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Spectrum chart

private struct SpectralBand: Identifiable {
    let id: Int
    let wavelength: Int
    let value: Double
}

struct SpectrumChart: View {
    let channels: [Double]

    private var bands: [SpectralBand] {
        zip(SpectralReading.wavelengths, channels).enumerated().map {
            SpectralBand(id: $0.offset, wavelength: $0.element.0, value: $0.element.1)
        }
    }

    var body: some View {
        Chart(bands) { band in
            LineMark(x: .value("Wavelength (nm)", band.wavelength),
                     y: .value("Reflectance", band.value))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor)
            AreaMark(x: .value("Wavelength (nm)", band.wavelength),
                     y: .value("Reflectance", band.value))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor.opacity(0.12))
        }
        .chartYScale(domain: 0...1)
        .chartXAxis {
            AxisMarks(values: [410, 560, 680, 760, 940]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let nm = value.as(Int.self) { Text("\(nm)") }
                }
            }
        }
        .frame(height: 150)
    }
}

// MARK: - Camera (device only; Simulator has no camera)

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
}
