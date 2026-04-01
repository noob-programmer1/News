import UIKit

final class LoadingFooterCell: UITableViewCell {
    static let reuseID = "LoadingFooterCell"

    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        selectionStyle = .none
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            spinner.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
        spinner.startAnimating()

        isAccessibilityElement = true
        accessibilityLabel = "Loading more articles"
    }
}
