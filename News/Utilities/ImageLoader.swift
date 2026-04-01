import UIKit
import Combine

// MARK: - ImageLoader
final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let lock = NSLock()
    private var inFlight: [String: AnyPublisher<UIImage, URLError>] = [:]

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 100 * 1024 * 1024
    }

    func publisher(for urlString: String) -> AnyPublisher<UIImage, URLError> {
        let key = urlString as NSString

        if let cached = cache.object(forKey: key) {
            return Just(cached).setFailureType(to: URLError.self).eraseToAnyPublisher()
        }

        lock.lock()
        if let existing = inFlight[urlString] {
            lock.unlock()
            return existing
        }

        guard let url = URL(string: urlString) else {
            lock.unlock()
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        let publisher = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .compactMap { UIImage(data: $0) }
            .mapError { $0 as URLError }
            .handleEvents(
                receiveOutput: { [weak self] image in
                    self?.cache.setObject(image, forKey: key)
                },
                receiveCompletion: { [weak self] _ in
                    self?.lock.lock()
                    self?.inFlight.removeValue(forKey: urlString)
                    self?.lock.unlock()
                },
                receiveCancel: { [weak self] in
                    self?.lock.lock()
                    self?.inFlight.removeValue(forKey: urlString)
                    self?.lock.unlock()
                }
            )
            .share()
            .eraseToAnyPublisher()

        inFlight[urlString] = publisher
        lock.unlock()
        return publisher
    }
}

// MARK: - UIImageView Extension
private enum AssociatedKeys {
    nonisolated(unsafe) static var cancellable = 0
}

extension UIImageView {
    private var imageCancellable: AnyCancellable? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.cancellable) as? AnyCancellable }
        set { objc_setAssociatedObject(self, &AssociatedKeys.cancellable, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func setImage(from urlString: String?, placeholder: UIImage? = UIImage(systemName: "photo")) {
        cancelImageLoad()
        image = placeholder
        guard let urlString else { return }

        imageCancellable = ImageLoader.shared.publisher(for: urlString)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] in self?.image = $0 }
            )
    }

    func cancelImageLoad() {
        imageCancellable?.cancel()
        imageCancellable = nil
    }
}
