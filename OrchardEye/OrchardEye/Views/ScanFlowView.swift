//
//  ScanFlowView.swift
//  OrchardEye
//
//  The end-to-end scan: capture → quality gate → disease + health → NIR quality
//  → fused verdict (F1–F3). Drives ScanViewModel.
//

import SwiftUI
import PhotosUI
import UIKit

@MainActor
final class ScanViewModel: ObservableObject {
    enum Step: Equatable { case capture, qualityFail, disease, spectral, verdict }

    @Published var step: Step = .capture
    @Published var image: UIImage?
    @Published var qualityIssues: [String] = []
    @Published var classification: DiseaseClassification?
    @Published var spectral: SpectralReading?
    @Published var fusion: FusionResult?
    @Published var isWorking = false
    @Published var statusText = ""
    @Published var plantTag = "Block 1"
    @Published var savedRecordID: UUID?
    @Published var reviewNote = ""

    func reset() {
        step = .capture; image = nil; qualityIssues = []
        classification = nil; spectral = nil; fusion = nil
        isWorking = false; statusText = ""; savedRecordID = nil; reviewNote = ""
    }

    func useImage(_ img: UIImage, app: AppModel) {
        image = img
        let q = ImageQualityGate.check(img)
        if q.passed {
            Task { await self.runDisease(app: app) }
        } else {
            qualityIssues = q.issues
            withAnimation { step = .qualityFail }
        }
    }

    func retake() {
        image = nil; qualityIssues = []
        withAnimation { step = .capture }
    }

    func runDisease(app: AppModel) async {
        guard let img = image else { return }
        isWorking = true; statusText = "Checking image & analyzing…"
        let c = await app.classifier.classify(image: img, crop: app.selectedVariety.crop)
        classification = c
        isWorking = false
        withAnimation { step = .disease }
    }

    func runSpectral(app: AppModel) async {
        isWorking = true
        statusText = "Connecting to sensor…"
        do {
            if !app.sensor.isConnected { try await app.sensor.connect() }
            statusText = "Reading spectrum (3 scans)…"
            var reads: [[Double]] = []
            for _ in 0..<3 { reads.append(try await app.sensor.read()) }
            let avg = QualityModel.averageReads(reads)
            let stability = QualityModel.stability(reads)
            let (ripeness, brix) = QualityModel.evaluate(channels: avg, variety: app.selectedVariety)
            spectral = SpectralReading(channels: avg, ripeness: ripeness, brix: brix, stability: stability)
            isWorking = false
            await fuse(app: app)
        } catch {
            isWorking = false
            statusText = "Sensor not connected — tap Scan to retry."
        }
    }

    func fuse(app: AppModel) async {
        guard let c = classification, let s = spectral else { return }
        let trend = TrendAnalyzer.summary(for: plantTag, in: app.store.records)
        fusion = FusionEngine.fuse(disease: c, spectral: s, weather: app.currentWeather,
                                   priorTrend: trend, variety: app.selectedVariety)
        withAnimation { step = .verdict }
    }

    func makeRecord(app: AppModel, confirmed: Bool?) -> ScanRecord? {
        guard let c = classification, let s = spectral, let f = fusion else { return nil }
        return ScanRecord(
            plantTag: plantTag.isEmpty ? "Unlabeled" : plantTag,
            variety: app.selectedVariety,
            imageData: image.flatMap { ImageAnalysis.thumbnailJPEG($0) },
            disease: c.disease,
            diseaseConfidence: c.confidence,
            alternatives: c.alternatives,
            health: c.health,
            spectral: s,
            verdict: f.verdict,
            recommendation: f.recommendation,
            risk: f.risk,
            urgency: f.urgency,
            weather: app.currentWeather,
            userConfirmed: confirmed,
            userCorrectionNote: (confirmed == false && !reviewNote.isEmpty) ? reviewNote : nil)
    }

    func save(app: AppModel, confirmed: Bool?) {
        if let id = savedRecordID, var existing = app.store.records.first(where: { $0.id == id }) {
            existing.userConfirmed = confirmed
            if confirmed == false && !reviewNote.isEmpty { existing.userCorrectionNote = reviewNote }
            app.store.update(existing)
            return
        }
        if let rec = makeRecord(app: app, confirmed: confirmed) {
            app.store.add(rec)
            savedRecordID = rec.id
        }
    }
}

struct ScanFlowView: View {
    @EnvironmentObject var app: AppModel
    @StateObject private var vm = ScanViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ZStack {
                content
                if vm.isWorking { workingOverlay }
            }
            .navigationTitle("OrchardEye")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if vm.step != .capture {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("New") { withAnimation { vm.reset() } }
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { img in
                    showCamera = false
                    vm.useImage(img, app: app)
                }
                .ignoresSafeArea()
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task { @MainActor in
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        vm.useImage(img, app: app)
                    }
                    photoItem = nil
                }
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch vm.step {
        case .capture:     captureStep
        case .qualityFail: qualityFailStep
        case .disease:     diseaseStep
        case .spectral:    spectralStep
        case .verdict:     VerdictView(vm: vm, voice: app.voice)
        }
    }

    // MARK: Capture

    private var captureStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("New scan").font(.headline)
                        HStack {
                            Text("Plant / block").foregroundStyle(.secondary)
                            Spacer()
                            TextField("Label", text: $vm.plantTag)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 170)
                        }
                        .font(.subheadline)
                        Divider()
                        Text("Step 1 — photo of a leaf or fruit")
                            .font(.subheadline).foregroundStyle(.secondary)

                        if CameraPicker.isAvailable {
                            Button { showCamera = true } label: {
                                Label("Take photo", systemImage: "camera.fill").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Choose photo", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        HStack {
                            Button { vm.useImage(ImageAnalysis.sampleLeaf(healthy: true), app: app) } label: {
                                Text("Sample: healthy").frame(maxWidth: .infinity)
                            }.buttonStyle(.bordered)
                            Button { vm.useImage(ImageAnalysis.sampleLeaf(healthy: false), app: app) } label: {
                                Text("Sample: diseased").frame(maxWidth: .infinity)
                            }.buttonStyle(.bordered)
                        }

                        Text("No camera or sensor? Use a sample to run the full flow — readings are simulated.")
                            .font(.footnote).foregroundStyle(.tertiary)
                    }
                }
            }
            .padding()
        }
    }

    private var headerCard: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(app.selectedVariety.crop.emoji)  \(app.selectedVariety.name)")
                        .font(.headline)
                    Text(app.selectedVariety.crop.displayName).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let w = app.currentWeather {
                    VStack(alignment: .trailing, spacing: 4) {
                        Label(w.summary, systemImage: "cloud.sun")
                            .font(.caption).foregroundStyle(.secondary)
                            .labelStyle(.titleAndIcon)
                        Text("pressure: \(w.diseasePressure)").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: Quality fail

    private var qualityFailStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50)).foregroundStyle(Color.orange)
            Text("Let's retake that").font(.title2.bold())
            VStack(alignment: .leading, spacing: 10) {
                ForEach(vm.qualityIssues, id: \.self) { issue in
                    Label(issue, systemImage: "arrow.right.circle")
                }
            }
            .font(.subheadline)
            Button { vm.retake() } label: {
                Text("Retake").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
        }
        .padding()
    }

    // MARK: Disease result

    private var diseaseStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let img = vm.image {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(height: 190).frame(maxWidth: .infinity).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                if let c = vm.classification {
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(c.disease.isHealthy ? "🟢" : "🔴")
                                Text(c.disease.name).font(.headline)
                            }
                            Text(c.disease.summary).font(.subheadline).foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Confidence"); Spacer(); Text("\(Int(c.confidence * 100))%")
                                }.font(.caption)
                                ConfidenceBar(value: c.confidence, tint: c.disease.isHealthy ? .green : .red)
                            }
                            if !c.disease.isHealthy && c.confidence < kDiseaseConfidenceThreshold && !c.alternatives.isEmpty {
                                Text("Also possible: \(c.alternatives.joined(separator: ", "))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Crop health").font(.headline)
                            HStack {
                                Text("Score").foregroundStyle(.secondary); Spacer()
                                Text("\(c.health.score)/100")
                                    .foregroundStyle(c.health.scoreColor).fontWeight(.semibold)
                            }.font(.subheadline)
                            InfoRow(label: "Lesion area", value: String(format: "%.0f%%", c.health.lesionPct))
                            InfoRow(label: "Yellowing", value: String(format: "%.0f%%", c.health.chlorosisPct))
                            InfoRow(label: "Lifecycle stage", value: c.health.lifecycleStage)
                        }
                    }
                    Button { withAnimation { vm.step = .spectral } } label: {
                        Label("Next: quality scan", systemImage: "arrow.right").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                }
            }
            .padding()
        }
    }

    // MARK: Spectral

    private var spectralStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Step 2 — NIR quality scan").font(.headline)
                        Text("Hold the sensor against the fruit and scan. We average 3 reads for stability.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if let s = vm.spectral {
                            SpectrumChart(channels: s.channels)
                            HStack {
                                Pill(text: s.ripeness.displayName, color: s.ripeness.color)
                                Pill(text: String(format: "%.0f° Brix", s.brix), color: .accentColor)
                                Spacer()
                                Text("stability \(Int(s.stability * 100))%")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Button { Task { await vm.runSpectral(app: app) } } label: {
                            Label(vm.spectral == nil ? "Scan fruit" : "Re-scan",
                                  systemImage: "dot.radiowaves.left.and.right").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                        .disabled(vm.isWorking)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: Working overlay

    private var workingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                Text(vm.statusText).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    ScanFlowView().environmentObject(AppModel())
}
