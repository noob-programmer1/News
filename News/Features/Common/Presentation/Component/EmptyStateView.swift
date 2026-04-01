import UIKit

final class EmptyStateView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    var onRetry: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(image: String, title: String, subtitle: String, showRetry: Bool = false) {
        imageView.image = UIImage(systemName: image)
        imageView.accessibilityLabel = title
        titleLabel.text = title
        subtitleLabel.text = subtitle
        retryButton.isHidden = !showRetry
        retryButton.accessibilityLabel = "Retry"

        accessibilityLabel = "\(title). \(subtitle)"
    }

    private func setup() {
        backgroundColor = .systemBackground

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, subtitleLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32)
        ])

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }

    @objc private func retryTapped() { onRetry?() }
}
