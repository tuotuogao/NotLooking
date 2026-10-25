import AppKit
import ServiceManagement
import SwiftUI

final class LoginItem: ObservableObject {
    static let shared = LoginItem()
    @Published private(set) var status = SMAppService.mainApp.status
    @Published var error: String?

    var isEnabled: Bool { status == .enabled || status == .requiresApproval }

    func refresh() { status = SMAppService.mainApp.status }

    func setEnabled(_ enabled: Bool) {
        error = nil
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            self.error = error.localizedDescription
        }
        refresh()
    }
}

struct LoginItemControl: View {
    @ObservedObject private var item = LoginItem.shared
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(l10n.t("login.title"), isOn: Binding(get: { item.isEnabled }, set: { item.setEnabled($0) }))
            Text(l10n.t("login.help")).font(.caption).foregroundStyle(.secondary)
            if item.status == .requiresApproval {
                Button(l10n.t("login.approve")) { SMAppService.openSystemSettingsLoginItems() }
            }
            if let error = item.error {
                Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled)
            }
        }
        .onAppear { item.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in item.refresh() }
    }
}
