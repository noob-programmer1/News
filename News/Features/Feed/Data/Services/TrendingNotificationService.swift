import Foundation
import UserNotifications

protocol TrendingNotificationService {
    func requestPermission()
    func scheduleTrendingNotification(articles: [Article])
}

final class TrendingNotificationServiceImpl: TrendingNotificationService {
    private let center = UNUserNotificationCenter.current()
    private var lastNotifiedIds = Set<String>()

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted { print("[Notifications] Permission granted") }
        }
    }

    func scheduleTrendingNotification(articles: [Article]) {
        guard !articles.isEmpty else { return }

        // Only notify for new trending articles we haven't notified about
        let newIds = Set(articles.map(\.stableId))
        guard !newIds.isSubset(of: lastNotifiedIds) else { return }
        lastNotifiedIds = newIds

        let topArticle = articles[0]

        let content = UNMutableNotificationContent()
        content.title = "Trending Now"
        content.body = topArticle.title
        content.sound = .default
        content.userInfo = ["articleURL": topArticle.url]

        // Fire after 2 seconds (simulates "new trending" arriving)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "trending-\(topArticle.stableId)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }
}
