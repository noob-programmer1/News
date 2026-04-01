import UIKit

final class OfflineBannerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = UIColor.systemYellow.withAlphaComponent(0.15)

        let icon = UIImageView(image: UIImage(systemName: "wifi.slash"))
        icon.tintColor = .systemOrange
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = "You are offline — showing cached articles"
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
        ])

        isAccessibilityElement = true
        accessibilityLabel = "You are offline. Showing cached articles."
    }
}
