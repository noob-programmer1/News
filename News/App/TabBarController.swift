import UIKit
import Networking

final class TabBarController: UITabBarController {
    private let networkMonitor: NetworkMonitor = DependencyContainer.shared.resolve()

    override func viewDidLoad() {
        super.viewDidLoad()

        let container = DependencyContainer.shared

        let feedVM = container.makeNewsFeedViewModel()
        let feedVC = NewsFeedViewController(viewModel: feedVM)
        let feedNav = UINavigationController(rootViewController: feedVC)
        feedNav.tabBarItem = UITabBarItem(title: "News", image: UIImage(systemName: "newspaper"), tag: 0)

        let bookmarksVM = container.makeBookmarksViewModel()
        let bookmarksVC = BookmarksViewController(viewModel: bookmarksVM)
        let bookmarksNav = UINavigationController(rootViewController: bookmarksVC)
        bookmarksNav.tabBarItem = UITabBarItem(title: "Bookmarks", image: UIImage(systemName: "bookmark"), tag: 1)

        viewControllers = [feedNav, bookmarksNav]

        if !networkMonitor.isConnected {
            selectedIndex = 1
        }
    }
}
