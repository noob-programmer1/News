import UIKit

final class ArticleCell: UITableViewCell {
    static let reuseID = "ArticleCell"

    private let articleImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let sourceLabel = UILabel()
    private let dateLabel = UILabel()
    private let dotLabel = UILabel()
    private let readLabel = UILabel()
    private let bookmarkButton = UIButton(type: .system)

    var onBookmarkTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        articleImageView.cancelImageLoad()
        readLabel.isHidden = true
        dotLabel.isHidden = true
        onBookmarkTapped = nil
    }

    func configure(with article: ArticleViewState) {
        titleLabel.text = article.title
        descriptionLabel.text = article.description
        sourceLabel.text = article.sourceName
        dateLabel.text = "\(article.timeAgo) · \(article.readingTime)"

        let symbol = article.isBookmarked ? "bookmark.fill" : "bookmark"
        bookmarkButton.setImage(UIImage(systemName: symbol), for: .normal)

        articleImageView.setImage(from: article.imageURL)

        if let pct = article.readPercentage {
            readLabel.text = pct >= 100 ? "Completed" : "\(pct)% read"
            readLabel.textColor = pct >= 100 ? .systemGreen : .systemOrange
            readLabel.isHidden = false
            dotLabel.isHidden = false
        } else {
            readLabel.isHidden = true
            dotLabel.isHidden = true
        }
    }

    // MARK: - Layout

    private func setupUI() {
        selectionStyle = .none

        // Image
        articleImageView.contentMode = .scaleAspectFill
        articleImageView.clipsToBounds = true
        articleImageView.layer.cornerRadius = 10
        articleImageView.backgroundColor = .secondarySystemFill

        // Title
        titleLabel.font = .preferredFont(forTextStyle: .subheadline, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true

        // Description
        descriptionLabel.font = .preferredFont(forTextStyle: .footnote)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.adjustsFontForContentSizeCategory = true

        // Source
        sourceLabel.font = .preferredFont(forTextStyle: .caption1, weight: .medium)
        sourceLabel.textColor = .systemBlue
        sourceLabel.adjustsFontForContentSizeCategory = true

        // Date
        dateLabel.font = .preferredFont(forTextStyle: .caption2)
        dateLabel.textColor = .tertiaryLabel
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)

        // Dot separator
        dotLabel.text = "·"
        dotLabel.font = .preferredFont(forTextStyle: .caption2)
        dotLabel.textColor = .tertiaryLabel
        dotLabel.isHidden = true
        dotLabel.setContentHuggingPriority(.required, for: .horizontal)

        // Read %
        readLabel.font = .preferredFont(forTextStyle: .caption2, weight: .medium)
        readLabel.textColor = .systemOrange
        readLabel.adjustsFontForContentSizeCategory = true
        readLabel.isHidden = true
        readLabel.setContentHuggingPriority(.required, for: .horizontal)

        // Bookmark
        bookmarkButton.tintColor = .systemBlue
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
        bookmarkButton.setContentHuggingPriority(.required, for: .horizontal)

        // Stacks
        let textStack = UIStackView(arrangedSubviews: [sourceLabel, titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let metaStack = UIStackView(arrangedSubviews: [dateLabel, dotLabel, readLabel, UIView(), bookmarkButton])
        metaStack.axis = .horizontal
        metaStack.spacing = 4
        metaStack.alignment = .center

        let rightStack = UIStackView(arrangedSubviews: [textStack, metaStack])
        rightStack.axis = .vertical
        rightStack.spacing = 6

        let mainStack = UIStackView(arrangedSubviews: [articleImageView, rightStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .top
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            articleImageView.widthAnchor.constraint(equalToConstant: 96),
            articleImageView.heightAnchor.constraint(equalToConstant: 96),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    @objc private func bookmarkTapped() { onBookmarkTapped?() }
}

// MARK: - Weighted font helper

private extension UIFont {
    static func preferredFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let weighted = desc.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: weighted, size: 0)
    }
}
