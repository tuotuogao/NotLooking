import SwiftUI
import Carbon

@main
struct NotLookingApp: App {
    @NSApplicationDelegateAdaptor(NotLookingDelegate.self) private var delegate
    @StateObject private var runtime = NotLookingRuntime.shared

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(runtime.tracker)
                .environmentObject(runtime.engine)
                .environmentObject(runtime.exercise)
        } label: {
            TrackingStatusIcon(tracker: runtime.tracker)
        }
        .menuBarExtraStyle(.window)

        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(L10n.shared.t("menu.settings")) { AppWindow.shared.show() }
                    .keyboardShortcut(",")
            }
        }
    }
}

final class NotLookingRuntime: ObservableObject {
    static let shared = NotLookingRuntime()
    let tracker = HeadTracker()
    let store = SceneStore()
    let engine: SceneEngine
    let exercise: ExerciseController

    init() {
        engine = SceneEngine(tracker: tracker, store: store)
        exercise = ExerciseController(tracker: tracker, engine: engine)
        engine.isSuspended = !UserDefaults.standard.bool(forKey: "setup.completed")
        if !engine.isSuspended { tracker.start() }
        L10n.shared.applyAppearance()
        // 启动后稍等再查更新，别和耳机连接抢启动那几秒
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            Updater.shared.check(interactive: false)
        }
    }
}

private struct TrackingStatusIcon: View {
    let tracker: HeadTracker
    @ObservedObject private var l10n = L10n.shared
    @State private var isTracking = false

    var body: some View {
        Label(l10n.t("app.menuTitle"), systemImage: isTracking ? "eye.slash.fill" : "eye.slash")
            .labelStyle(.titleAndIcon)
            .help(l10n.t("app.name") + " · " + StatusText.tracker(tracker))
            .onReceive(tracker.$status.map(\.isTracking).removeDuplicates()) {
                isTracking = $0
            }
    }
}

final class NotLookingDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !UserDefaults.standard.bool(forKey: "setup.completed") {
            AppWindow.shared.show(.setup)
        } else {
            let launchedAtLogin = NSAppleEventManager.shared().currentAppleEvent?
                .paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
            if !launchedAtLogin { AppWindow.shared.show(.calibration) }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        AppWindow.shared.show()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

/// One normal window, reachable by reopening the app even if its menu item is hidden.
final class AppWindow: NSObject, NSWindowDelegate {
    static let shared = AppWindow()
    private var window: NSWindow?

    func show(_ page: SettingsPage? = nil) {
        NSApplication.shared.setActivationPolicy(.regular)
        if let page { SettingsRouter.shared.selection = page }
        else if !UserDefaults.standard.bool(forKey: "setup.completed") { SettingsRouter.shared.selection = .setup }
        if window == nil {
            let runtime = NotLookingRuntime.shared
            let content = SettingsView()
                .environmentObject(runtime.tracker)
                .environmentObject(runtime.store)
                .environmentObject(runtime.engine)
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 920, height: 700),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            w.title = L10n.shared.t("app.name")
            w.identifier = NSUserInterfaceItemIdentifier("NotLooking.settings")
            w.minSize = NSSize(width: 800, height: 660)
            w.contentView = NSHostingView(rootView: content)
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.center()
            w.setFrameAutosaveName("NotLooking.settings")
            window = w
        }
        window?.title = L10n.shared.t("app.name")
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        // Release the hosted guide, cancelling a pending calibration countdown.
        window?.contentView = nil
        window = nil
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
