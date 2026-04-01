import UIKit
import WebKit
import Combine

// MARK: - ArticleDetailViewController
final class ArticleDetailViewController: UIViewController {
    private let viewModel: ArticleDetailViewModel
    private let webView = WKWebView()
    private let loadingView = LoadingView()
    private let errorView = EmptyStateView()

    private var cancellables = Set<AnyCancellable>()
    private var sessionStart: Date?
    private var isReaderMode = false

    init(viewModel: ArticleDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = viewModel.state.sourceName
        setupWebView()
        setupToolbar()
        bindViewModel()
        viewModel.send(.loadArticle)
        sessionStart = Date()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isToolbarHidden = true
        let scrollY = webView.scrollView.contentOffset.y
        let contentHeight = webView.scrollView.contentSize.height
        viewModel.send(.saveScrollPosition(scrollY: scrollY, contentHeight: contentHeight))

        if let start = sessionStart {
            let s = viewModel.state
            DependencyContainer.shared.logReadingSession(
                articleUrl: s.articleRawURL, articleTitle: s.title,
                category: nil, duration: Date().timeIntervalSince(start)
            )
        }
    }
}

// MARK: - Private
private extension ArticleDetailViewController {
    func setupWebView() {
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)

        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.isHidden = true
        view.addSubview(errorView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 44),
            loadingView.heightAnchor.constraint(equalToConstant: 44),
            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    func setupToolbar() {
        navigationController?.isToolbarHidden = false
        let spacer = UIBarButtonItem(systemItem: .flexibleSpace)
        toolbarItems = [
            UIBarButtonItem(image: UIImage(systemName: "bookmark"), style: .plain, target: self, action: #selector(bookmarkTapped)),
            spacer,
            UIBarButtonItem(image: UIImage(systemName: "doc.plaintext"), style: .plain, target: self, action: #selector(toggleReaderMode)),
            spacer,
            UIBarButtonItem(image: UIImage(systemName: "bubble.right"), style: .plain, target: self, action: #selector(commentsTapped)),
            spacer,
            UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareTapped)),
            spacer,
            UIBarButtonItem(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(openInSafari)),
        ]
    }

    func bindViewModel() {
        viewModel.statePublisher
            .map(\.isBookmarked)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBookmarked in
                let symbol = isBookmarked ? "bookmark.fill" : "bookmark"
                self?.toolbarItems?.first?.image = UIImage(systemName: symbol)
            }
            .store(in: &cancellables)

        viewModel.effectPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleEffect($0) }
            .store(in: &cancellables)
    }

    func handleEffect(_ effect: ArticleDetailEffect) {
        switch effect {
        case .loadURL(let url):        webView.load(URLRequest(url: url))
        case .loadCachedHTML(let h, let b): webView.loadHTMLString(h, baseURL: b)
        case .showError:               break
        }
    }

    func restoreScrollPosition() {
        guard let fraction = viewModel.savedScrollFraction() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            let ch = self.webView.scrollView.contentSize.height
            let vh = self.webView.scrollView.bounds.height
            guard ch > vh else { return }
            self.webView.scrollView.setContentOffset(CGPoint(x: 0, y: min(fraction * ch, ch - vh)), animated: false)
        }
    }

    @objc func bookmarkTapped() { viewModel.send(.toggleBookmark) }

    @objc func toggleReaderMode() {
        isReaderMode.toggle()
        if isReaderMode {
            webView.evaluateJavaScript("document.body.innerText") { [weak self] result, _ in
                guard let self, let text = result as? String else { return }
                let s = self.viewModel.state
                let isDark = self.traitCollection.userInterfaceStyle == .dark
                let bg = isDark ? "#1c1c1e" : "#ffffff"
                let fg = isDark ? "#f2f2f7" : "#1c1c1e"
                let html = """
                <html><head><meta name="viewport" content="width=device-width,initial-scale=1">
                <style>body{font-family:-apple-system,Georgia,serif;font-size:18px;line-height:1.7;padding:20px;background:\(bg);color:\(fg)}
                h1{font-size:24px;line-height:1.3;margin-bottom:4px}.meta{font-size:14px;color:#8e8e93;margin-bottom:24px}p{margin-bottom:16px}</style>
                </head><body><h1>\(s.title)</h1><div class="meta">\(s.sourceName) · \(s.formattedDate)</div>
                \(text.split(separator: "\n").filter { !$0.isEmpty }.map { "<p>\($0)</p>" }.joined())</body></html>
                """
                self.webView.loadHTMLString(html, baseURL: nil)
            }
            toolbarItems?[2].image = UIImage(systemName: "doc.plaintext.fill")
        } else {
            if let url = viewModel.state.articleURL {
                webView.load(URLRequest(url: url))
            }
            toolbarItems?[2].image = UIImage(systemName: "doc.plaintext")
        }
    }

    @objc func commentsTapped() {
        let vc = DependencyContainer.shared.makeCommentsViewController(articleId: viewModel.state.articleRawURL)
        present(vc, animated: true)
    }

    @objc func shareTapped() {
        guard let url = viewModel.state.articleURL else { return }
        let vc = UIActivityViewController(activityItems: [viewModel.state.title, url], applicationActivities: nil)
        vc.popoverPresentationController?.barButtonItem = toolbarItems?[6]
        present(vc, animated: true)
    }

    @objc func openInSafari() {
        guard let url = viewModel.state.articleURL else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - WKNavigationDelegate
extension ArticleDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingView.isHidden = false
        errorView.isHidden = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingView.isHidden = true
        if let pageTitle = webView.title, !pageTitle.isEmpty { title = pageTitle }
        if !isReaderMode {
            webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, _ in
                if let html = result as? String { self?.viewModel.send(.cacheHTML(html)) }
            }
            restoreScrollPosition()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingView.isHidden = true
        showWebError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingView.isHidden = true
        showWebError(error)
    }
}

// MARK: - Error Handling
private extension ArticleDetailViewController {
    func showWebError(_ error: Error) {
        if let cached = viewModel.state.cachedHTML {
            webView.loadHTMLString(cached, baseURL: URL(string: viewModel.state.articleRawURL))
            return
        }

        let s = viewModel.state
        if let desc = s.articleDescription, !desc.isEmpty {
            let isDark = traitCollection.userInterfaceStyle == .dark
            let bg = isDark ? "#1c1c1e" : "#ffffff"
            let fg = isDark ? "#f2f2f7" : "#1c1c1e"
            let html = """
            <html><head><meta name="viewport" content="width=device-width,initial-scale=1">
            <style>body{font-family:-apple-system,Georgia,serif;font-size:18px;line-height:1.7;padding:20px;background:\(bg);color:\(fg)}
            h1{font-size:24px;line-height:1.3;margin-bottom:4px}.meta{font-size:14px;color:#8e8e93;margin-bottom:24px}
            .offline{font-size:13px;color:#8e8e93;background:\(isDark ? "#2c2c2e" : "#f2f2f7");padding:10px 14px;border-radius:8px;margin-bottom:20px}
            p{margin-bottom:16px}</style>
            </head><body><h1>\(s.title)</h1><div class="meta">\(s.sourceName) · \(s.formattedDate)</div>
            <div class="offline">You're offline. Showing saved preview only.</div>
            <p>\(desc)</p></body></html>
            """
            webView.loadHTMLString(html, baseURL: nil)
            return
        }

        errorView.configure(image: "wifi.exclamationmark", title: "Failed to load article", subtitle: error.localizedDescription, showRetry: true)
        errorView.isHidden = false
        errorView.onRetry = { [weak self] in
            self?.errorView.isHidden = true
            self?.viewModel.send(.loadArticle)
        }
    }
}
