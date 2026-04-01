import UIKit

final class CategoryFilterView: UIView {
    var onCategorySelected: ((ArticleCategory) -> Void)?

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var buttons: [ArticleCategory: UIButton] = [:]
    private var selectedCategory: ArticleCategory = .general

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    func select(_ category: ArticleCategory) {
        selectedCategory = category
        for (cat, button) in buttons {
            updateButtonAppearance(button, isSelected: cat == category)
        }
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .systemBackground

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
            stackView.heightAnchor.constraint(equalToConstant: 32),
        ])

        for category in ArticleCategory.allCases {
            let button = makePillButton(title: category.rawValue)
            button.tag = ArticleCategory.allCases.firstIndex(of: category) ?? 0
            button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttons[category] = button
            updateButtonAppearance(button, isSelected: category == .general)
        }
    }

    private func makePillButton(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var attrs = incoming
            attrs.font = UIFont.preferredFont(forTextStyle: .subheadline)
            return attrs
        }

        let button = UIButton(configuration: config)
        button.accessibilityTraits = .button
        return button
    }

    private func updateButtonAppearance(_ button: UIButton, isSelected: Bool) {
        var config = button.configuration ?? UIButton.Configuration.filled()
        if isSelected {
            config.baseBackgroundColor = .systemBlue
            config.baseForegroundColor = .white
        } else {
            config.baseBackgroundColor = .secondarySystemFill
            config.baseForegroundColor = .label
        }
        button.configuration = config
        button.accessibilityTraits = isSelected ? [.button, .selected] : .button
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        let category = ArticleCategory.allCases[sender.tag]
        select(category)
        onCategorySelected?(category)
    }
}
