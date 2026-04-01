import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = TabBarController()
        window.makeKeyAndVisible()
        self.window = window

        if let urlContext = connectionOptions.urlContexts.first,
           let deepLink = DeepLink.parse(urlContext.url) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                
                DeepLink.navigate(to: deepLink, in: self?.window)
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url,
              let deepLink = DeepLink.parse(url) else { return }
        DeepLink.navigate(to: deepLink, in: window)
    }
}
