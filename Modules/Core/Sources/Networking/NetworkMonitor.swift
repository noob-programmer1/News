import Foundation
import Network


public final class NetworkMonitor: @unchecked Sendable {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let lock = NSLock()
    private var _isConnected: Bool = true

    public var isConnected: Bool {
        lock.withLock { _isConnected }
    }

    public init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.core.network-monitor")

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.lock.withLock { self._isConnected = path.status == .satisfied }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
