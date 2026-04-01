import UIKit
import Combine

final class CommentsViewController: UIViewController {
    private let articleId: String
    private let commentRepository: CommentRepository
    private var comments: [Comment] = []
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(articleId: String, commentRepository: CommentRepository) {
        self.articleId = articleId
        self.commentRepository = commentRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupSheet()
        setupUI()
        loadComments()
    }

    private func setupSheet() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Comments"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        tableView.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseID)
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
        ])
    }

    private func loadComments() {
        spinner.startAnimating()
        commentRepository.comments(for: articleId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] comments in
                self?.spinner.stopAnimating()
                self?.comments = comments
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - DataSource

extension CommentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseID, for: indexPath) as? CommentCell else {
            return UITableViewCell()
        }
        cell.configure(with: comments[indexPath.row])
        return cell
    }
}

// MARK: - CommentCell

private final class CommentCell: UITableViewCell {
    static let reuseID = "CommentCell"

    private let avatarView = UIView()
    private let initialsLabel = UILabel()
    private let authorLabel = UILabel()
    private let timeLabel = UILabel()
    private let bodyLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with comment: Comment) {
        initialsLabel.text = comment.initials
        authorLabel.text = comment.authorName
        timeLabel.text = comment.timeAgo
        bodyLabel.text = comment.text

        // Deterministic color from name
        let hue = CGFloat(abs(comment.authorName.hashValue) % 360) / 360.0
        avatarView.backgroundColor = UIColor(hue: hue, saturation: 0.4, brightness: 0.9, alpha: 1.0)

        accessibilityLabel = "\(comment.authorName), \(comment.timeAgo). \(comment.text)"
    }

    private func setupUI() {
        selectionStyle = .none

        avatarView.layer.cornerRadius = 20
        avatarView.clipsToBounds = true
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        initialsLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        initialsLabel.textColor = .white
        initialsLabel.textAlignment = .center
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(initialsLabel)

        authorLabel.font = .preferredFont(forTextStyle: .subheadline)
        authorLabel.textColor = .label
        authorLabel.adjustsFontForContentSizeCategory = true

        timeLabel.font = .preferredFont(forTextStyle: .caption2)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.adjustsFontForContentSizeCategory = true

        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        bodyLabel.adjustsFontForContentSizeCategory = true

        let headerStack = UIStackView(arrangedSubviews: [authorLabel, UIView(), timeLabel])
        headerStack.axis = .horizontal
        headerStack.alignment = .center

        let textStack = UIStackView(arrangedSubviews: [headerStack, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [avatarView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .top
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }
}
