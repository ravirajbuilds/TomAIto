//
//  VerdictView.swift
//  OrchardEye
//
//  Stage 6: the single fused verdict (F3), spoken aloud (A4), saved to history,
//  and confirmed/corrected by the grower (F7).
//

import SwiftUI

struct VerdictView: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var vm: ScanViewModel
    @ObservedObject var voice: VoiceGuide

    @State private var showCorrect = false
    @State private var reviewState = 0   // 0 none · 1 confirmed · 2 corrected

    var body: some View {
        ScrollView {
            if let f = vm.fusion {
                VStack(spacing: 16) {
                    banner(f)
                    recommendationCard(f)
                    qualityCard
                    detailsCard(f)
                    reviewCard
                    Button { withAnimation { vm.reset() } } label: {
                        Label("New scan", systemImage: "plus.viewfinder").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered).controlSize(.large)
                }
                .padding()
            }
        }
        .onAppear {
            if vm.savedRecordID == nil { vm.save(app: app, confirmed: nil) }
        }
        .sheet(isPresented: $showCorrect) { correctionSheet }
    }

    // MARK: Banner

    private func banner(_ f: FusionResult) -> some View {
        VStack(spacing: 8) {
            Text(f.verdict.emoji).font(.system(size: 44))
            Text(f.verdict.title).font(.title.bold()).foregroundStyle(.white)
            HStack(spacing: 8) {
                Pill(text: f.risk.displayName, color: .white)
                Pill(text: f.urgency.displayName, color: .white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(f.verdict.color.gradient, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Recommendation + voice

    private func recommendationCard(_ f: FusionResult) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("What to do").font(.headline)
                Text(f.recommendation).font(.body)
                Button {
                    if voice.isSpeaking { voice.stop() } else { voice.speak(f.spoken) }
                } label: {
                    Label(voice.isSpeaking ? "Stop" : "Hear it",
                          systemImage: voice.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    // MARK: Quality

    @ViewBuilder private var qualityCard: some View {
        if let s = vm.spectral {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quality (NIR)").font(.headline)
                    SpectrumChart(channels: s.channels)
                    HStack {
                        Pill(text: s.ripeness.displayName, color: s.ripeness.color)
                        Pill(text: String(format: "%.0f° Brix", s.brix), color: .accentColor)
                        Spacer()
                        Text("410–940 nm · 18 ch").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: Details

    private func detailsCard(_ f: FusionResult) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Details").font(.headline)
                if let c = vm.classification {
                    InfoRow(label: "Disease", value: c.disease.name)
                    InfoRow(label: "Confidence", value: "\(Int(c.confidence * 100))%")
                    InfoRow(label: "Health score", value: "\(c.health.score)/100")
                }
                InfoRow(label: "Plant / block", value: vm.plantTag)
                InfoRow(label: "Variety", value: app.selectedVariety.displayName)
                if let w = app.currentWeather {
                    InfoRow(label: "Weather", value: w.summary)
                }
            }
        }
    }

    // MARK: Review (F7)

    private var reviewCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Was this right?").font(.headline)
                Text("Your feedback trains OrchardEye for your orchard and varieties.")
                    .font(.caption).foregroundStyle(.secondary)
                if reviewState == 0 {
                    HStack {
                        Button {
                            vm.save(app: app, confirmed: true)
                            reviewState = 1
                        } label: {
                            Label("Confirm", systemImage: "checkmark.circle").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered).tint(.green)
                        Button {
                            showCorrect = true
                        } label: {
                            Label("Correct", systemImage: "pencil").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered).tint(.orange)
                    }
                } else {
                    Label(reviewState == 1 ? "Thanks, confirmed and saved." : "Thanks, correction saved.",
                          systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green).font(.subheadline)
                }
            }
        }
    }

    private var correctionSheet: some View {
        NavigationStack {
            Form {
                Section("What was it actually?") {
                    TextField("e.g. this was sunburn, not scab", text: $vm.reviewNote, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section {
                    Text("Logged locally as community knowledge. Corrections are the highest-value training signal.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Correct verdict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCorrect = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.save(app: app, confirmed: false)
                        reviewState = 2
                        showCorrect = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
