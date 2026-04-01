import UIKit
import Combine

final class ReadingStatsViewController: UIViewController {
    private let viewModel: ReadingStatsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI
    private let articlesCard = StatCard()
    private let timeCard = StatCard()
    private let categoriesStack = UIStackView()

    init(viewModel: ReadingStatsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Reading Stats"

        setupUI()
        bindViewModel()
        viewModel.send(.loadStats)
    }


    private func setupUI() {
        let cardsStack = UIStackView(arrangedSubviews: [articlesCard, timeCard])
        cardsStack.axis = .horizontal
        cardsStack.distribution = .fillEqually
        cardsStack.spacing = 12

        let sectionLabel = UILabel()
        sectionLabel.text = "Top Categories"
        sectionLabel.font = .preferredFont(forTextStyle: .headline)

        categoriesStack.axis = .vertical
        categoriesStack.spacing = 8

        let mainStack = UIStackView(arrangedSubviews: [cardsStack, sectionLabel, categoriesStack, UIView()])
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func bindViewModel() {
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.render($0) }
            .store(in: &cancellables)
    }

    private func render(_ state: ReadingStatsState) {
        articlesCard.configure(value: "\(state.articlesThisWeek)", label: "Articles", icon: "doc.text")
        timeCard.configure(value: state.totalTimeFormatted, label: "Time Spent", icon: "clock")

        categoriesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if state.topCategories.isEmpty {
            let empty = UILabel()
            empty.text = "Start reading to see your stats!"
            empty.font = .preferredFont(forTextStyle: .subheadline)
            empty.textColor = .secondaryLabel
            categoriesStack.addArrangedSubview(empty)
        } else {
            for cat in state.topCategories {
                let row = CategoryRow(name: cat.name, count: cat.count)
                categoriesStack.addArrangedSubview(row)
            }
        }
    }
}

// MARK: - Stat Card

private final class StatCard: UIView {
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()
    private let iconView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(value: String, label: String, icon: String) {
        valueLabel.text = value
        titleLabel.text = label
        iconView.image = UIImage(systemName: icon)
    }

    private func setup() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12

        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit

        valueLabel.font = .preferredFont(forTextStyle: .title2, compatibleWith: nil)
        valueLabel.adjustsFontForContentSizeCategory = true

        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabel
        titleLabel.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [iconView, valueLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 24),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])
    }
}

// MARK: - Category Row

private final class CategoryRow: UIView {
    init(name: String, count: Int) {
        super.init(frame: .zero)

        let label = UILabel()
        label.text = name
        label.font = .preferredFont(forTextStyle: .body)

        let countLabel = UILabel()
        countLabel.text = "\(count) articles"
        countLabel.font = .preferredFont(forTextStyle: .body)
        countLabel.textColor = .secondaryLabel

        let bar = UIView()
        bar.backgroundColor = .systemBlue.withAlphaComponent(0.2)
        bar.layer.cornerRadius = 4

        let fill = UIView()
        fill.backgroundColor = .systemBlue
        fill.layer.cornerRadius = 4

        let stack = UIStackView(arrangedSubviews: [label, UIView(), countLabel])
        stack.axis = .horizontal
        stack.translatesAutoresizingMaskIntoConstraints = false

        bar.translatesAutoresizingMaskIntoConstraints = false
        fill.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        addSubview(bar)
        bar.addSubview(fill)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),

            bar.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 4),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 8),
            bar.bottomAnchor.constraint(equalTo: bottomAnchor),

            fill.topAnchor.constraint(equalTo: bar.topAnchor),
            fill.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            fill.bottomAnchor.constraint(equalTo: bar.bottomAnchor),
            fill.widthAnchor.constraint(equalTo: bar.widthAnchor, multiplier: CGFloat(min(count, 10)) / 10.0),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}
