//
//  HistoryView.swift
//  OrchardEye
//
//  F4 — saved scans, detail, and CSV export (share sheet).
//

import SwiftUI
import UIKit

struct HistoryView: View {
    @EnvironmentObject var store: ScanStore
    @State private var csvURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    ContentUnavailableView("No scans yet", systemImage: "leaf",
                        description: Text("Saved scans will appear here. Try a scan to get started."))
                } else {
                    List {
                        ForEach(store.records) { record in
                            NavigationLink { ScanDetailView(record: record) } label: { row(record) }
                        }
                        .onDelete { store.delete(at: $0) }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !store.records.isEmpty, let url = csvURL {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                    }
                }
            }
            .task(id: store.records.count) {
                csvURL = store.exportCSV()
            }
        }
    }

    private func row(_ record: ScanRecord) -> some View {
        HStack(spacing: 12) {
            thumbnail(record)
            VStack(alignment: .leading, spacing: 3) {
                Text(record.plantTag).font(.subheadline.weight(.semibold))
                Text(record.disease.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Text(record.date, format: .dateTime.month().day().hour().minute())
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            Text(record.verdict.emoji)
        }
    }

    @ViewBuilder private func thumbnail(_ record: ScanRecord) -> some View {
        if let data = record.imageData, let ui = UIImage(data: data) {
            Image(uiImage: ui).resizable().scaledToFill()
                .frame(width: 46, height: 46).clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill))
                .frame(width: 46, height: 46)
                .overlay(Image(systemName: "leaf").foregroundStyle(.secondary))
        }
    }
}

struct ScanDetailView: View {
    let record: ScanRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let data = record.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFill()
                        .frame(height: 200).frame(maxWidth: .infinity).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                HStack {
                    Text(record.verdict.emoji).font(.title)
                    Text(record.verdict.title).font(.title3.bold())
                    Spacer()
                    Pill(text: record.urgency.displayName, color: record.urgency.color)
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommendation").font(.headline)
                        Text(record.recommendation)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Readings").font(.headline)
                        InfoRow(label: "Disease", value: record.disease.name)
                        InfoRow(label: "Confidence", value: "\(Int(record.diseaseConfidence * 100))%")
                        InfoRow(label: "Health score", value: "\(record.health.score)/100")
                        InfoRow(label: "Lesion area", value: String(format: "%.0f%%", record.health.lesionPct))
                        InfoRow(label: "Ripeness", value: record.spectral.ripeness.displayName)
                        InfoRow(label: "Brix", value: String(format: "%.0f°", record.spectral.brix))
                        InfoRow(label: "Risk", value: record.risk.displayName)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context").font(.headline)
                        InfoRow(label: "Plant / block", value: record.plantTag)
                        InfoRow(label: "Variety", value: record.variety.displayName)
                        InfoRow(label: "Date", value: record.date.formatted(date: .abbreviated, time: .shortened))
                        if let w = record.weather { InfoRow(label: "Weather", value: w.summary) }
                        if let confirmed = record.userConfirmed {
                            InfoRow(label: "Review", value: confirmed ? "Confirmed" : "Corrected")
                        }
                        if let note = record.userCorrectionNote {
                            InfoRow(label: "Note", value: note)
                        }
                    }
                }

                if !record.spectral.channels.isEmpty {
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Spectrum").font(.headline)
                            SpectrumChart(channels: record.spectral.channels)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(record.plantTag)
        .navigationBarTitleDisplayMode(.inline)
    }
}
