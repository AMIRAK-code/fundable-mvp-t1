import Foundation
import WatchConnectivity

/// iPhone side of watch sync. The phone is the source of truth: it pushes the
/// full state after every save, and applies quick actions (resist/slip) that
/// arrive from the watch.
final class PhoneSyncManager: NSObject, WCSessionDelegate {
    static let shared = PhoneSyncManager()

    private weak var store: AppStore?

    private override init() {
        super.init()
    }

    func start(store: AppStore) {
        self.store = store
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func pushState() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let state = store?.state,
              let data = try? JSONEncoder().encode(state)
        else { return }
        try? WCSession.default.updateApplicationContext(["state": data])
    }

    private func handleAction(_ payload: [String: Any]) {
        guard let action = payload["action"] as? String else { return }
        DispatchQueue.main.async { [weak self] in
            switch action {
            case "resistCraving":
                self?.store?.logResistedCraving()
            case "logSlip":
                let units = payload["units"] as? Double ?? 1
                self?.store?.logSlip(units: units)
            default:
                break
            }
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.pushState()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleAction(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleAction(userInfo)
    }
}
