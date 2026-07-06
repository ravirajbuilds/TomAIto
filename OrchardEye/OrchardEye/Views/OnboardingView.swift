//
//  OnboardingView.swift
//  OrchardEye
//
//  First-run flow (F5): pair the spectral sensor, pick the variety
//  (calibration is variety-specific), and take a white reference.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var app: AppModel
    @State private var step = 0
    @State private var variety = Variety.default
    @State private var pairing = false
    @State private var paired = false
    @State private var calibrating = false
    @State private var calibrated = false

    var body: some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(step), total: 3)
                .padding(.horizontal)

            Spacer()

            switch step {
            case 0: welcome
            case 1: pairStep
            case 2: varietyStep
            default: calibrateStep
            }

            Spacer()

            Button(action: advance) {
                Text(primaryTitle)
            }
            .buttonStyle(BrandButtonStyle())
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.5)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: 18) {
            BrandMark(size: 104)
            Eyebrow(text: "Congressional App Challenge · WA-08")
            VStack(spacing: 6) {
                Text("Welcome to OrchardEye")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("One scan. Two answers.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.brandLeafDark)
            }
            Text("Is it diseased, and is it good? Let's get your sensor set up.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }

    private var pairStep: some View {
        VStack(spacing: 16) {
            Image(systemName: paired ? "checkmark.circle.fill" : "sensor.tag.radiowaves.forward")
                .font(.system(size: 56))
                .foregroundStyle(paired ? Color.green : Color.accentColor)
            Text("Pair the spectral sensor").font(.title2.bold())
            Text(paired ? "Sensor connected." : "Turn on your clip-on NIR sensor and pair over Bluetooth.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !paired {
                Button {
                    pairing = true
                    Task {
                        try? await app.sensor.connect()
                        paired = app.sensor.isConnected
                        pairing = false
                    }
                } label: {
                    if pairing { ProgressView() } else { Text("Pair sensor") }
                }
                .buttonStyle(.bordered)
                .disabled(pairing)
            }
            Text("No hardware? The sensor is simulated in this build.")
                .font(.footnote).foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
    }

    private var varietyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill").font(.system(size: 48)).foregroundStyle(Color.accentColor)
            Text("Pick your variety").font(.title2.bold())
            Text("Brix and ripeness models are variety-specific.")
                .foregroundStyle(.secondary)
            Picker("Variety", selection: $variety) {
                ForEach(Variety.all) { v in
                    Text("\(v.crop.emoji)  \(v.name)").tag(v)
                }
            }
            .pickerStyle(.wheel)
        }
        .padding(.horizontal)
    }

    private var calibrateStep: some View {
        VStack(spacing: 16) {
            Image(systemName: calibrated ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 56))
                .foregroundStyle(calibrated ? Color.green : Color.accentColor)
            Text("White reference").font(.title2.bold())
            Text(calibrated ? "Calibrated and ready." : "Hold the sensor to the white reference card and capture, so readings stay accurate.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !calibrated {
                Button {
                    calibrating = true
                    Task {
                        try? await Task.sleep(nanoseconds: 900_000_000)
                        calibrated = true
                        calibrating = false
                    }
                } label: {
                    if calibrating { ProgressView() } else { Text("Capture white reference") }
                }
                .buttonStyle(.bordered)
                .disabled(calibrating)
            }
        }
        .padding(.horizontal)
    }

    // MARK: Flow

    private var primaryTitle: String {
        step >= 3 ? "Start scanning" : "Continue"
    }

    private var canAdvance: Bool {
        switch step {
        case 1: return paired
        case 3: return calibrated
        default: return true
        }
    }

    private func advance() {
        if step >= 3 {
            app.completeOnboarding(variety: variety)
        } else {
            withAnimation { step += 1 }
        }
    }
}

#Preview {
    OnboardingView().environmentObject(AppModel())
}
