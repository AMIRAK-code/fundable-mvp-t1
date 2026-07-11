import Foundation
import WatchConnectivity

/// Watch side of sync. Applies actions locally for instant feedback, then
/// forwards them to the phone; whenever the phone pushes its state (the
/// source of truth), the local copy is replaced.
final class WatchSyncManager: NSObject, WCSessionDelegate {
    static let shared = WatchSyncManager()

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

    func sendAction(_ action: String, units: Double? = nil) {
        guard WCSession.isSupported() else { return }
        var payload: [String: Any] = ["action": action]
        if let units {
            payload["units"] = units
        }
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { _ in
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Adopt any state the phone pushed while we were inactive.
        let context = session.receivedApplicationContext
        applyContext(context)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyContext(applicationContext)
    }

    private func applyContext(_ context: [String: Any]) {
        guard let data = context["state"] as? Data,
              let state = try? JSONDecoder().decode(AppState.self, from: data)
        else { return }
        DispatchQueue.main.async { [weak self] in
            self?.store?.replaceState(state)
        }
    }
}
