import UIKit

final class TrendingCell: UITableViewCell {
    static let reuseID = "TrendingCell"

    var onArticleSelected: ((ArticleViewState) -> Void)?

    private var articles: [ArticleViewState] = []
    private let collectionView: UICollectionView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 280, height: 180)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with articles: [ArticleViewState]) {
        self.articles = articles
        collectionView.reloadData()
    }

    private func setupUI() {
        selectionStyle = .none
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(TrendingArticleCell.self, forCellWithReuseIdentifier: TrendingArticleCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self

        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            collectionView.heightAnchor.constraint(equalToConstant: 180),
        ])
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension TrendingCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        articles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrendingArticleCell.reuseID, for: indexPath) as? TrendingArticleCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: articles[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onArticleSelected?(articles[indexPath.item])
    }
}

// MARK: - Inner Collection Cell

private final class TrendingArticleCell: UICollectionViewCell {
    static let reuseID = "TrendingArticleCell"

    private let imageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let sourceLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancelImageLoad()
        titleLabel.text = nil
        sourceLabel.text = nil
    }

    func configure(with article: ArticleViewState) {
        titleLabel.text = article.title
        sourceLabel.text = article.sourceName
        imageView.setImage(from: article.imageURL)

        accessibilityLabel = "\(article.title). \(article.sourceName)"
        accessibilityHint = "Double tap to read article"
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
        gradientLayer.locations = [0.3, 1.0]
        contentView.layer.addSublayer(gradientLayer)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontForContentSizeCategory = true

        sourceLabel.font = .preferredFont(forTextStyle: .caption1)
        sourceLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        sourceLabel.adjustsFontForContentSizeCategory = true

        let textStack = UIStackView(arrangedSubviews: [titleLabel, sourceLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }
}
