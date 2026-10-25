import CoreMotion
import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var tracker: HeadTracker
    @EnvironmentObject private var store: SceneStore
    @EnvironmentObject private var engine: SceneEngine
    @ObservedObject private var l10n = L10n.shared
    @State private var step = 0
    @State private var countdown: Int?
    @State private var calibrationTask: Task<Void, Never>?
    @State private var calibratedHere = false
    @State private var testing = false
    @State private var verification = SetupVerification()
    @State private var error: String?

    private let titles = ["setup.permission", "setup.headphones", "setup.calibrate", "setup.test"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 14) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(.indigo.gradient, in: RoundedRectangle(cornerRadius: 19))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(l10n.t("app.name")).font(.largeTitle.bold())
                        Text(l10n.t("setup.tagline")).foregroundStyle(.secondary)
                    }
                }
                progress
                VStack(alignment: .leading, spacing: 16) {
                    Text(l10n.t(titles[step])).font(.title2.bold())
                    stepContent
                    if let error { Text(error).font(.callout).foregroundStyle(.red) }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 20))
                navigation
                Label(l10n.t("setup.findAgain"), systemImage: "menubar.arrow.up.rectangle")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(32)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(l10n.t("setup.open"))
        .onAppear { tracker.refresh() }
        .onDisappear { cancelCalibration() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in tracker.refresh() }
        .onReceive(tracker.$status) { status in
            if !status.isTracking {
                cancelCalibration()
                calibratedHere = false
                verification.reset()
                if testing { testing = false; engine.isSuspended = !UserDefaults.standard.bool(forKey: "setup.completed") }
            }
        }
        .onReceive(engine.feed.$active) { active in
            guard testing else { return }
            let blurActive = active.contains { gesture in
                store.scene("privacy")?.bindings.contains { $0.gesture == gesture && $0.behavior.kind == .blur } == true
            }
            verification.update(isTracking: tracker.status.isTracking, isProtected: blurActive)
        }
        .onChange(of: step) { _, _ in cancelCalibration(); error = nil }
    }

    private var progress: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(0..<titles.count, id: \.self) { index in
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(index <= step ? Color.indigo : Color.secondary.opacity(0.12))
                        if index < step { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white) }
                        else { Text("\(index + 1)").font(.caption.bold()).foregroundStyle(index == step ? .white : .secondary) }
                    }.frame(width: 28, height: 28)
                    Text(l10n.t(titles[index])).font(.caption).foregroundStyle(index == step ? .primary : .secondary)
                }.frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var stepContent: some View {
        switch step {
        case 0:
            Text(l10n.t("setup.permissionHelp")).fixedSize(horizontal: false, vertical: true)
            statusLine(tracker.authorization == .authorized ? "setup.permissionGranted" : "setup.permissionNeeded",
                       ready: tracker.authorization == .authorized)
            if tracker.authorization == .restricted {
                Text(l10n.t("setup.restricted")).font(.callout).foregroundStyle(.secondary)
            } else if tracker.authorization != .authorized {
                Button(l10n.t(tracker.authorization == .notDetermined ? "setup.allow" : "device.openSettings")) {
                    if tracker.authorization == .notDetermined { tracker.start() }
                    else { Permissions.openMotionSettings() }
                }.buttonStyle(.borderedProminent)
            }
        case 1:
            Text(l10n.t("device.hint")).fixedSize(horizontal: false, vertical: true)
            Label(StatusText.tracker(tracker), systemImage: tracker.status.isTracking ? "checkmark.circle.fill" : "airpodspro")
                .foregroundStyle(tracker.status.isTracking ? .green : .secondary)
            if tracker.status == .unsupported {
                Text(l10n.t("setup.unsupported")).font(.callout).foregroundStyle(.secondary)
            } else if !tracker.status.isTracking {
                Text(l10n.t("setup.wait")).font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button(l10n.t("setup.bluetooth")) { Permissions.openBluetoothSettings() }
                    Button(l10n.t(tracker.isReconnecting ? "device.reconnecting" : "device.reconnect")) { tracker.reconnect() }
                        .disabled(tracker.isReconnecting)
                }
            }
            if let lastError = tracker.lastError { Text(lastError).font(.caption).foregroundStyle(.red) }
        case 2:
            Text(l10n.t("setup.calibrateHelp")).fixedSize(horizontal: false, vertical: true)
            SetupPose(feed: engine.feed)
            if let countdown {
                Text(l10n.t("setup.countdown", countdown)).font(.title3.monospacedDigit()).foregroundStyle(.indigo)
                ProgressView()
            } else {
                Button(l10n.t(calibratedHere ? "pose.recalibrate" : "setup.startCalibration")) { beginCalibration() }
                    .buttonStyle(.borderedProminent).disabled(!tracker.status.isTracking)
                if calibratedHere { statusLine("setup.calibrated", ready: true) }
            }
            if !tracker.status.isTracking { Text(l10n.t("setup.lostConnection")).foregroundStyle(.orange).font(.callout) }
        default:
            Text(l10n.t("setup.testHelp")).fixedSize(horizontal: false, vertical: true)
            if !tracker.status.isTracking {
                Text(l10n.t("setup.lostConnection")).font(.callout).foregroundStyle(.orange)
            }
            SetupPose(feed: engine.feed)
            if testing {
                statusLine(testStatusKey, ready: verification.phase == .passed)
            } else {
                Button(l10n.t("setup.startTest")) { beginTest() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!tracker.status.isTracking || !calibratedHere)
            }
            if verification.phase == .passed {
                Divider()
                LoginItemControl()
            }
        }
    }

    private var testStatusKey: String {
        switch verification.phase {
        case .waitingForTurn: return "setup.turnNow"
        case .waitingForReturn: return "setup.lookBack"
        case .passed: return "setup.testPassed"
        }
    }

    private func statusLine(_ key: String, ready: Bool) -> some View {
        Label(l10n.t(key), systemImage: ready ? "checkmark.circle.fill" : "circle.dotted")
            .foregroundStyle(ready ? .green : .secondary)
            .font(.callout.weight(.medium))
    }

    private var canAdvance: Bool {
        switch step {
        case 0: return tracker.authorization == .authorized
        case 1: return tracker.status.isTracking
        case 2: return calibratedHere && countdown == nil && tracker.status.isTracking
        default: return verification.phase == .passed && tracker.status.isTracking && calibratedHere
        }
    }

    private var navigation: some View {
        HStack {
            if step > 0 {
                Button(l10n.t("setup.back")) {
                    testing = false
                    verification.reset()
                    engine.isSuspended = !UserDefaults.standard.bool(forKey: "setup.completed")
                    step -= 1
                }
            }
            Spacer()
            Button(l10n.t(step == 3 ? "setup.finish" : "setup.next")) {
                if step < 3 { step += 1 }
                else {
                    UserDefaults.standard.set(true, forKey: "setup.completed")
                    engine.isSuspended = false
                    SettingsRouter.shared.selection = .scene("privacy")
                }
            }.buttonStyle(.borderedProminent).disabled(!canAdvance)
        }
    }

    private func beginCalibration() {
        calibratedHere = false
        verification.reset()
        error = nil
        calibrationTask = Task { @MainActor in
            for remaining in stride(from: 3, through: 1, by: -1) {
                guard !Task.isCancelled, tracker.status.isTracking, step == 2 else { countdown = nil; return }
                countdown = remaining
                do { try await Task.sleep(for: .seconds(1)) }
                catch { countdown = nil; return }
            }
            guard !Task.isCancelled, step == 2 else { countdown = nil; return }
            calibratedHere = tracker.recenter()
            countdown = nil
            if !calibratedHere { error = l10n.t("setup.lostConnection") }
        }
    }

    private func cancelCalibration() {
        calibrationTask?.cancel()
        calibrationTask = nil
        countdown = nil
    }

    private func beginTest() {
        guard tracker.status.isTracking, calibratedHere else { return }
        guard let privacy = store.scene("privacy"),
              [Gesture.turnLeft, .turnRight].allSatisfy({ gesture in privacy.bindings.contains { $0.gesture == gesture && $0.behavior.kind == .blur } }),
              store.setEnabled("privacy", true).isEmpty else {
            error = l10n.t("setup.privacyConflict")
            return
        }
        error = nil
        verification.reset()
        testing = true
        engine.isSuspended = false
    }
}

/// Keep the per-frame subscription in this small view, away from the guide state.
private struct SetupPose: View {
    @ObservedObject var feed: PoseFeed
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        AngleGauge(label: l10n.t("pose.yaw"), value: feed.forward.yaw,
                   highlight: !feed.active.isDisjoint(with: [.turnLeft, .turnRight]), labelWidth: 100)
            .padding(.vertical, 8)
    }
}
