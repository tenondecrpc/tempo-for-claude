import Foundation

@Observable
@MainActor
final class MacSettingsStore {
    private enum Key {
        static let launchAtLogin = "mac.settings.launchAtLogin"
        static let showPercentageInMenuBar = "mac.settings.showPercentageInMenuBar"
        static let use24HourTime = "mac.settings.use24HourTime"
        static let serviceStatusMonitoring = "mac.settings.serviceStatusMonitoring"
        static let syncHistoryViaICloud = "mac.settings.syncHistoryViaICloud"
    }

    var onServiceStatusMonitoringChanged: ((Bool) -> Void)?
    var onSyncHistoryViaICloudChanged: ((Bool) -> Void)?

    var launchAtLogin: Bool {
        didSet {
            persist(launchAtLogin, forKey: Key.launchAtLogin)
        }
    }

    var showPercentageInMenuBar: Bool {
        didSet {
            persist(showPercentageInMenuBar, forKey: Key.showPercentageInMenuBar)
        }
    }

    var use24HourTime: Bool {
        didSet {
            persist(use24HourTime, forKey: Key.use24HourTime)
        }
    }

    var serviceStatusMonitoring: Bool {
        didSet {
            persist(serviceStatusMonitoring, forKey: Key.serviceStatusMonitoring)
            if !isHydrating {
                onServiceStatusMonitoringChanged?(serviceStatusMonitoring)
            }
        }
    }

    var syncHistoryViaICloud: Bool {
        didSet {
            persist(syncHistoryViaICloud, forKey: Key.syncHistoryViaICloud)
            if !isHydrating {
                onSyncHistoryViaICloudChanged?(syncHistoryViaICloud)
            }
        }
    }

    private let defaults: UserDefaults
    private var isHydrating = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isHydrating = true

        if defaults.object(forKey: Key.launchAtLogin) == nil {
            launchAtLogin = false
        } else {
            launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        }

        if defaults.object(forKey: Key.showPercentageInMenuBar) == nil {
            showPercentageInMenuBar = true
        } else {
            showPercentageInMenuBar = defaults.bool(forKey: Key.showPercentageInMenuBar)
        }

        if defaults.object(forKey: Key.use24HourTime) == nil {
            use24HourTime = true
        } else {
            use24HourTime = defaults.bool(forKey: Key.use24HourTime)
        }

        if defaults.object(forKey: Key.serviceStatusMonitoring) == nil {
            serviceStatusMonitoring = true
        } else {
            serviceStatusMonitoring = defaults.bool(forKey: Key.serviceStatusMonitoring)
        }

        if defaults.object(forKey: Key.syncHistoryViaICloud) == nil {
            syncHistoryViaICloud = true
        } else {
            syncHistoryViaICloud = defaults.bool(forKey: Key.syncHistoryViaICloud)
        }

        isHydrating = false
    }

    func updateLaunchAtLoginFromSystem(_ enabled: Bool) {
        let oldHydrating = isHydrating
        isHydrating = true
        launchAtLogin = enabled
        isHydrating = oldHydrating
    }

    private func persist(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}
