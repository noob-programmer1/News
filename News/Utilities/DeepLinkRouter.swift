import UIKit

//MARK: - DeepLink
enum DeepLink {
    case article(url: String)
}


//MARK: - DeepLink
extension DeepLink {
    static func parse(_ url: URL) -> DeepLink? {
        guard url.scheme == "newsreader" else { return nil }
        
        switch url.host {
            case "article":
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                guard let articleUrl = components?.queryItems?.first(where: { $0.name == "url" })?.value else {
                    return nil
                }
                return .article(url: articleUrl)
            default:
                return nil
        }
    }
    
    static func navigate(to deepLink: DeepLink, in window: UIWindow?) {
        guard let tabBar = window?.rootViewController as? TabBarController else { return }
        tabBar.selectedIndex = 0
        
        guard let navController = tabBar.viewControllers?.first as? UINavigationController else { return }
        navController.popToRootViewController(animated: false)
        
        switch deepLink {
            case .article(let url):
                let stubArticle = Article(
                    id: nil, title: "Loading...", description: nil, content: nil,
                    url: url, image: nil, publishedAt: nil, sourceName: "Unknown"
                )
                
                let detailVM = DependencyContainer.shared.makeArticleDetailViewModel(article: stubArticle)
                
                let detailVC = ArticleDetailViewController(viewModel: detailVM)
                
                navController.pushViewController(detailVC, animated: true)
        }
    }
}




