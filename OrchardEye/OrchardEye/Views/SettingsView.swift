//
//  SettingsView.swift
//  OrchardEye
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Crop & variety") {
                    Picker("Variety", selection: Binding(get: { app.selectedVariety },
                                                         set: { app.setVariety($0) })) {
                        ForEach(Variety.all) { v in
                            Text("\(v.crop.emoji)  \(v.name)").tag(v)
                        }
                    }
                    Text("Brix and ripeness calibration is variety-specific.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Sensor") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(app.sensor.isConnected ? "Connected (simulated)" : "Simulated")
                            .foregroundStyle(.secondary)
                    }
                    Button("Re-run setup") { app.resetOnboarding() }
                }

                Section("Weather") {
                    if let w = app.currentWeather {
                        InfoRow(label: "Now", value: w.summary)
                        InfoRow(label: "Disease pressure", value: w.diseasePressure)
                    } else {
                        Text("Not loaded").foregroundStyle(.secondary)
                    }
                    Button("Refresh") { Task { await app.refreshWeather() } }
                }

                Section("About") {
                    Text("OrchardEye — a dual-sensor crop disease & quality scanner, built for the Congressional App Challenge (WA-08 tree-fruit country).")
                        .font(.subheadline)
                    Text("This build uses a placeholder vision model and a simulated NIR sensor so the full flow is demoable. Spectral claims are limited to what 410–940 nm sensing can really do.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView().environmentObject(AppModel())
}
